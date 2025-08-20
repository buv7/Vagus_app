# Coach Notes Section 4 Testing Checklist

## Database Schema Tests
- [ ] Run `supabase_progress_setup.sql` in Supabase SQL Editor
- [ ] Verify `coach_notes` table has new columns: `updated_at`, `updated_by`, `is_deleted`, `version`
- [ ] Verify `coach_note_versions` table exists with proper structure
- [ ] Verify `coach_note_attachments` table exists with proper structure
- [ ] Verify RLS policies are in place for new tables

## Version History Tests
- [ ] Create a new note (should have version 1)
- [ ] Edit the note (should create version 2 and save snapshot)
- [ ] Check version viewer shows previous versions
- [ ] Test revert functionality (should create new version, not overwrite)
- [ ] Verify version badges appear in note cards and editor

## Attachment Tests
- [ ] Test file attachment through existing `AttachToNoteButton`
- [ ] Verify files upload to `notes/{userId}/{noteId}/...` path
- [ ] Check attachment chips appear in note cards
- [ ] Test file preview functionality

## Transcription Tests
- [ ] Test voice recorder with audio file
- [ ] Verify audio uploads to storage
- [ ] Test transcription AI service (requires API key configuration)
- [ ] Verify transcribed text inserts into note editor

## Smart Panel Duplicate Detection Tests
- [ ] Create multiple notes with similar content
- [ ] Test duplicate detection button
- [ ] Verify similarity calculation works
- [ ] Test "View Similar Note" navigation

## UI Integration Tests
- [ ] Verify "Attach" button works in note editor
- [ ] Check "Versions (N)" button appears in app bar
- [ ] Test filter options in note list screen
- [ ] Verify version badges and attachment indicators

## Configuration Tests
- [ ] Set up `TRANSCRIPTION_ENDPOINT` in environment/config
- [ ] Set up `TRANSCRIPTION_API_KEY` in environment/config
- [ ] Test transcription service connectivity

## Performance Tests
- [ ] Test with 50+ notes for duplicate detection
- [ ] Verify version history loads quickly
- [ ] Check attachment upload performance

## Error Handling Tests
- [ ] Test transcription with invalid audio file
- [ ] Test version creation with network issues
- [ ] Verify graceful error messages
- [ ] Test attachment upload failures
