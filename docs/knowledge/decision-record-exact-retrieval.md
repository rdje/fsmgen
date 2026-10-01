---
id: decision-record-exact-retrieval
title: Sealed decision records preserve authority and exact retrieval
answers:
  - "how do I read the original text of a sealed decision?"
  - "does archiving a decision supersede its authority?"
  - "why do early decision files contain forwarding links?"
  - "how is decision archive reconstruction checked?"
  - "how must current decision edits synchronize the authenticated catalog?"
date: 2026-10-01
status: current
tags: [memory, decisions, archive, continuity]
evidence: docs/decisions/0108-decision-records-seal-originals-with-stable-retrieval.md; docs/decisions/INDEX.md; scripts/decision_records.py; t/1923-decision-record-archive.t
reverify: scripts/decision_records.py check && prove -Iperl t/1923-decision-record-archive.t
---

The sealed decision cohort keeps its original paths as forwarding pages.
Follow the complete-record link or run `scripts/decision_records.py read 0014`
from the repository root. Multiple IDs return their exact original text in
requested order. No historical Git object or network access is needed for
ordinary reading. The index remains the discovery route for all decisions.

Original text lives in the immutable JSON archive; the generated human view
relocates its relative links. Storage never supersedes authority. Preserve
existing supersession markers and record later policy changes through new
decisions and the index. Do not append to the archive or generated view.

The live-document projection verifier checks exact originals against the
independently committed source census, then verifies the view, root pointers,
index links, link destinations and affected Knowledge Map body-search commands.
The regression test independently compares reader bytes with the fixed Git
source and rejects planted retention and navigation defects. Root alias
cardinality remains live file-count pressure and has a separate scheduled owner.

Current decision bodies live in semantic parts under `docs/decisions/current/`.
An edit must synchronize that ID's `content` dimensions/digest and `metadata`
with `docs/decisions/current/catalog.json`; otherwise the reader and staged
doctrine gate reject the changed body. `scripts/decision_records.py check`
validates the complete worktree store; `--snapshot index --prior-snapshot HEAD
check-continuity` verifies the staged store against its committed predecessor.
Captured originals, compatibility pages and the transition census stay sealed.
