---
id: task-tree-stale-status-drift-repair
title: Task-tree stale status drift repair
answers:
  - "why does the task tree say PNT is exhausted while old task files mention pending or active?"
  - "are there stale active task markers in completed task trees?"
  - "how do I recheck stale task-tree status drift?"
date: 2026-06-12
status: current
tags: [task-tree, memory, continuity, pnt]
evidence: docs/TASK_TREE.md; docs/tasks/TASK-TREE-STALE-STATUS-DRIFT-REPAIR.md; docs/tasks/TASK-TREE-HYPHENATED-STATUS-DRIFT-REPAIR.md
reverify: perl -ne 'BEGIN { %skip = map { $_ => 1 } qw(docs/tasks/TEMPLATE.md docs/tasks/TASK-TREE-HYPHENATED-STATUS-DRIFT-REPAIR.md) } next if $skip{$ARGV}; if (/Status: .(active|proposed|in[_-]progress|pending)./) { print "$ARGV:$.:$_"; $bad = 1 } END { exit($bad ? 1 : 0) }' docs/tasks/*.md
---

The canonical task-tree index records no queued proposed tree and exhausted
active PNT after `IAL2-PPIF-BUNDLE-HDL-ENTRY-FIRST-SLICE.1`. Several completed
task files still carried internal `Status: pending` or `Status: active` node
markers from historical selection slices; those markers were continuity drift,
not eligible work.

`TASK-TREE-STALE-STATUS-DRIFT-REPAIR.1` normalized those stale markers in the
completed task files so non-template task files no longer expose
`active`/`in_progress`/`in-progress`/`proposed`/PNT-eligible `pending` statuses
outside the current repair leaf while the repair is in flight. A follow-up
hyphenated-status repair normalized the historical `ISF-TRIGGER-ANCHOR`
metadata value and hardened this recheck to include both spellings.
