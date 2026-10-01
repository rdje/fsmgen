---
id: task-tree-closed-history-boundary
title: Closed task-history suffixes require a committed legal heading
answers:
  - "how is a closed task acceptance-history boundary selected?"
  - "why must the semantic history boundary commit before rollover?"
date: 2026-10-01
status: current
tags: [task-tree, doctrine, continuity, history]
evidence: docs/audits/semantic-history-rollover-20261001/manifest.json; docs/tasks/history/SEMANTIC-INTROSPECTION-MCP-FRONTIER/acceptance-history.jsonl; docs/TASK_TREE.md; scripts/check_task_tree_integrity.pl; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- python3 docs/audits/semantic-history-rollover-20261001/verify.py
---

The acceptance-history manifest authenticates an exact committed predecessor
and a suffix beginning at a unique named level-two heading. Its unchanged
closed heading contract forbids empty headings, newlines and backticks.

The former semantic `Decisions` boundary was retired under `.54`; the next
closed acceptance heading contains backticks. `.64.1` therefore inserts one
legal `Completed Acceptance History` heading before the closed body and
commits it without deleting history or altering the manifest. `.64.2` consumes
committed b2669c3fafe36b40f8f1897f48a954dcbf94a9bb and authenticates its complete
source/suffix plus prior manifest/source chain under unchanged registry bounds.
The live file retires only closed prose. Distinct Python/Perl census and real
read-only checker controls reject corrupt hashes, string dimensions, absent
boundaries and displaced pointers; all other node contracts remain identical. Current node contracts
and native/feature limits remain ahead of the boundary. Complete source and
suffix products overlap and are authenticated separately; neither represents
discarded bytes. Existing Git retention preserves prior history chains.
