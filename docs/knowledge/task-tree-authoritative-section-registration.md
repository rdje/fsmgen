---
id: task-tree-authoritative-section-registration
title: Ownership registration requires the parsed Task Tree section and parent reference
answers:
  - "why can whole-file task IDs miss authoritative ownership registration?"
  - "which completed semantic nodes were outside the authoritative task section?"
  - "how is semantic node registration repaired without changing historical-view doctrine?"
date: 2026-10-01
status: current
tags: [task-tree, doctrine, continuity, integrity]
evidence: docs/audits/semantic-node-registration-20261001/manifest.json; docs/audits/semantic-node-registration-20261001/verify.py; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; scripts/check_task_tree_integrity.pl
reverify: scripts/run_with_ram_guard.sh -- python3 docs/audits/semantic-node-registration-20261001/verify.py
---

SEM `.65` restores completed ownership records `.61` (reset question), `.62`
(reset grammar repair) and `.63` (historical secondary-view retirement) to the
authoritative first `## Task Tree` section and its exact root child list.
Their entire original contracts, statuses, verification and commit fields
remain byte-identical. Code, feature outcomes and native evidence are unchanged.

The checker ends the section at the next level-two heading; those records had
been introduced after that boundary. Whole-file ID preservation in `.63` did
not establish their authoritative registration. This limitation is explicitly
corrected by the new repair, rather than changing the checker or treating
decision-0019 historical convenience views as live projections.

The exact predecessor and qualified source blob are authenticated in the audit
manifest. Independent line-based extraction and complete contract comparison
re-derive preservation. The actual public checker runs on plain same-volume
fixtures: the former graph passes structurally while omitting the hidden
ownership; the corrected graph passes with complete registration. A misplaced
node retains identical whole-file IDs but is correctly rejected, as are missing
node/root reference and duplicate controls. Independent comparison rejects a
changed complete contract. No additional Git repository is created or modified.
The tracked proof, exact retained Git objects, original records, task and book
provide durability; active feature execution remains separately owned.
