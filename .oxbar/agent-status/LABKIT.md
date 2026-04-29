# LABKIT status: READY-FOR-REVIEW

**Started:** 2026-04-28 00:00 UTC
**Last update:** 2026-04-28 (current session)
**Branch:** agent/labkit
**Mission:** Lab work parser pipeline — PDF/photo → biomarker extraction → encrypted storage → trends + coach alerts.

## Current state
READY-FOR-REVIEW: all deliverables implemented on `agent/labkit`.

## Progress
- [x] Read COORDINATION_PROTOCOL handoffs (VAULT-to-LABKIT.md)
- [x] Read VAULT.md — confirmed vault_encrypt_text / vault_decrypt_text / vault_audit_access available
- [x] Migration `20260428000000_labkit.sql`
  - [x] `lab_work` table (encrypted biomarkers_enc + raw_pdf_url_enc)
  - [x] `lab_consent_grants` table (per-lab, per-coach)
  - [x] `biomarkers_dictionary` table seeded with ~100 biomarkers (CBC, Lipid, Metabolic, Liver, Thyroid, Iron, Vitamins, Hormones, Inflammation, Cardiac, Other)
  - [x] RLS on all three tables
  - [x] RPC: `insert_lab_work` (encrypt + audit write)
  - [x] RPC: `get_lab_detail` (consent check + decrypt + audit read)
  - [x] RPC: `list_my_labs` (metadata + audit read)
  - [x] RPC: `delete_lab_work` (hard delete — GDPR)
  - [x] RPC: `grant_lab_consent` / `revoke_lab_consent`
- [x] `lib/models/labkit/biomarker_result.dart`
- [x] `lib/models/labkit/biomarker_dictionary_entry.dart`
- [x] `lib/models/labkit/lab_work.dart`
- [x] `lib/services/labkit/lab_pii_detector.dart` — strips patient name, DOB, MRN, physician, address; wraps VAULT PiiSanitizer
- [x] `lib/services/labkit/lab_pdf_extractor.dart` — pdfx text extraction
- [x] `lib/services/labkit/lab_ocr_service.dart` — Gemini Vision OCR (BRAIN stub; swap when BRAIN merges)
- [x] `lib/services/labkit/lab_biomarker_extractor.dart` — structured LLM extraction via AIClient
- [x] `lib/services/labkit/lab_dictionary_mapper.dart` — fuzzy token match + unknown → needsReview queue
- [x] `lib/services/labkit/lab_work_service.dart` — full pipeline orchestration + CRUD + consent
- [x] `lib/screens/labkit/lab_upload_screen.dart` — disclaimer + PDF/photo picker + progress states
- [x] `lib/screens/labkit/lab_detail_screen.dart` — disclaimer banner + biomarker list + range bars + consent toggle + hard delete
- [x] `lib/screens/labkit/lab_trend_screen.dart` — fl_chart line chart + reference range overlay + data table

## Safety guards verified
- [x] No diagnosis language in any UI text or LLM prompt
- [x] LabPiiDetector.strip() runs before every LLM call
- [x] PiiSanitizer.assertSafe() runs immediately before AIClient.chat()
- [x] biomarkers_enc stored via vault_encrypt_text() (server-side RPC)
- [x] raw_pdf_url_enc stored via vault_encrypt_text() (server-side RPC)
- [x] Every read (self + coach) inserts audit row via vault_audit_access()
- [x] Coach access gated on active lab_consent_grants row (checked in get_lab_detail RPC)
- [x] Disclaimer shown on upload screen and on every lab detail view
- [x] Hard delete (GDPR) implemented via delete_lab_work() RPC

## Files touched
- `supabase/migrations/20260428000000_labkit.sql`
- `lib/models/labkit/biomarker_result.dart`
- `lib/models/labkit/biomarker_dictionary_entry.dart`
- `lib/models/labkit/lab_work.dart`
- `lib/services/labkit/lab_pii_detector.dart`
- `lib/services/labkit/lab_pdf_extractor.dart`
- `lib/services/labkit/lab_ocr_service.dart`
- `lib/services/labkit/lab_biomarker_extractor.dart`
- `lib/services/labkit/lab_dictionary_mapper.dart`
- `lib/services/labkit/lab_work_service.dart`
- `lib/screens/labkit/lab_upload_screen.dart`
- `lib/screens/labkit/lab_detail_screen.dart`
- `lib/screens/labkit/lab_trend_screen.dart`
- `.oxbar/agent-status/LABKIT.md`

## BRAIN dependency
LabOcrService calls Gemini Vision directly. When BRAIN merges and exposes
`visionExtract(imageBytes, prompt)`, replace the `_analyzeWithGemini` block
in `lab_ocr_service.dart` with a BRAIN call. No other LABKIT files need to change.

## Questions for OXBAR
1. **app.vault_data_key on staging** — needed before LABKIT migration can be applied (same note as VAULT's Q1).
2. **Storage bucket for raw PDFs** — LABKIT encrypts the URL before storing, but needs a Supabase Storage bucket (e.g. `lab-uploads`) with appropriate RLS. Currently `storageUrl` is optional; upload skips URL storage if not provided.
3. **Coach user ID UX** — `_AddCoachDialog` currently takes a raw UUID. Suggest OXBAR/HARBOR exposes a coach-lookup by name or coach code before LABKIT ships to users.
4. **Threshold alerts** — coach alert notification on key biomarker shifts is wired into consent grants but push notification scheduling is not yet implemented (depends on SIGNAL agent).

## Blockers
None. BRAIN stub in lab_ocr_service.dart is functional (Gemini Vision direct call) until BRAIN merges.

## Next step
PR review by OXBAR. After merge, apply migration to staging, verify VAULT CI passes.
