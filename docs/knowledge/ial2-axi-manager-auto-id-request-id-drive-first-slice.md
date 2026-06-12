---
id: ial2-axi-manager-auto-id-request-id-drive-first-slice
title: AXI manager auto-ID request-ID drive is shipped
answers:
  - "is AXI auto-ID request-ID drive shipped?"
  - "is AXI auto-ID allocation implemented now?"
  - "are AXI automatic IDs allocated now?"
  - "does auto-id-lifecycle change generated HDL?"
  - "what does auto_id_lifecycle report now?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.23?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, id, auto-id, ppif, systemverilog, task-tree]
evidence: docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md; ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.23` ships bounded request-ID drive for
explicit AXI manager `auto-id-lifecycle` families.

With `(auto-id-lifecycle (write (pool 0 1)))`, generated IAL1 declares the
write request ID signal as a generated output, for example
`(output axi0_awid (width 4))`. It also declares per-auto-transaction
selected-ID and busy state, emits deterministic first-free allocation rules,
emits completion-event release rules, and uses generated priority edges so
the existing IAL1 rule-conflict checker can verify the generated rule set.

Generated `.fsm` carries `+size` entries for the request ID output and
auto-ID state, rule DTs for allocation/release, and `+assert` carriers for
no-ID-available, completion-while-inactive, and simultaneous same-family
auto-ID requests. SystemVerilog declares the request ID and auto-ID state
registers and emits those assertions through the existing assertion backend.

The report sets `auto_id_lifecycle.generated_behavior` to true and includes
`transaction_state[]` entries naming selected-ID storage, busy storage,
allocation rules, release rules, and assertion names. Shipped allocation and
release behavior are no longer listed as residue; same-ID ordering and
response demux remain residue.

Existing `(id auto)` transactions remain structural/report-only when the
explicit `auto-id-lifecycle` clause is absent.
