---
id: ial2-post-multiple-dynamic-read-rlast-response-demux-next-slice-selection
title: IAL2 post multiple dynamic read RLAST demux selects read-data readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.256 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.257?"
  - "what is next after multiple dynamic read RLAST demux?"
  - "why audit read-data after multiple dynamic read RLAST demux?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, read-data, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.256|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.257|POST_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_NEXT_SLICE_SELECTION|read_data\\.read dynamic coverage requires exactly one dynamic read transaction|read-data over generated multiple dynamic read response-demux' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.256` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.257`, readiness audit for read-data over
generated multiple dynamic read response-demux.

The reason is dependency order. `.255` shipped the multiple dynamic read
burst-last/`RLAST` response-demux substrate, but the dynamic read-data coverage
helper still requires exactly one dynamic read transaction. Read-data must
learn how to map multiple dynamic read transactions to generated completion
pulses before burst-length/runtime validation or multi-beat output banks can
widen over multiple dynamic read demux.

`.257` is audit-only unless it explicitly selects a later implementation
owner. It should cover the `.251` single-beat and `.255` burst-last multiple
dynamic read response-demux shapes, scalar single-beat and last-beat
read-data, transaction-to-completion mapping, report/residue vocabulary,
diagnostics, validation, rollback, and preserved residue for burst-length,
runtime validation, multi-beat output banks, mixed dynamic/static demux,
same-cycle behavior, queues, scoreboards, backend-language variants, and
VHDL.
