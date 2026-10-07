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
date: 2026-10-07
status: current
tags: [memory, decisions, archive, continuity]
evidence: docs/decisions/0108-decision-records-seal-originals-with-stable-retrieval.md; docs/decisions/INDEX.md; scripts/decision_records.py; t/1923-decision-record-archive.t
reverify: scripts/decision_records.py check && prove -Iperl t/1923-decision-record-archive.t t/2003-decision-store-git-continuity.t
---

Sealed decisions keep their original paths as forwarding pages. Follow the
complete-record link or run scripts/decision_records.py read 0014 from the
root. Multiple IDs return exact originals in requested order; the index discovers
all decisions. Immutable JSON retains originals; the human view relocates relative links.
Storage preserves authority and supersession. Later policy changes use new
decisions and the index, never appends to archive or generated view.

Projection checks compare originals to the independent committed census, then
verify view, root pointers, index links/destinations and affected Knowledge Map
body-search commands. Regression reads compare fixed Git bytes and reject
retention/navigation defects. Root aliases remain live file pressure with a
separately scheduled owner.

Current bodies live in semantic parts under docs/decisions/current/. Edits sync
that ID's content dimensions/digest and metadata with current/catalog.json or
reader/staged gates reject. check validates the whole worktree store;
--snapshot index --prior-snapshot HEAD check-continuity compares staged and
committed stores. Originals, compatibility pages and transition census stay sealed.

Selected Git trees stream standard NUL paths into index zero-stage metadata under
the unchanged byte budget. T2003 compares every mode/object/path and rejects
old-header/real-overflow controls; custom Git format quoting is avoided.
Owner/evidence: SEMANTIC-INTROSPECTION-MCP-FRONTIER.77.1; docs/audits/decision-git-inventory-20261007/.
