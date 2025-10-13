// Process account deletion (Admin only)
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

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

    // Verify admin user
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single();

    if (!profile || !['admin', 'superadmin'].includes(profile.role)) {
      return new Response(JSON.stringify({ error: 'Forbidden: Admin access required' }), {
        status: 403,
      });
    }

    // Get userId from request
    const { userId } = await req.json();
    if (!userId) {
      return new Response(JSON.stringify({ error: 'Missing userId' }), { status: 400 });
    }

    console.log(`Processing deletion for user: ${userId} by admin: ${user.id}`);

    // Anonymize profile (soft delete PII)
    await supabase
      .from('profiles')
      .update({
        full_name: 'Deleted User',
        avatar_url: null,
        bio: null,
        email: `deleted_${userId}@example.com`,
      })
      .eq('id', userId);

    // Mark delete_requests as done
    await supabase
      .from('delete_requests')
      .update({
        status: 'done',
        processed_at: new Date().toIso8601String(),
        processed_by: user.id,
      })
      .eq('user_id', userId);

    // Optional: Delete files from storage
    // Note: Supabase Storage doesn't have recursive delete via API
    // This is a placeholder for future implementation
    try {
      const { data: files } = await supabase.storage
        .from('vagus-media')
        .list(`user_files/${userId}`);

      if (files && files.length > 0) {
        const filePaths = files.map(f => `user_files/${userId}/${f.name}`);
        await supabase.storage.from('vagus-media').remove(filePaths);
      }
    } catch (storageError) {
      console.error('Storage deletion failed:', storageError);
      // Continue anyway
    }

    console.log(`Deletion processed successfully for user: ${userId}`);

    return new Response(
      JSON.stringify({
        ok: true,
        userId,
        processedAt: new Date().toISOString(),
        processedBy: user.id,
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );
  } catch (error) {
    console.error('Deletion processing failed:', error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : String(error) }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
});

