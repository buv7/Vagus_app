# OXBAR Escalations to Alhassan

> Items blocked on human owner. Alhassan checks once daily.
> Format: timestamp · agent · short title · question/decision needed.
> When resolved, mark `RESOLVED: <date>` and append Alhassan's call.

---

## E-001 · 2026-04-27 · POLYGLOT-KU · Kurdish-Sorani translation pipeline needs human-in-the-loop arrangement

**Decision needed:** How should POLYGLOT-KU produce `lib/l10n/app_ku.arb` at the quality bar the mission demands?

**Why escalating (not just BLOCKED-on-TONGUE):** TONGUE blocking is expected (Wave B). The deeper question is independent of TONGUE: even once `app_en.arb` exists, POLYGLOT-KU's mission requires (a) Gemini Flash API access, neither of which is provisioned, and (b) a native-Sorani reviewer pass. Mission FORBIDS auto-accepting LLM output and explicitly notes Sorani LLM quality is "lower base" than Arabic. Without these, the agent will either ship low-quality strings (violates FORBIDDEN) or sit BLOCKED indefinitely.

**Options:**
- **(1)** Provision Gemini API key in agent env + arrange recurring Sorani reviewer (e.g. weekly review batches). Agent operates as designed.
- **(2)** Drop Sorani from launch scope; mark POLYGLOT-KU ABANDONED; ship app with EN/AR only and add KU post-launch via human translator.
- **(3)** Accept lower quality bar: let agent generate Gemini-only output, mark every string with a `// review-pending` marker in the .arb, push to a feature-flagged KU locale invisible to users until reviewed. Requires explicit waiver of the mission's FORBIDDEN clause.

**Recommendation:** (1) if Sorani at launch is a hard requirement; (2) if it's nice-to-have. (3) is workable but needs explicit waiver in writing — agent will not self-authorize this.

**Blocking:** POLYGLOT-KU progress past PENDING-glossary work. Not blocking other agents.
