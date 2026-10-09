---
id: decision-selected-inventory-byte-budget
title: Selected decision Git inventory uses existing metadata byte budget
answers:
  - "why did selected decision continuity reject unrelated tracked evidence growth?"
  - "what bounds complete selected decision Git path inventories?"
  - "does the selected inventory repair weaken blob or metadata byte limits?"
date: 2026-10-09
status: current
tags: [decisions, git, continuity, memory, capacity]
evidence: >-
  scripts/decision_store_git.py; t/python/test_decision_store_git.py;
  docs/audits/record-output-predecessors-20261002/manifest.json;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md;
  docs/book/src/10-errors-strict-mode-and-troubleshooting.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2003-decision-store-git-continuity.t t/2004-decision-reader-snapshots.t
  t/2005-decision-ceiling-stores.t t/2007-decision-hostile-boundaries.t
  t/2010-decision-production-growth.t
---

Selected reads pin every repository path/mode/object, including unrelated evidence. Old entry cap
rejected actual staged predecessor within metadata bytes; exact Git census/failed gate and
selected-continuity preparation history retain its cause.

Bound: unchanged metadata bytes / minimum SHA-1 index-record size (trees longer). Pin before
index/worktree changes: no filtering, truncation, ambient fallback or submodule traversal.
Blob/output-byte, regular-mode, missing-path, unsafe-selector and conflicting-stage checks, ceilings
and store pins stay unchanged.

Re-derive: project-local index/tree fixtures exceed the old count; independent full
membership/authenticated reads. Falsify: real byte overflow in both selectors and
hostile/identity/snapshot/gate controls. Durability: exact RED/current tests, code/census/Git,
failed gate/sealed evidence, book/task/facts/Git. No unbounded repository or metadata/blob-byte
budget increase.
