---
id: ial2-axi-manager-concrete-id-assertions-first-slice
title: AXI manager concrete ID assertions are shipped
answers:
  - "are AXI concrete transaction ID assertions shipped?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.18 ship?"
  - "what is id_response_rule_engine?"
  - "do concrete AXI transaction IDs emit +assert carriers?"
  - "does FSMGen allocate AXI IDs now?"
date: 2026-06-12
status: current
tags: [ial2, ial1, axi, manager, id, assertions, systemverilog, task-tree]
evidence: docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.18` shipped concrete AXI manager
transaction ID request/response assertions under the existing public
`manager-capacity-status` `.ppif` object.

No new public clause is introduced. Existing `id_families` plus
`transactions` become behavior-bearing when a transaction uses concrete
`(id (value N))`.

Generated IAL1 declares the used positive-width ID-family request/response ID
signals, then emits assertion-only transaction checks. Generated `.fsm` exposes
matching `+size` entries and `+assert` carriers. SystemVerilog emits
verification-only concurrent assertions through the existing assertion backend.

Schedule/report JSON additively emits `id_response_rule_engine` with
`mode: concrete_id_assertions`, `id_signal_inputs`, request/response `checks`,
and explicit residue.

Auto-ID allocation, ID release, same-ID ordering, generated response demux,
bursts, queued/blocking policy, aliases, full AXI manager behavior, and VHDL
remain future exact-owner work.
