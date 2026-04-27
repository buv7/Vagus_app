# Security Policy

Vagus is a fitness-coaching platform that handles workout, nutrition, lab-work, period-tracking, wearable, payment, and chat data. Some of those categories are medical-grade and some of our users are minors under coach supervision. We take this seriously.

This document is the public security posture. Internal posture (key rotation cadence, incident drills, on-call rota) is tracked in `.oxbar/` and is not public.

---

## Reporting a vulnerability

**Email:** security@vagus.app
**Response target:** acknowledgement within 72 hours, triage within 7 days.

If you believe you have found a vulnerability — especially one touching authentication, payment, or any of the medical-data categories below — please email us before disclosing publicly. We do coordinated disclosure and will credit you in the release notes once a fix has shipped.

We do not currently run a paid bug bounty. We will reimburse reasonable expenses for testing under a coordinated-disclosure agreement.

**Out of scope:**
- Findings against third-party services we use (Supabase, Vercel, Cerebras, Groq, Gemini, OpenRouter) — please report those to the relevant vendor.
- Self-XSS, missing security headers without an exploit, anything requiring a rooted device + physical access.

---

## Supported versions

| Version | Supported |
|---------|-----------|
| 1.x (current) | yes |
| 0.9.x (pre-launch RC) | security fixes only |
| earlier | no |

---

## Data we collect

| Category | Examples | Encryption at rest | Encryption in transit | Audit log |
|----------|----------|--------------------|------------------------|-----------|
| Account / profile | email, name, DOB, role | Supabase managed (AES-256) | TLS 1.2+ | no |
| Workout / nutrition | sets, reps, foods, macros | Supabase managed | TLS 1.2+ | no |
| Lab work | biomarker values, ranges | column-encrypted (pgcrypto) | TLS 1.2+ | yes (`data_access_audit`) |
| Period tracking | cycle dates, symptoms | column-encrypted (pgcrypto) | TLS 1.2+ | yes (`data_access_audit`) |
| Wearable signals | HR, sleep, steps | column-encrypted (pgcrypto) | TLS 1.2+ | yes (`data_access_audit`) |
| Payment | last-4, charge IDs | provider-tokenized (no PAN stored) | TLS 1.2+ | n/a |
| Chat | message text, attachments | Supabase managed | TLS 1.2+ | no |
| AI prompts | LLM payloads | not retained beyond the request | TLS 1.2+ | n/a |

Column-encryption is implemented via Postgres `pgcrypto` (`pgp_sym_encrypt` / `pgp_sym_decrypt`). The symmetric key is provisioned per environment, never checked into the repo, and rotated quarterly.

Audit logs survive the lifetime of the data subject. When a user requests deletion under GDPR Article 17, both the data and the audit log entries are erased together.

---

## How coach access works

A coach can read a client's workout, nutrition, and chat data once the client has accepted the coach link. A coach **cannot** read a client's lab work, period tracking, or wearable data unless the client has granted explicit per-resource consent. The consent grant itself is also logged in `data_access_audit`.

---

## How AI calls work

We send anonymized, PII-stripped payloads to LLM providers (Cerebras, Groq, Gemini, OpenRouter) for: meal classification, exercise classification, summary generation, and conversational coaching prompts.

Every code path that hits an LLM endpoint is required to route through `lib/services/ai/pii_sanitizer.dart`. CI fails the build if a new call site bypasses the sanitizer. The sanitizer:

- Strips email addresses, phone numbers, credit-card-shaped numbers, government-ID-shaped numbers, and dates.
- Strips the user's known full name and individual name tokens.
- Hard-fails (in debug) and logs a SEVERE alert (in release) if any payload would still contain the user's name + a date in the same request.

LLM providers see anonymized strings only. We do not send a user's `auth.uid()`, name, DOB, email, phone, or street address.

---

## Child safety

