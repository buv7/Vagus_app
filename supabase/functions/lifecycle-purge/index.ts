// lifecycle-purge — daily cron for account deactivation / deletion grace periods
//
// What this function does each run:
//   1. Send scheduled reminder notifications (push via OneSignal).
//   2. Purge accounts whose scheduled_purge_at has elapsed.
//
// Notification schedule:
//   deactivate: on-request (sent by client), day-25 warning (5 days left),
//               day-30 final (0 days left, sent just before purge)
//   delete:     on-request (sent by client), day-1 (6 days left),
//               day-6 (1 day left), day-7-purged (sent on purge)
//
// Purge cascade:
//   1. Delete user storage files from vagus-media bucket.
//   2. Delete auth.users row → triggers ON DELETE CASCADE on all data tables.
//   3. Mark account_lifecycle row as 'purged'.
//   4. Insert audit row.
//
// Invocation: called by Supabase cron (pg_cron) or manually via HTTP POST
// with service-role Authorization header. No request body required.

import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL           = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY   = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const ONESIGNAL_APP_ID       = Deno.env.get('ONESIGNAL_APP_ID') ?? '';
const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY') ?? '';
const STORAGE_BUCKET         = 'vagus-media';

interface LifecycleRow {
  id: string;
  user_id: string;
  action: 'deactivate' | 'delete';
  requested_at: string;
  scheduled_purge_at: string;
  status: 'pending';
  notification_flags: Record<string, boolean>;
}

