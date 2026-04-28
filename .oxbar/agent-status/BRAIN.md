# BRAIN status: DONE

**Started:** 2026-04-28 UTC
**Last update:** 2026-04-28 UTC
**Branch:** agent/brain-ai-router
**Mission:** Unified AI tier-router: Cerebras / Groq / Gemini / OpenRouter with PII sanitization,
quota tracking, and fallback chains.

## Current state
All CI checks green. PR #20 open and ready to merge.

## Progress
- [x] `lib/services/ai/task_type.dart` — TaskType enum + kProviderChain routing map
- [x] `lib/services/ai/providers/provider_client.dart` — abstract ProviderClient + ProviderQuotaExceededException
- [x] `lib/services/ai/providers/cerebras_client.dart` — Cerebras inference API (llama-3.3-70b)
- [x] `lib/services/ai/providers/groq_client.dart` — Groq cloud (llama-3.3-70b-versatile)
- [x] `lib/services/ai/providers/gemini_client.dart` — Gemini 1.5 Flash (text + vision)
- [x] `lib/services/ai/providers/openrouter_client.dart` — OpenRouter free models (DeepSeek R1, Llama 3.3, Qwen3, Gemma 3)
- [x] `lib/services/ai/ai_quota_tracker.dart` — QuotaChecker interface + AiQuotaTracker (Supabase)
- [x] `lib/services/ai/ai_client.dart` — Router (PII-sanitize → chain → fallback → quota record)
- [x] `supabase/migrations/20260428000000_brain_quota_usage.sql` — ai_quota_usage table + brain_upsert_quota RPC
- [x] `test/ai/ai_router_test.dart` — 18 tests covering routing, PII, fallback, quota, streaming, vision, embed
- [x] `.oxbar/handoffs/BRAIN-to-THRIFT.md` — cache layer handoff
- [x] Backward compat: existing `chat()` and `embed()` callers continue to work

## Design decisions
- **QuotaChecker** is an abstract interface so tests can inject a stub without Supabase.
- **AIClient.forTesting()** factory creates isolated non-singleton instances for test.
- **chat()** is marked `@Deprecated` — callers should migrate to `complete()`.
- **vision()** has no fallback (Gemini only) per spec.
- **embed()** routes to OpenRouter; `model` param is kept for backward compat (ignored).
- **unawaited()** from `dart:async` used for fire-and-forget quota recording.

## Files touched
- `lib/services/ai/ai_client.dart` (replaced)
- `lib/services/ai/task_type.dart` (new)
- `lib/services/ai/ai_quota_tracker.dart` (new)
- `lib/services/ai/providers/provider_client.dart` (new)
- `lib/services/ai/providers/cerebras_client.dart` (new)
- `lib/services/ai/providers/groq_client.dart` (new)
- `lib/services/ai/providers/gemini_client.dart` (new)
- `lib/services/ai/providers/openrouter_client.dart` (new)
- `supabase/migrations/20260428000000_brain_quota_usage.sql` (new)
- `test/ai/ai_router_test.dart` (new)
- `.oxbar/handoffs/BRAIN-to-THRIFT.md` (new)

## Questions for OXBAR
- THRIFT should be launched next to add the cache layer on top of this router.
- ANALYTICA wires real PostHog events in `_posthogStub()` — stubs are in place.

## Blockers
None.

## Next step
Merge PR #20. Launch THRIFT for cache layer (see handoff).
