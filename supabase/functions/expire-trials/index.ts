import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Cron-triggered daily. Invoke via Supabase scheduled cron:
//   select cron.schedule('expire-trials', '0 3 * * *', $$
//     select net.http_post(
//       url := '<SUPABASE_URL>/functions/v1/expire-trials',
//       headers := '{"Authorization": "Bearer <CRON_SECRET>"}'
//     );
//   $$);

const CRON_SECRET = Deno.env.get("CRON_SECRET") ?? "";
const FREE_CLIENT_LIMIT = 2;

// Notification windows (hours from period_end)
// Day 23 = 7 days left  = 168h ± 12h window
const DAY_23_MIN_H = 156;
const DAY_23_MAX_H = 180;
// Day 28 = 2 days left  = 48h ± 6h window
const DAY_28_MIN_H = 42;
const DAY_28_MAX_H = 54;

interface Trial {
  id: string;
  user_id: string;
  period_end: string;
  trial_notified_stages: string[];
}

interface Results {
  notified_day23: number;
  notified_day28: number;
  downgraded: number;
  pending_client_review: number;
  errors: number;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: { "Access-Control-Allow-Origin": "*" },
    });
  }

  // Verify caller is the scheduler
  const auth = req.headers.get("Authorization") ?? "";
  if (CRON_SECRET && auth !== `Bearer ${CRON_SECRET}`) {
    return new Response("Unauthorized", { status: 401 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const now = new Date();
  const results: Results = {
    notified_day23: 0,
    notified_day28: 0,
    downgraded: 0,
    pending_client_review: 0,
    errors: 0,
  };

  const { data: trials, error } = await supabase
    .from("subscriptions")
    .select("id, user_id, period_end, trial_notified_stages")
    .eq("status", "trialing");

  if (error) {
    console.error("fetch trials:", error);
    return Response.json({ error: error.message }, { status: 500 });
  }

  for (const trial of (trials ?? []) as Trial[]) {
    try {
      const periodEnd = new Date(trial.period_end);
      const hoursLeft =
        (periodEnd.getTime() - now.getTime()) / (1000 * 60 * 60);
      const stages: string[] = trial.trial_notified_stages ?? [];

      // ── Day-23 notification ──────────────────────────────────────────────
      if (
        hoursLeft >= DAY_23_MIN_H &&
        hoursLeft < DAY_23_MAX_H &&
        !stages.includes("day_23")
      ) {
        await sendPush(supabase, trial.user_id, {
          title: "Your trial ends in 7 days",
          message:
            "Choose a plan now to keep your Pro features without interruption.",
          screen: "billing",
        });
        await appendStage(supabase, trial.id, stages, "day_23");
        results.notified_day23++;
      }

      // ── Day-28 notification ──────────────────────────────────────────────
      if (
        hoursLeft >= DAY_28_MIN_H &&
        hoursLeft < DAY_28_MAX_H &&
        !stages.includes("day_28")
      ) {
        await sendPush(supabase, trial.user_id, {
          title: "Your trial ends in 2 days!",
          message:
            "Upgrade now to keep your client list, workflows, and AI access.",
          screen: "billing",
        });
        await appendStage(supabase, trial.id, stages, "day_28");
        results.notified_day28++;
      }

      // ── Expiry handling ──────────────────────────────────────────────────
      if (hoursLeft <= 0) {
        await handleExpiry(supabase, trial, results);
      }
    } catch (err) {
      console.error(`trial ${trial.id}:`, err);
      results.errors++;
    }
  }

  console.log("expire-trials run complete", results);
  return Response.json({ success: true, results });
});

async function handleExpiry(
  supabase: ReturnType<typeof createClient>,
  trial: Trial,
  results: Results,
) {
  // Count how many active clients the coach has.
  const { data: clientRows } = await supabase
    .from("coach_clients")
    .select("client_id")
    .eq("coach_id", trial.user_id);

  const clientCount = (clientRows ?? []).length;

  if (clientCount <= FREE_CLIENT_LIMIT) {
    // Safe to auto-downgrade.
    await supabase
      .from("subscriptions")
      .update({
        plan_code: "free",
        status: "canceled",
        updated_at: new Date().toISOString(),
      })
      .eq("id", trial.id);

    await sendPush(supabase, trial.user_id, {
      title: "Your trial has ended",
      message:
        "You're now on the Free plan. Upgrade anytime to restore Pro features.",
      screen: "billing",
    });
    results.downgraded++;
  } else {
    // Coach has too many clients — leave in trialing but notify them to
    // log in and choose which clients to release. The app's TrialService
    // detects the expired period_end and triggers the downgrade sheet.
    await sendPush(supabase, trial.user_id, {
      title: "Action required: trial ended",
      message: `You have ${clientCount} clients but Free supports ${FREE_CLIENT_LIMIT}. Open the app to choose which to keep.`,
      screen: "billing",
    });
    results.pending_client_review++;
  }
}

async function sendPush(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  payload: { title: string; message: string; screen: string },
) {
  await supabase.functions.invoke("send-notification", {
    body: {
      type: "user",
      userId,
      title: payload.title,
      message: payload.message,
      screen: payload.screen,
    },
  });
}

async function appendStage(
  supabase: ReturnType<typeof createClient>,
  subId: string,
  current: string[],
  stage: string,
) {
  await supabase
    .from("subscriptions")
    .update({ trial_notified_stages: [...current, stage] })
    .eq("id", subId);
}
