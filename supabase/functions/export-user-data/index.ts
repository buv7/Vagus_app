// Export all user data (GDPR compliance)
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type Row = Record<string, unknown>;

async function fetchAll(supabase: any, table: string, userId: string): Promise<Row[]> {
  try {
    const { data, error } = await supabase
      .from(table)
      .select('*')
      .eq('user_id', userId);
    if (error) throw new Error(`${table}: ${error.message}`);
    return data ?? [];
  } catch (e) {
    console.error(`Failed to fetch ${table}:`, e);
    return [];
  }
}

Deno.serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    });
  }

  try {
    const auth = req.headers.get('Authorization')!;
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: auth } } }
    );

    // Get current user
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
    }

    console.log(`Exporting data for user: ${user.id}`);

    // Tables to export
    const tables = [
      'nutrition_plans',
      'workout_plans',
      'workout_weeks',
      'workout_days',
      'exercises',
      'exercise_logs',
      'checkins',
      'client_metrics',
      'messages',
      'user_files',
      'progress_photos',
      'coach_notes',
      'file_tags',
      'file_comments',
    ];

    const bundle: Record<string, Row[]> = {};
    for (const table of tables) {
      bundle[table] = await fetchAll(supabase, table, user.id);
    }

    // Add profile
    const { data: profile } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single();
    bundle['profile'] = profile ? [profile] : [];

    // Create JSON export
    const exportData = {
      exported_at: new Date().toISOString(),
      user_id: user.id,
      data: bundle,
    };

    const json = new Blob([JSON.stringify(exportData, null, 2)], {
      type: 'application/json',
    });

    // Upload to storage
    const fileName = `exports/${user.id}/${Date.now()}.json`;
    const { error: uploadError } = await supabase.storage
      .from('vagus-media')
      .upload(fileName, json, {
        contentType: 'application/json',
        upsert: true,
      });

    if (uploadError) throw uploadError;

    // Create signed URL (1 hour expiry)
    const { data: signedData, error: signError } = await supabase.storage
      .from('vagus-media')
      .createSignedUrl(fileName, 3600);

    if (signError) throw signError;

    // Record export request
    await supabase.from('data_exports').insert({
      user_id: user.id,
      status: 'ready',
      export_url: signedData.signedUrl,
      expires_at: new Date(Date.now() + 3600 * 1000).toISOString(),
      completed_at: new Date().toISOString(),
    });

    console.log(`Export complete for user: ${user.id}`);

    return new Response(
      JSON.stringify({ 
        url: signedData.signedUrl,
        expires_at: new Date(Date.now() + 3600 * 1000).toISOString(),
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );
  } catch (error) {
    console.error('Export failed:', error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : String(error) }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
});

