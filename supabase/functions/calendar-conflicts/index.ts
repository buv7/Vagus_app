// Deno Deploy Edge Function
// POST { coachId, startAt, endAt }
// Returns { hasConflict: boolean, conflicts: Event[] }

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface ConflictCheckRequest {
  coachId: string;
  startAt: string;
  endAt: string;
}

interface CalendarEvent {
  id: string;
  title: string;
  start_at: string;
  end_at: string;
  coach_id: string;
}

Deno.serve(async (req) => {
  // Handle CORS preflight
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
    // Parse request body
    const { coachId, startAt, endAt }: ConflictCheckRequest = await req.json();
    
    // Validate inputs
    if (!coachId || !startAt || !endAt) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: coachId, startAt, endAt' }),
        { 
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        }
      );
    }

    // Create Supabase client with user's auth context
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    );

    // Query for conflicting events
    const { data, error } = await supabase
      .from('calendar_events')
      .select('id, title, start_at, end_at, coach_id')
      .eq('coach_id', coachId)
      .lt('start_at', endAt)
      .gt('end_at', startAt);

    if (error) {
      console.error('Database query error:', error);
      throw error;
    }

    const conflicts = (data as CalendarEvent[]) ?? [];
    const hasConflict = conflicts.length > 0;

    console.log(`Conflict check for coach ${coachId}: ${hasConflict ? conflicts.length : 'no'} conflicts found`);

    return new Response(
      JSON.stringify({
        hasConflict,
        conflicts: conflicts.map(c => ({
          id: c.id,
          title: c.title,
          startAt: c.start_at,
          endAt: c.end_at,
        })),
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );
  } catch (error) {
    console.error('Error in calendar-conflicts function:', error);
    return new Response(
      JSON.stringify({ 
        error: error instanceof Error ? error.message : String(error),
        hasConflict: false,
        conflicts: [],
      }),
      { 
        status: 500,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        }
      }
    );
  }
});

