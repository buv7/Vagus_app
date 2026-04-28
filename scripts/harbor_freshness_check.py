#!/usr/bin/env python3
"""
HARBOR — weekly translation freshness check.

Flags any key in app_en.arb whose English value was changed more recently than
the corresponding AR/KU translation. Outputs a stale-translation report to
.oxbar/reports/harbor-stale.md.

Usage:
    python3 scripts/harbor_freshness_check.py [--days N] [--repo ROOT]

    --days N      Staleness threshold in days (default: 30).
                  A translation is stale when its last git-change is more than
                  N days older than the EN key's last git-change.
    --repo ROOT   Path to git repo root (default: current directory).

Exit codes:
    0 — no stale translations found
    1 — one or more stale translations found (report written)
    2 — l10n pipeline not bootstrapped (app_en.arb missing — TONGUE not done)
"""

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


ARB_EN = Path("lib/l10n/app_en.arb")
ARB_AR = Path("lib/l10n/app_ar.arb")
ARB_KU = Path("lib/l10n/app_ku.arb")
REPORT_PATH = Path(".oxbar/reports/harbor-stale.md")


# ── git helpers ──────────────────────────────────────────────────────────────

def git(*args, cwd=None):
    result = subprocess.run(
        ["git"] + list(args),
        capture_output=True, text=True, cwd=cwd
    )
    return result.stdout.strip()


def get_commit_log(file_path):
    """Return list of (commit_hash, timestamp) for all commits touching file."""
    raw = git("log", "--format=%H %aI", "--", str(file_path))
    entries = []
    for line in raw.splitlines():
        parts = line.split(" ", 1)
        if len(parts) == 2:
            try:
                dt = datetime.fromisoformat(parts[1])
                if dt.tzinfo is None:
                    dt = dt.replace(tzinfo=timezone.utc)
                entries.append((parts[0], dt))
            except ValueError:
                pass
    return entries  # newest first


def get_arb_at_commit(commit_hash, file_path):
    """Return parsed ARB dict at a specific commit, or {} on failure."""
    content = git("show", f"{commit_hash}:{file_path}")
    if not content:
        return {}
    try:
        data = json.loads(content)
        return {k: v for k, v in data.items()
                if not k.startswith("@") and k != "@@locale"}
    except json.JSONDecodeError:
        return {}


def build_key_history(file_path, keys_of_interest):
    """
    Return dict: {key: last_change_datetime} for the given set of keys.

    Walks the git log for file_path. For each commit, compares the ARB snapshot
    to its parent. When a key's value changes, records the commit's timestamp
    as that key's last-change date (git log is newest-first, so first match wins).
    """
    commits = get_commit_log(file_path)
    if not commits:
        return {}

    key_last_changed = {}
    remaining = set(keys_of_interest)

    # Seed: current state
    prev_data = get_arb_at_commit(commits[0][0], file_path)

    for i, (commit_hash, commit_dt) in enumerate(commits):
        if not remaining:
            break

        if i == len(commits) - 1:
            # Oldest commit — everything present here was "added" then.
            parent_data = {}
        else:
            parent_data = get_arb_at_commit(commits[i + 1][0], file_path)

        for key in list(remaining):
            current_val = prev_data.get(key)
            parent_val = parent_data.get(key)
            if current_val != parent_val:
                key_last_changed[key] = commit_dt
                remaining.discard(key)

        prev_data = parent_data

    return key_last_changed


# ── ARB loading ───────────────────────────────────────────────────────────────

def load_arb(path):
    """Return dict of user-facing keys, or None if file missing."""
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        return {k: v for k, v in data.items()
                if not k.startswith("@") and k != "@@locale"}
    except FileNotFoundError:
        return None
    except json.JSONDecodeError as e:
        print(f"ERROR: {path} is not valid JSON: {e}", file=sys.stderr)
        sys.exit(1)


# ── report ────────────────────────────────────────────────────────────────────

