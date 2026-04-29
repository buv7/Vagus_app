# Handoff from BRAIN to THRIFT

**Date:** 2026-04-28
**Branch:** agent/brain-ai-router
**PR:** [BRAIN] AI tier-router + multi-provider with PII sanitization (to be opened)

---

## What BRAIN delivered

A unified AI routing layer in `lib/services/ai/`:

| File | Role |
|---|---|
| `task_type.dart` | `TaskType` enum + `kProviderChain` routing table |
| `providers/provider_client.dart` | Abstract `ProviderClient` + `ProviderQuotaExceededException` |
| `providers/cerebras_client.dart` | Cerebras inference API (llama-3.3-70b) |
| `providers/groq_client.dart` | Groq cloud API (llama-3.3-70b-versatile) |
| `providers/gemini_client.dart` | Google Gemini 1.5 Flash (text + vision) |
| `providers/openrouter_client.dart` | OpenRouter free models (DeepSeek R1, Llama 3.3, Qwen3, Gemma 3) |
| `ai_quota_tracker.dart` | `QuotaChecker` interface + `AiQuotaTracker` (Supabase) |
| `ai_client.dart` | Router: PII-sanitize → pick chain → fallback → quota record |

Supabase migration: `supabase/migrations/20260428000000_brain_quota_usage.sql`  
(`ai_quota_usage` table + `brain_upsert_quota` SECURITY DEFINER RPC)

---

## What THRIFT needs to build on top

THRIFT is the **cache layer** that sits in front of `AIClient`. Its job:

### Cache key
Hash of:
- `TaskType` name
- Sanitized message content (after `PiiSanitizer.sanitize()` — cache keys must never contain raw PII)
- Any structured options that affect the output (temperature, etc.)

Recommended: reuse the existing `AICache.cacheKeyFor()` pattern in `lib/services/ai/ai_cache.dart`.

### Where to hook in
Intercept `AIClient.complete()` calls **before** they reach the provider chain.
THRIFT should implement a wrapper or a middleware layer rather than modifying `AIClient` directly — the routing logic is intentionally isolated.

### Cache invalidation signals
- The `ai_quota_usage` table records when each provider was last used. THRIFT can read this to decide whether a cached response should be served more aggressively (e.g. if a provider is near its daily limit, extend TTL for cache hits).
- `TaskType.programGeneration` and `TaskType.summary` are batch tasks — safe to cache for hours.
- `TaskType.smartReply` and `TaskType.coachInsight` are low-latency — cache TTL should be short (minutes).
- `TaskType.vision` should NOT be cached by content (image hash is expensive). Cache by `(imageHash, prompt)` if at all.

### Quota tracker access
```dart
import 'package:vagus_app/services/ai/ai_quota_tracker.dart';

// Check if a provider is near its limit:
final hasRoom = await AiQuotaTracker.instance.hasCapacity('cerebras');

// Daily limit constants:
final cerebrasDailyLimit = kDailyRequestLimits['cerebras']; // 1,000,000
```

### API keys required
THRIFT does not call providers directly, but if it runs any prefetch logic it will need:
- `CEREBRAS_API_KEY`
- `GROQ_API_KEY`
- `GEMINI_API_KEY`
- `OPENROUTER_API_KEY`

### Testing pattern
`AIClient.forTesting(providers: {...}, quota: ...)` creates a fresh non-singleton
instance with injected providers and quota checker. THRIFT tests should wrap this
to avoid any Supabase dependency.

---

## PII contract (VAULT-enforced)

Every string that flows through `AIClient` is sanitized via `PiiSanitizer.sanitizeAndAssert()`
before reaching a provider. THRIFT **must not bypass** this:
- Cache keys derived from raw user text must use `PiiSanitizer.sanitize()` first.
- Cache *values* (LLM responses) are fine to store — they were generated from sanitized input.
- Never log a cache key or value that could contain unsanitized user data.

---

## Open questions for THRIFT

1. Should cache hits bypass `ai_quota_tracker.recordUsage()`? (Probably yes — no provider was called.)
2. Semantic cache (embedding similarity) vs exact-match? The `embed()` method on `AIClient` routes to OpenRouter and is available.
3. Persistence: Supabase table vs device-local `SharedPreferences` vs in-memory `AICache`?

BRAIN recommends: device-local `AICache` for sub-minute TTL (smartReply), Supabase for multi-session batch results (programGeneration, summary).