Some clients are minors (under 18). The platform:
- Asks for DOB at account creation. If the calculated age is < 18, public-facing features (marketplace listings, public leaderboard, social sharing) are disabled by default.
- Never logs a full name + DOB together in any analytics event. CI enforces this via the same `pii_sanitizer.dart` rule used for LLM payloads.
- Requires the coach link for minors to be confirmed by an authenticated parent/guardian email before any messaging is enabled.

---

## Authentication

- Supabase Auth (email + password, magic link, OAuth where configured).
- Session tokens stored in `flutter_secure_storage` (iOS Keychain / Android Keystore).
- Optional biometric unlock via `local_auth`.
- Multi-factor auth via Supabase OTP (opt-in for clients, mandatory for staff and admin roles).

---

## Row-level security

The Supabase database uses RLS as its primary authorization layer. Every table that holds user-scoped data must:

1. Have `ROW LEVEL SECURITY` enabled.
2. Have at least one `CREATE POLICY` defined in the same migration file.

CI enforces this on every PR (`.github/workflows/vault.yml` → `rls_validation`). A migration that adds a `CREATE TABLE` without RLS and a matching policy in the same file fails the build. Genuinely-global lookup tables can be exempted with an inline annotation:

```sql
-- vault-rls-exempt: <table_name> reason: <one-line>
```

Exemptions are reviewed by the security agent (VAULT) on PR.

---

## Secret management

- No secret is ever committed to the repo. CI runs `gitleaks` on every PR.
- Real `.env` is gitignored. `.env.example` is the template that ships with the repo.
- The `.env` Flutter asset is **only** for local development convenience. **Production secrets MUST be supplied via `--dart-define` at build time**, never read from the bundled `.env` (because the asset ships inside the APK / IPA and is recoverable by anyone who decompiles the app).
- Supabase service-role keys, OpenRouter API keys, Cerebras / Groq / Gemini API keys live in CI secrets and in the deployment platform's environment-variable store.
- Staging credentials are tracked in `.oxbar/staging-secrets.md` (gitignored) and rotated quarterly by VAULT, or immediately if a leak is suspected.

---

## Third-party processors

| Provider | Purpose | Data category sent |
|----------|---------|--------------------|
| Supabase | database, auth, storage, edge functions | all categories (host of record) |
| Vercel | web app hosting | none beyond standard request logs |
| OpenRouter / Cerebras / Groq | LLM inference for chat & coaching features | sanitized prompts only — no PII |
| Google Gemini | food image classification | image bytes + sanitized prompt |
| Google Health Connect / Apple Health | wearable signal ingestion (on-device only) | n/a (data flows from device → our DB) |
| OneSignal | push notification delivery | device token + payload (no medical content) |

---

## Compliance posture

- We design to a **HIPAA-aligned** standard (encryption at rest, encryption in transit, audit logs on medical reads, role-based access control, BAAs with infrastructure providers where available). We are **not currently HIPAA-certified**.
- We honor **GDPR** rights: right to access (data export from settings), right to erasure (account deletion with audit-log purge), right to rectification (profile editing).
- Minor-protections follow a COPPA-style model regardless of jurisdiction.

---

## Disclosure timeline (target)

| Severity | Patch deadline | Disclosure window |
|----------|----------------|-------------------|
| Critical (data exposure, auth bypass) | 7 days | 30 days |
| High | 30 days | 60 days |
| Medium | 90 days | 90 days |
| Low | next minor release | with release notes |

If a coordinated-disclosure window is about to expire and we have not patched, we will engage the reporter to request a brief extension and document the reason.

---

## Cryptographic agility

If a primitive we depend on is broken or weakened (SHA-1-style deprecation, AES-CBC padding-oracle-class issue), we will:

1. Disable the affected primitive in new writes within 14 days.
2. Re-encrypt at-rest data with the replacement primitive within 90 days.
3. Document the migration in the release notes.

---

*Last reviewed: 2026-04-27 by VAULT. Next scheduled review: 2026-07-27.*
