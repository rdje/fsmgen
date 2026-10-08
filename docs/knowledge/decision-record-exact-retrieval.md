---
id: decision-record-exact-retrieval
title: Sealed decision records preserve authority and exact retrieval
answers:
  - "how do I read the original text of a sealed decision?"
  - "does archiving a decision supersede its authority?"
  - "why do early decision files contain forwarding links?"
  - "how is decision archive reconstruction checked?"
  - "how must current decision edits synchronize the authenticated catalog?"
  - "why can selected Git tree inventory overflow while the same index fits?"
  - "why does unrelated index growth block decision authentication?"
date: 2026-10-08
status: current
tags: [memory, decisions, archive, continuity]
evidence: docs/decisions/0108-decision-records-seal-originals-with-stable-retrieval.md; docs/decisions/INDEX.md; scripts/decision_records.py; t/1923-decision-record-archive.t
reverify: scripts/decision_records.py check && prove -Iperl t/1923-decision-record-archive.t t/2003-decision-store-git-continuity.t && scripts/run_with_ram_guard.sh -- python3 -B docs/audits/decision-index-scope-20261008/verify.py
---

Sealed decisions retain forwarding paths. Follow the full-record link or run
scripts/decision_records.py read 0014 at root. Ordered IDs return exact originals;
the index finds all. JSON originals and the human view’s relocated relative links
preserve authority/supersession. Later policy needs a new decision/index, never
archive/generated-view appends.

Projection checks: independent committed originals census; view/root pointers and
index links/targets; affected Knowledge Map body-search commands. Fixed-Git regression
reads reject retention/navigation defects. Root aliases keep live pressure with a separate owner.

Current bodies: semantic parts under docs/decisions/current/. Edits sync content
dimensions/digest and metadata in current/catalog.json or reader/staged gates reject.
check verifies the whole worktree; --snapshot index --prior-snapshot HEAD check-continuity
compares staged/committed stores. Originals, compatibility and transition census stay sealed.

Selected trees use standard NUL paths as index zero-stage metadata under the unchanged
byte budget. T2003 checks every mode/object/path and old-header/real-overflow refusals;
custom-format quoting is avoided. SEMANTIC-INTROSPECTION-MCP-FRONTIER.77.1;
docs/audits/decision-git-inventory-20261007/.

Dated unrelated-index overflow: P1 SEM.78; source hypothesis only.