// ──────────────────────────────────────────────────────────────────────────────
// Entry point
// ──────────────────────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    });
  }

  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  try {
    const { data: pending, error } = await admin
      .from('account_lifecycle')
      .select('*')
      .eq('status', 'pending');

    if (error) throw error;

    const rows = (pending ?? []) as LifecycleRow[];
    const now  = new Date();

    const results = {
      notifications_sent: 0,
      purged:             0,
      errors:             [] as string[],
    };

    for (const row of rows) {
      try {
        const purgeAt       = new Date(row.scheduled_purge_at);
        const msRemaining   = purgeAt.getTime() - now.getTime();
        const daysRemaining = msRemaining / (1000 * 60 * 60 * 24);

        if (msRemaining <= 0) {
          // Grace period over — purge now.
          await purgeUser(admin, row);
          results.purged++;
        } else {
          // Check whether any reminder notification is due.
          const sent = await maybeNotify(admin, row, daysRemaining);
          results.notifications_sent += sent;
        }
      } catch (rowErr) {
        const msg = rowErr instanceof Error ? rowErr.message : String(rowErr);
        console.error(`lifecycle-purge: error processing row ${row.id}:`, msg);
        results.errors.push(`${row.id}: ${msg}`);
      }
    }

    return new Response(JSON.stringify({ ok: true, ...results }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error('lifecycle-purge: fatal error:', msg);
    return new Response(JSON.stringify({ ok: false, error: msg }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});

// ──────────────────────────────────────────────────────────────────────────────
// Notification dispatch
// ──────────────────────────────────────────────────────────────────────────────

async function maybeNotify(
  admin: SupabaseClient,
  row: LifecycleRow,
  daysRemaining: number,
): Promise<number> {
  const flags = row.notification_flags ?? {};
  let sent = 0;

  if (row.action === 'deactivate') {
    // day-25 warning: when ~5 days remain (between 5.5 and 4.5 days)
    if (!flags['day25_warning'] && daysRemaining <= 5.5 && daysRemaining > 4.5) {
      await sendPush(row.user_id, {
        title:   'Account deactivation in 5 days',
        message: 'Your Vagus account will be deactivated in 5 days. Sign in to cancel.',
        data:    { screen: 'AccountSettings', action: 'deactivate_warning' },
      });
      await setFlag(admin, row.id, 'day25_warning');
      await insertAudit(admin, row, 'notified_day25_warning');
      sent++;
    }
  } else {
    // delete: day-1 (6 days remaining) and day-6 (1 day remaining)
    if (!flags['day1_reminder'] && daysRemaining <= 6.5 && daysRemaining > 5.5) {
      await sendPush(row.user_id, {
        title:   'Account deletion requested',
        message: 'Your Vagus account is scheduled for permanent deletion in 6 days. Sign in to cancel.',
        data:    { screen: 'AccountSettings', action: 'delete_day1' },
      });
      await setFlag(admin, row.id, 'day1_reminder');
      await insertAudit(admin, row, 'notified_day1_reminder');
      sent++;
    }
    if (!flags['day6_warning'] && daysRemaining <= 1.5 && daysRemaining > 0.5) {
      await sendPush(row.user_id, {
        title:   'Final warning: account deletion tomorrow',
        message: 'Your Vagus account will be permanently deleted in less than 24 hours. Sign in NOW to cancel.',
        data:    { screen: 'AccountSettings', action: 'delete_day6' },
      });
      await setFlag(admin, row.id, 'day6_warning');
      await insertAudit(admin, row, 'notified_day6_warning');
      sent++;
    }
  }

  return sent;
}

// ──────────────────────────────────────────────────────────────────────────────
// Purge execution
// ──────────────────────────────────────────────────────────────────────────────

async function purgeUser(admin: SupabaseClient, row: LifecycleRow): Promise<void> {
  const userId = row.user_id;

  // 1. Send final notification before data is gone.
  if (row.action === 'deactivate') {
    await sendPush(userId, {
      title:   'Account permanently deleted',
      message: 'Your 30-day deactivation period has ended. Your Vagus account and all data have been deleted.',
      data:    { screen: 'Goodbye', action: 'purged' },
    });
  } else {
    await sendPush(userId, {
      title:   'Account permanently deleted',
      message: 'Your Vagus account and all associated data have been permanently deleted.',
      data:    { screen: 'Goodbye', action: 'purged' },
    });
  }

  // 2. Delete storage files.
  try {
    const { data: files } = await admin.storage
      .from(STORAGE_BUCKET)
      .list(`user_files/${userId}`);
    if (files && files.length > 0) {
      const paths = files.map((f) => `user_files/${userId}/${f.name}`);
      await admin.storage.from(STORAGE_BUCKET).remove(paths);
    }
  } catch (storageErr) {
    // Log but don't abort — auth deletion is the critical path.
    console.error(`lifecycle-purge: storage cleanup failed for ${userId}:`, storageErr);
  }

  // 3. Delete the auth.users row — cascades to all tables referencing auth.users.
  const { error: deleteErr } = await admin.auth.admin.deleteUser(userId);
  if (deleteErr) {
    // If the user is already gone (e.g. re-run), treat as success.
    if (!deleteErr.message.includes('not found') && !deleteErr.message.includes('User not found')) {
      throw new Error(`auth.admin.deleteUser failed: ${deleteErr.message}`);
    }
  }

  // 4. Mark lifecycle row as purged.
  await admin
    .from('account_lifecycle')
    .update({ status: 'purged', purged_at: new Date().toISOString() })
    .eq('id', row.id);

  // 5. Immutable audit entry.
  await insertAudit(admin, row, 'purged', 'cron');

  console.log(`lifecycle-purge: purged user ${userId} (lifecycle ${row.id}, action=${row.action})`);
}

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────

async function setFlag(admin: SupabaseClient, rowId: string, flag: string): Promise<void> {
  // Uses merge_lifecycle_flag RPC (JSONB || operator) so we never clobber
  // flags set by a previous cron run.
  const { error } = await admin.rpc('merge_lifecycle_flag', { p_id: rowId, p_flag: flag });
  if (error) throw new Error(`merge_lifecycle_flag failed: ${error.message}`);
}

async function insertAudit(
  admin: SupabaseClient,
  row: LifecycleRow,
  status: string,
  performedBy = 'cron',
): Promise<void> {
  await admin.from('account_lifecycle_audit').insert({
    user_id:      row.user_id,
    action:       row.action,
    status,
    performed_by: performedBy,
    details:      { lifecycle_id: row.id },
  });
}

interface PushPayload {
  title:   string;
  message: string;
  data?:   Record<string, string>;
}

async function sendPush(userId: string, payload: PushPayload): Promise<void> {
  if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
    console.warn('lifecycle-purge: OneSignal not configured, skipping push for', userId);
    return;
  }

  try {
    const res = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type':  'application/json',
        'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify({
        app_id:                      ONESIGNAL_APP_ID,
        headings:                    { en: payload.title },
        contents:                    { en: payload.message },
        include_external_user_ids:   [userId],
        data:                        payload.data ?? {},
      }),
    });
    if (!res.ok) {
      const body = await res.text();
      console.error(`lifecycle-purge: OneSignal error for ${userId}:`, body);
    }
  } catch (err) {
    console.error(`lifecycle-purge: push failed for ${userId}:`, err);
  }
}
