import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Supabase configuration
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Create Supabase client with service role key for admin access
const supabase = createClient(supabaseUrl, supabaseServiceKey);

interface UpdateAIUsageRequest {
  user_id: string;
  tokens_used: number;
}

interface AIUsageRecord {
  user_id: string;
  month: number;
  year: number;
  tokens_used: number;
  updated_at: string;
}

serve(async (req) => {
  try {
    // Handle CORS
    if (req.method === 'OPTIONS') {
      return new Response(null, {
        status: 200,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      });
    }

    // Only allow POST requests
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Parse request body
    const body: UpdateAIUsageRequest = await req.json();

    // Validate required fields
    if (!body.user_id || typeof body.tokens_used !== 'number') {
      return new Response(JSON.stringify({ 
        error: 'user_id and tokens_used are required. tokens_used must be a number.' 
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Validate user_id format (should be a valid UUID)
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(body.user_id)) {
      return new Response(JSON.stringify({ 
        error: 'Invalid user_id format. Must be a valid UUID.' 
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Validate tokens_used is positive
    if (body.tokens_used < 0) {
      return new Response(JSON.stringify({ 
        error: 'tokens_used must be a positive number.' 
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Get current month and year
    const now = new Date();
    const month = now.getMonth() + 1; // getMonth() returns 0-11, so add 1
    const year = now.getFullYear();

    // Check if record exists for this user/month/year
    const { data: existingRecord, error: selectError } = await supabase
      .from('ai_usage')
      .select('id, tokens_used')
      .eq('user_id', body.user_id)
      .eq('month', month)
      .eq('year', year)
      .single();

    if (selectError && selectError.code !== 'PGRST116') { // PGRST116 = no rows returned
      console.error('Error checking existing record:', selectError);
      return new Response(JSON.stringify({ 
        error: 'Failed to check existing AI usage record' 
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    let result;
    
    if (existingRecord) {
      // Update existing record
      const { data: updateData, error: updateError } = await supabase
        .from('ai_usage')
        .update({
          tokens_used: existingRecord.tokens_used + body.tokens_used,
          updated_at: now.toISOString(),
        })
        .eq('id', existingRecord.id)
        .select();

      if (updateError) {
        console.error('Error updating AI usage:', updateError);
        return new Response(JSON.stringify({ 
          error: 'Failed to update AI usage record' 
        }), {
          status: 500,
          headers: { 'Content-Type': 'application/json' },
        });
      }

      result = updateData;
    } else {
      // Insert new record
      const newRecord: AIUsageRecord = {
        user_id: body.user_id,
        month: month,
        year: year,
        tokens_used: body.tokens_used,
        updated_at: now.toISOString(),
      };

      const { data: insertData, error: insertError } = await supabase
        .from('ai_usage')
        .insert(newRecord)
        .select();

      if (insertError) {
        console.error('Error inserting AI usage:', insertError);
        return new Response(JSON.stringify({ 
          error: 'Failed to insert AI usage record' 
        }), {
          status: 500,
          headers: { 'Content-Type': 'application/json' },
        });
      }

      result = insertData;
    }

    console.log('AI usage updated successfully:', {
      user_id: body.user_id,
      month: month,
      year: year,
      tokens_used: body.tokens_used,
      operation: existingRecord ? 'updated' : 'inserted',
    });

    return new Response(JSON.stringify({
      success: true,
      message: 'AI usage updated successfully',
      data: result?.[0],
    }), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });

  } catch (error) {
    console.error('Error in update-ai-usage function:', error);
    return new Response(JSON.stringify({
      error: 'Internal server error',
      details: error.message
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
  }
});
