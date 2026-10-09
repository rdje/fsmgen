---
id: decision-selected-inventory-byte-budget
title: Selected decision Git inventories follow the existing metadata byte budget
answers:
  - "why did selected decision continuity reject unrelated tracked evidence growth?"
  - "what bounds complete selected decision Git path inventories?"
  - "does the selected inventory repair weaken blob or metadata byte limits?"
date: 2026-10-02
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

The selected reader captures the complete repository path/mode/object inventory,
including unrelated tracked evidence. Its former independent entry-count cap
blocked the actual staged predecessor slice while its metadata still fit the
existing byte budget. Exact Git census and the failed staged gate retain that
cause; history roots the cap at the selected-continuity preparation commit.

The entry bound now derives from the unchanged metadata byte budget divided by
the minimum SHA-1 index record size. Tree records are longer. Capture remains
complete and pinned before any later mutable index/worktree changes; there is
no path filtering, truncation, ambient fallback or submodule traversal. Selected
blob, output-byte, regular-mode, missing-path, unsafe-selector and conflicting
stage checks remain in place. Live-document ceilings and store pins are unchanged.

Actual project-local Git fixtures crossing the old count in both index and
committed trees provide re-derivation, including full independent path membership
and authenticated store reads. Actual metadata byte overflow in both selectors,
plus existing hostile/identity/snapshot/gate controls provide falsification.
Exact RED/current tests, code/census/Git identities, failed staged receipt and
sealed evidence, book/task/facts/Git retain durability. This does not claim an
unbounded repository or increase the metadata/blob byte budget.
