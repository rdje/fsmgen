---
id: ial2-feature-completeness-next-slice
title: The active IAL2 next slice is selected by the task-tree frontier
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what is the next IAL2 PNT task?"
  - "what is the next AXI manager slice?"
date: 2026-08-01
status: current
tags: [ial2, task-tree, pnt, current-routing]
evidence: >-
  docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md
reverify: >-
  rg -n 'Current frontier|Next action|Status: `active`'
  docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md
---

The next IAL2 slice is whatever the active frontier row in
`docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md` selects. This card is a
stable route to that live authority; it deliberately does not copy a leaf ID
that becomes stale after every completed slice.

The pre-containment card's `.211`–`.276` chronology is split into bounded
historical cards and remains exactly version-retrievable from activation
commit `aadbd14a5`.
