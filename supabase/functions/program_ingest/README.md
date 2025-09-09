# Program Ingestion Edge Function

This Edge Function processes uploaded program files or text to extract structured fitness program data using AI.

## Environment Variables Required

- `OPENAI_API_KEY`: Your OpenAI API key for GPT-4o-mini processing
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY`: Your Supabase service role key

## Deployment

```bash
# Deploy the function
supabase functions deploy program_ingest

# Set environment variables
supabase secrets set OPENAI_API_KEY=your_openai_api_key_here
```

## Usage

The function expects a POST request with:

```json
{
  "jobId": "uuid-of-the-job"
}
```

## Features

- Processes both file uploads and text input
- Uses OpenAI GPT-4o-mini for intelligent parsing
- Extracts structured data for:
  - General notes
  - Supplements (name, dosage, timing, notes)
  - Nutrition plans (calories, meals, macros)
  - Workout plans (days, exercises, sets, reps, tempo, rest)
- Handles errors gracefully with proper status updates
- Stores results in the `program_ingest_results` table

## Error Handling

- Updates job status to 'processing' when started
- Updates job status to 'succeeded' when completed
- Updates job status to 'failed' with error message if processing fails
- All database operations use the service role for proper permissions

## Future Enhancements

- Add OCR support for image files
- Add PDF text extraction
- Support for more file formats
- Batch processing capabilities
- Custom parsing rules per coach
