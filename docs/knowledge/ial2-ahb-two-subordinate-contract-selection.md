---
id: ial2-ahb-two-subordinate-contract-selection
title: First AHB two-subordinate contract selects generic PPIF implementation
answers:
  - "what AHB two-subordinate contract was selected?"
  - "which task owns AHB two-subordinate implementation?"
  - "what source path will implement bounded AHB two-subordinate interconnect?"
  - "does the AHB two-subordinate contract include .ahb alias support?"
  - "how should AHB multi-subordinate wiring be represented?"
date: 2026-06-29
status: current
tags: [ial2, ahb, interconnect, decode, contract, task-tree]
evidence: docs/IAL2_AHB_TWO_SUBORDINATE_CONTRACT_SELECTION.md; docs/IAL2_AHB_MULTI_SUBORDINATE_DECODE_READINESS_AUDIT.md; docs/IAL2_AHB_INTERCONNECT_DECODE_BEHAVIOR.md; docs/IAL2_AHB_INTERCONNECT_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_interconnect.ppif; ppif/ahb_interconnect.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1478-ial2-ahb-interconnect.t; t/1479-ial2-ahb-interconnect-profile-alias.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.729|IAL2-FEATURE-COMPLETENESS-FRONTIER\.730|ppif/ahb_interconnect_two_subordinate\.ppif|intent\.ppif_ahb_interconnect_two_subordinate|ial2_ppif_ahb_interconnect_two_subordinate_pipeline_cli|one_requester_two_subordinate_static_window_interconnect|ahb_broader_interconnect_decode_deferred|t/1480-ial2-ahb-interconnect-two-subordinate\.t' docs/IAL2_AHB_TWO_SUBORDINATE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.729` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.730`, direct implementation of the first
bounded public generic `.ppif` AHB two-subordinate interconnect/decode source:
`ppif/ahb_interconnect_two_subordinate.ppif`.

The selected contract is exactly one requester, exactly two subordinate
objects, one interconnect object, two subordinate child bindings, and two
non-overlapping static address-map windows. Per-subordinate select, local
address, ready-out, response, and read-data names come from each subordinate
object's bus block; the multi-source wiring block contains only requester and
global AHB bus names.

The matching `.ahb` profile alias is not selected for `.730`; it remains a
future exact selector after the generic `.ppif` behavior ships.
