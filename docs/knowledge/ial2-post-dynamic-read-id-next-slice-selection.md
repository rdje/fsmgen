---
id: ial2-post-dynamic-read-id-next-slice-selection
title: Post dynamic read ID selector chooses dynamic read RLAST readiness
answers:
  - "what comes after dynamic read ID demux?"
  - "what is the next IAL2 slice after dynamic read RID matching?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.228 select?"
  - "why is dynamic read burst-last RLAST an audit next?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-response-demux, rlast, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_ID_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/knowledge/ial2-dynamic-read-transaction-id-capture-behavior.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.228|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.229|POST_DYNAMIC_READ_ID_NEXT_SLICE_SELECTION|dynamic read burst-last|RLAST transaction-ID capture' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_ID_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.228` selects `.229`, readiness audit for
dynamic read burst-last/`RLAST` transaction-ID capture and response matching.

The selector keeps behavior unchanged. It records that `.229` must audit
last-beat response scope, `RLAST` signal ownership, selected-ID/busy lifetime,
generated completion/release semantics, assertions, report vocabulary,
read-data and burst/runtime interactions, validation gates, rollback, and
explicit residue before any parser, generator, PPIF sample, support-accounting
catalog, generated artifact, test, validation, or HDL behavior changes.

The selector found no immediate report/static/support cleanup prerequisite
after `.227`; the shipped dynamic read behavior already identifies burst-last,
read-data, multiple/mixed, same-cycle, same-ID, queue/scoreboard,
direct-backend, and VHDL boundaries as deferred.