def write_report(stale_ar, stale_ku, missing_ar, missing_ku, threshold_days, en_data):
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    total_stale = len(stale_ar) + len(stale_ku) + len(missing_ar) + len(missing_ku)

    lines = [
        f"# HARBOR — Translation Freshness Report",
        f"",
        f"**Generated:** {now}  ",
        f"**Staleness threshold:** {threshold_days} days  ",
        f"**Total issues:** {total_stale}",
        f"",
    ]

    if total_stale == 0:
        lines += [
            "## ✅ All translations are fresh",
            "",
            "No keys require re-translation. Good work, POLYGLOT-AR and POLYGLOT-KU.",
        ]
    else:
        lines += [
            "## Summary",
            "",
            f"| Issue type                   | Count |",
            f"|------------------------------|-------|",
            f"| AR stale (EN changed, AR old)| {len(stale_ar):5} |",
            f"| KU stale (EN changed, KU old)| {len(stale_ku):5} |",
            f"| Missing in AR                | {len(missing_ar):5} |",
            f"| Missing in KU                | {len(missing_ku):5} |",
            f"",
            f"**Owner for AR issues:** POLYGLOT-AR  ",
            f"**Owner for KU issues:** POLYGLOT-KU",
            f"",
        ]

        def key_table(entries, label):
            if not entries:
                return []
            out = [f"### {label} ({len(entries)} keys)\n"]
            out += [f"| Key | EN value | EN last changed | Translation last changed |"]
            out += [f"|-----|----------|-----------------|--------------------------|"]
            for key, en_date, tr_date in sorted(entries, key=lambda x: x[0]):
                en_val = str(en_data.get(key, ""))[:60].replace("|", "\\|")
                en_str = en_date.strftime("%Y-%m-%d") if en_date else "unknown"
                tr_str = tr_date.strftime("%Y-%m-%d") if tr_date else "never"
                out.append(f"| `{key}` | {en_val} | {en_str} | {tr_str} |")
            return out + [""]

        def missing_table(keys, label):
            if not keys:
                return []
            out = [f"### {label} ({len(keys)} keys)\n"]
            out += ["| Key | EN value |"]
            out += ["|-----|----------|"]
            for key in sorted(keys):
                en_val = str(en_data.get(key, ""))[:60].replace("|", "\\|")
                out.append(f"| `{key}` | {en_val} |")
            return out + [""]

        lines += key_table(stale_ar,  "⚠️ Arabic — stale (EN changed, AR not updated)")
        lines += key_table(stale_ku,  "⚠️ Kurdish-Sorani — stale (EN changed, KU not updated)")
        lines += missing_table(missing_ar, "❌ Arabic — key missing entirely")
        lines += missing_table(missing_ku, "❌ Kurdish-Sorani — key missing entirely")

        lines += [
            "---",
            "",
            "_This report is generated weekly by HARBOR. "
            "POLYGLOT-AR and POLYGLOT-KU should address stale translations within 7 days of this report._",
        ]

    REPORT_PATH.write_text("\n".join(lines), encoding="utf-8")
    print(f"Report written to {REPORT_PATH}")
    return total_stale


# ── main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="HARBOR translation freshness check")
    parser.add_argument("--days", type=int, default=30,
                        help="Staleness threshold in days (default: 30)")
    parser.add_argument("--repo", type=str, default=".",
                        help="Path to git repo root (default: current directory)")
    args = parser.parse_args()

    os.chdir(args.repo)

    en_data = load_arb(ARB_EN)
    if en_data is None:
        print(
            "HARBOR: app_en.arb not found. "
            "TONGUE has not bootstrapped the i18n pipeline yet. "
            "Freshness check skipped.",
            file=sys.stderr,
        )
        sys.exit(2)

    ar_data = load_arb(ARB_AR)
    ku_data = load_arb(ARB_KU)

    en_keys   = set(en_data)
    ar_keys   = set(ar_data) if ar_data is not None else set()
    ku_keys   = set(ku_data) if ku_data is not None else set()

    # Keys present in both EN and the target locale — check staleness.
    ar_shared = en_keys & ar_keys
    ku_shared = en_keys & ku_keys
    # Keys in EN but absent from target — flag as missing.
    missing_ar = list(en_keys - ar_keys)
    missing_ku = list(en_keys - ku_keys)

    all_tracked = en_keys | ar_keys | ku_keys
    print(f"Building key history for {len(en_keys)} EN keys …")

    en_history = build_key_history(ARB_EN, en_keys)
    ar_history = build_key_history(ARB_AR, ar_shared) if ar_data is not None else {}
    ku_history = build_key_history(ARB_KU, ku_shared) if ku_data is not None else {}

    threshold_days = args.days
    stale_ar = []
    stale_ku = []

    for key in en_keys:
        en_date = en_history.get(key)
        if en_date is None:
            # Key has no git history (perhaps arb was bulk-added with no prior state)
            continue

        # Arabic staleness
        if key in ar_keys:
            ar_date = ar_history.get(key)
            if ar_date is None or (en_date - ar_date).days > threshold_days:
                stale_ar.append((key, en_date, ar_date))

        # Kurdish-Sorani staleness
        if key in ku_keys:
            ku_date = ku_history.get(key)
            if ku_date is None or (en_date - ku_date).days > threshold_days:
                stale_ku.append((key, en_date, ku_date))

    total = write_report(stale_ar, stale_ku, missing_ar, missing_ku, threshold_days, en_data)

    if total > 0:
        print(
            f"\n{total} issue(s) found. "
            f"See {REPORT_PATH} for details."
        )
        sys.exit(1)

    print("All translations fresh. No issues found.")
    sys.exit(0)


if __name__ == "__main__":
    main()
