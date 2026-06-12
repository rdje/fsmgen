---
id: ial2-axi-manager-id-family-first-slice
title: AXI manager ID-family metadata first slice is shipped
answers:
  - "is AXI manager ID-family metadata shipped?"
  - "how do I use AXI manager id-families in PPIF?"
  - "does id-families change generated .isf .fsm or HDL?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.9?"
  - "what sample covers AXI manager ID-family metadata?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, id-family, ppif, task-tree]
evidence: docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md; ppif/axi_manager_capacity_status_id_family.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/book/src/14-feature-backlog.md
reverify: prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.9` ships optional `(id-families ...)`
metadata under the existing public `.ppif` `manager-capacity-status` object.
The checked-in sample is
`ppif/axi_manager_capacity_status_id_family.ppif`, support-accounted as
`intent.ppif_axi_manager_capacity_status_id_family`.

The report additively emits `id_families.write` and `id_families.read` with
width, present/absent state, positive-width request/response ID signal names,
and source anchors. This is static metadata only: generated `.isf`, generated
`.fsm`, and HDL behavior are unchanged with or without `id_families`.

ID allocation, per-transaction user-ID validation, same-ID ordering,
different-ID interleaving, `BID`/`RID` response matching, bursts,
queued/blocking policy, profile aliases, full AXI manager behavior, and VHDL
remain future exact-owner residue.
