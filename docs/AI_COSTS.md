# AI Endpoint & Cost Inventory

Single source of truth for every AI call the app makes, the model behind it,
and the approximate cost at a reference usage load.

Routing: all LLM + embedding calls go through **OpenRouter**
(`lib/services/ai/ai_client.dart`), which proxies to OpenAI. The
model names below are the OpenAI names OpenRouter exposes.
Transcription calls go directly to OpenAI Whisper from
`lib/services/ai/transcription_ai.dart`.
Model-per-task mapping lives in `lib/services/ai/model_registry.dart`
and can be overridden at build time via `--dart-define`
(e.g. `NOTES_SUMMARIZE_MODEL=...`).

## Reference unit prices (OpenAI list, 2026-04)

| Resource | Input per 1M tokens | Output per 1M tokens |
| --- | ---: | ---: |
| `gpt-4o-mini` | $0.150 | $0.600 |
| `text-embedding-3-small` | $0.020 | — |
| `text-embedding-3-large` (legacy) | $0.130 | — |
| `whisper-1` | $0.006 / audio-minute | — |

## Endpoint inventory

| Task key | Caller (file) | User-facing feature | Model | Endpoint |
| --- | --- | --- | --- | --- |
| `notes.summarize` | `messaging_ai.dart` (fallback) | Notes summarization; long-thread summary | `gpt-4o-mini` | `/chat/completions` |
| `notes.tags` | — (registered, admin-configurable) | Auto-tagging coach notes | `gpt-4o-mini` | `/chat/completions` |
| `notes.dupdetect` | — (registered, admin-configurable) | Duplicate-note detection | `gpt-4o-mini` | `/chat/completions` |
| `chat.default` | `calendar_ai.dart` (fallback) | Generic chat fallback | `gpt-4o-mini` | `/chat/completions` |
| `calendar.tagger` | `calendar_ai.dart` | Auto-tag calendar events | `gpt-4o-mini` | `/chat/completions` |
| `calendar.time` | `calendar_ai.dart` | Natural-language time parsing | `gpt-4o-mini` | `/chat/completions` |
| `messaging.reply` | `messaging_ai.dart` | Smart reply suggestions | `gpt-4o-mini` | `/chat/completions` |
| `messaging.translate` | `messaging_ai.dart` | Inline message translation | `gpt-4o-mini` | `/chat/completions` |
| `messaging.summarize` | `messaging_ai.dart` | Thread summarization | `gpt-4o-mini` | `/chat/completions` |
| `workout.suggest` | `workout_ai.dart` | Next-exercise suggestion | `gpt-4o-mini` | `/chat/completions` |
| `workout.deload` | `workout_ai.dart` | Suggest deload week | `gpt-4o-mini` | `/chat/completions` |
| `workout.weakpoint` | `workout_ai.dart` | Weak-point analysis | `gpt-4o-mini` | `/chat/completions` |
| `workout.full_week` | `workout_ai.dart` | Generate 7-day plan | `gpt-4o-mini` | `/chat/completions` |
| `workout.single_day` | `workout_ai.dart` | Generate 1-day plan | `gpt-4o-mini` | `/chat/completions` |
| `workout.alternatives` | `workout_ai.dart` | Exercise swap suggestions | `gpt-4o-mini` | `/chat/completions` |
| `workout.autofill` | `workout_ai.dart` | Autofill missing set fields | `gpt-4o-mini` | `/chat/completions` |
| `workout.progression` | `workout_ai.dart` | Progressive-overload math | `gpt-4o-mini` | `/chat/completions` |
| `workout.balance` | `workout_ai.dart` | Muscle-group balance check | `gpt-4o-mini` | `/chat/completions` |
| `workout.supersets` | `workout_ai.dart` | Superset pairing | `gpt-4o-mini` | `/chat/completions` |
| `workout.duration` | `workout_ai.dart` | Estimate session duration | `gpt-4o-mini` | `/chat/completions` |
| `workout.deload_week` | `workout_ai.dart` | Deload week builder | `gpt-4o-mini` | `/chat/completions` |
| `embedding.default` | `embedding_helper.dart`, `contextual_memory_service.dart` | Note / message / workout semantic search + contextual memory | `text-embedding-3-small` | `/embeddings` |
| (transcription) | `transcription_ai.dart` | Voice-note → text | `whisper-1` | OpenAI `v1/audio/transcriptions` |
| `program_ingest` | Supabase function `program_ingest/index.ts` | OCR/ingest uploaded coaching programs | `gpt-4o-mini` | `/chat/completions` |

## Per-user monthly cost at 5 AI calls/day

Assumption: 5 AI calls/day × 30 days = **150 chat-style calls per user
per month**, averaging ~1.5K input + ~0.5K output tokens each.
Embeddings run implicitly on a subset of those calls (note saves,
message indexing); whisper usage is modeled separately because it is
driven by voice input, not chat flow.

| Bucket | Volume / month / user | Unit rate | Cost / month / user |
| --- | --- | --- | ---: |
| Chat (`gpt-4o-mini`) — input | 150 × 1,500 = 225K tokens | $0.150 / 1M | **$0.0338** |
| Chat (`gpt-4o-mini`) — output | 150 × 500 = 75K tokens | $0.600 / 1M | **$0.0450** |
| Embeddings (`text-embedding-3-small`) | ~30 calls × 500 tokens = 15K tokens | $0.020 / 1M | **$0.0003** |
| Transcription (`whisper-1`), *if used* | ~1 audio minute / day = 30 min | $0.006 / min | **$0.1800** |
| **Total, chat + embeddings only** | | | **≈ $0.08 / user / month** |
| **Total, including daily voice notes** | | | **≈ $0.26 / user / month** |

### Sensitivity

- Double the output-token assumption (1K avg output) → chat cost
  rises to **≈ $0.12/user/month** (whisper unchanged).
- If `workout.full_week` (bulkier, ~4K in / 2K out) is 20% of the mix:
  chat cost rises to **≈ $0.14/user/month**.
- Had we stayed on `text-embedding-3-large`, embeddings would cost
  **$0.002/user/month** instead of **$0.0003** — negligible at this
  volume but 6.5× per call; the swap matters once embeddings are run
  against large corpora (e.g. bulk re-index).

## Operational notes

- Quota + rate limits are enforced in `lib/services/ai/rate_limiter.dart`
  and `lib/services/ai/ai_usage_service.dart` before any network call.
- The update-ai-usage Supabase function logs token counts per call
  so the above numbers should be validated against real usage before
  any pricing decisions.
- `embeddingDim()` returns 1536 for both `-3-small` and `-3-large`, so
  the pgvector columns defined in `supabase/migrations/0004_ai_core_embeddings.sql`
  remain compatible and no re-indexing is required.
