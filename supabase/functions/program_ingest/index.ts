import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client with service role key
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    const { jobId } = await req.json()

    if (!jobId) {
      throw new Error('jobId is required')
    }

    // Get the job
    const { data: job, error: jobError } = await supabaseClient
      .from('program_ingest_jobs')
      .select('*')
      .eq('id', jobId)
      .single()

    if (jobError) {
      throw new Error(`Failed to fetch job: ${jobError.message}`)
    }

    // Update job status to processing
    await supabaseClient
      .from('program_ingest_jobs')
      .update({ 
        status: 'processing',
        updated_at: new Date().toISOString()
      })
      .eq('id', jobId)

    let rawText = ''

    try {
      if (job.source === 'file' && job.storage_path) {
        // Get file from storage
        const { data: fileData, error: fileError } = await supabaseClient.storage
          .from('program_ingest')
          .download(job.storage_path)

        if (fileError) {
          throw new Error(`Failed to download file: ${fileError.message}`)
        }

        // For now, we'll just extract text from the file
        // In a real implementation, you would use OCR for images/PDFs
        // and OpenAI Vision API for complex documents
        rawText = await fileData.text()
      } else if (job.source === 'text') {
        rawText = job.raw_text || ''
      }

      // Update job with raw text
      await supabaseClient
        .from('program_ingest_jobs')
        .update({ 
          raw_text: rawText,
          updated_at: new Date().toISOString()
        })
        .eq('id', jobId)

      // Parse the text using OpenAI (placeholder implementation)
      const parsedJson = await parseProgramText(rawText)

      // Save the result
      await supabaseClient
        .from('program_ingest_results')
        .insert({
          job_id: jobId,
          parsed_json: parsedJson,
          model_hint: 'gpt-4o-mini'
        })

      // Update job status to succeeded
      await supabaseClient
        .from('program_ingest_jobs')
        .update({ 
          status: 'succeeded',
          updated_at: new Date().toISOString()
        })
        .eq('id', jobId)

      return new Response(
        JSON.stringify({ success: true, message: 'Program parsed successfully' }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200 
        }
      )

    } catch (processingError) {
      // Update job status to failed
      await supabaseClient
        .from('program_ingest_jobs')
        .update({ 
          status: 'failed',
          error: processingError.message,
          updated_at: new Date().toISOString()
        })
        .eq('id', jobId)

      throw processingError
    }

  } catch (error) {
    console.error('Error processing program ingestion:', error)
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})

async function parseProgramText(text: string): Promise<any> {
  // This is a placeholder implementation
  // In a real implementation, you would call OpenAI API here
  
  const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiApiKey) {
    throw new Error('OPENAI_API_KEY not configured')
  }

  // Example OpenAI API call (you would implement this properly)
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${openaiApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: `You are a fitness program parser. Parse the following text and extract structured information about:
- Notes (general notes about the program)
- Supplements (name, dosage, timing, notes)
- Nutrition plan (calories, meals with items, macros)
- Workout plan (days with exercises, sets, reps, tempo, rest)

Return a JSON object with this exact structure:
{
  "notes": "string or null",
  "supplements": [{"name":"string","dosage":"string or null","timing":"string or null","notes":"string or null"}],
  "nutrition_plan": {
    "calories_target": "number or null",
    "meals": [{"name":"string or null","time":"string or null","items":[{"food":"string","qty":"string or null","units":"string or null","kcal":"number or null","macros":{"p":"number or null","c":"number or null","f":"number or null"}}]}]
  },
  "workout_plan": {
    "days": [{"day":"string","exercises":[{"name":"string","sets":"number or null","reps":"string or number or null","tempo":"string or null","rest":"string or null","notes":"string or null"}]}]
  }
}`
        },
        {
          role: 'user',
          content: text
        }
      ],
      temperature: 0.1,
    }),
  })

  if (!response.ok) {
    throw new Error(`OpenAI API error: ${response.statusText}`)
  }

  const data = await response.json()
  const content = data.choices[0]?.message?.content

  if (!content) {
    throw new Error('No content returned from OpenAI')
  }

  try {
    return JSON.parse(content)
  } catch (parseError) {
    throw new Error(`Failed to parse OpenAI response as JSON: ${parseError.message}`)
  }
}
