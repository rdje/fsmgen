---
id: ial2-axi-manager-capacity-status-ppif-first-slice
title: AXI manager capacity/status public PPIF first slice shipped
answers:
  - "is public .ppif AXI manager capacity/status shipped?"
  - "how do I run the AXI manager capacity/status .ppif sample?"
  - "what does ppif/axi_manager_capacity_status.ppif generate?"
  - "does AXI manager capacity/status .ppif preserve public source identity?"
  - "what remains out of scope after the capacity/status PPIF first slice?"
date: 2026-06-12
status: current
tags: [ial2, ppif, axi, manager, capacity, status, cli, semantic-json]
evidence: docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md; ppif/axi_manager_capacity_status.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/book/src/14-feature-backlog.md
reverify: prove -Iperl t/1436-ial2-ppif-parser-cli.t
---

Public `.ppif` AXI manager capacity/status is shipped for exactly one
`(manager-capacity-status NAME ...)` object under a
`(protocol-platform-intent ...)` root with `(profile axi4)` and top-level
source anchors. The tracked sample is
`ppif/axi_manager_capacity_status.ppif`.

The CLI supports schedule JSON, `--outdir`, default HDL, `--verify-hdl`,
`--check --json`, and `--emit-semantic-json` for that sample. The path remains
reviewable: the adapter maps the PPIF object to
`FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`, emits generated
`axi0_capacity_status.isf` before generated `axi0_capacity_status.fsm`, and
then emits the `axi0_capacity_status` SystemVerilog module from the generated
`.fsm`.

Support accounting names the sample
`intent.ppif_axi_manager_capacity_status`; check JSON and normalized semantic
JSON preserve `source.resolved_path` on the public `.ppif` source. Mixed
Valid-Ready/manager objects, multiple managers, IDs, ordering, response
matching, bursts, queued/blocking policy, profile aliases, full AXI manager
behavior, and VHDL remain future task-tree-owned residue.
