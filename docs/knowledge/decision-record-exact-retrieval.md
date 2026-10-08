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
reverify: scripts/decision_records.py check && prove -Iperl t/1923-decision-record-archive.t t/2003-decision-store-git-continuity.t && scripts/run_with_ram_guard.sh -- python3 -B docs/audits/decision-index-repair-20261008/verify.py
---

Sealed decisions keep forwarding paths. Follow full-record links or run
scripts/decision_records.py read 0014 at root. Ordered IDs give exact originals;
the index finds all. JSON originals and human-view relocated relative links retain
authority/supersession. Later policy needs new decision/index; no archive/generated-view appends.

Checks: independent committed-original census; view/root/index links/targets; affected
Knowledge Map body-search commands. Fixed-Git regression rejects retention/navigation
defects. Root aliases retain live pressure; separate owner.

Semantic parts: docs/decisions/current/. Sync dimensions/digest/metadata in
current/catalog.json; reader/staged gates reject drift. check verifies the whole
worktree; --snapshot index --prior-snapshot HEAD check-continuity compares staged/committed
stores. Originals, compatibility and transition census stay sealed.

Standard NUL trees become zero-stage index metadata under unchanged limits. T2003
checks every mode/object/path plus old-header/real-overflow refusals; no custom quoting.
SEM.77.1: docs/audits/decision-git-inventory-20261007/.

SEM.78 captures decisions, source/legacy links/consumers, controls and ancestors.
Trusted census mode/object joins bootstrap/final; HEAD resolves once. Default whole
and relevant overflow refuse; dated stock evidence retains.
