---
id: ial2-axi-manager-auto-id-lifecycle-metadata-first-slice
title: AXI manager auto-ID lifecycle metadata is shipped
answers:
  - "is AXI auto-ID lifecycle metadata shipped?"
  - "what sample covers AXI auto-ID lifecycle metadata?"
  - "does auto-id-lifecycle change generated HDL?"
  - "what does auto_id_lifecycle report?"
  - "what support-accounting entry covers auto-id-lifecycle?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.23?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, id, auto-id, ppif, task-tree]
evidence: docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_METADATA_FIRST_SLICE.md; ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.22` ships the additive public
`auto-id-lifecycle` parser/report metadata slice for the AXI manager
`manager-capacity-status` object.

The checked-in sample is
`ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif`, support accounted
as `intent.ppif_axi_manager_capacity_status_auto_id_lifecycle`.

The public syntax is:

```text
(auto-id-lifecycle
  (write (pool 0 1)))
```

The report emits `auto_id_lifecycle` with
`mode: bounded_pool_contract`, `generated_behavior: false`, request ID
direction `generated_output`, response ID direction `generated_input`,
author-ordered bounded pools, allocator `first_free_pool_order`,
single-active transaction lifetime, completion-event release, runtime
no-ID behavior, auto transaction names, and residue for generated request-ID
drive and release rules.

This slice does not change generated `.isf`, `.fsm`, or HDL behavior. Existing
`(id auto)` transactions remain structural/report-only when the clause is
absent.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.23` owns the next step: implement the
bounded auto-ID request-ID drive behavior for the explicit lifecycle contract.
