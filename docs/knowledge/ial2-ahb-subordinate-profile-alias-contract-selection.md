---
id: ial2-ahb-subordinate-profile-alias-contract-selection
title: AHB subordinate .ahb public profile-alias contract selects bounded implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.717 decide?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.718?"
  - "what is the AHB subordinate .ahb public profile-alias contract?"
  - "how should AHB subordinate .ahb be support-accounted?"
  - "what path is selected for the AHB subordinate .ahb alias?"
date: 2026-06-29
status: current
tags: [ial2, ahb, subordinate, profile-alias, ppif, task-tree]
evidence: >-
  docs/IAL2_AHB_SUBORDINATE_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_POST_AHB_SUBORDINATE_PPIF_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_SUBORDINATE_PPIF_BEHAVIOR.md; docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_SUBORDINATE_PUBLIC_CONTRACT_SELECTION.md; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md; ppif/ahb_lite_subordinate.ppif; ppif/ahb_requester.ahb; bin/fsmgen; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1474-ial2-ahb-profile-alias.t; t/1475-ial2-ahb-subordinate.t; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md;
  ROADMAP_V2.md
reverify: ./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ahb && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.717|IAL2-FEATURE-COMPLETENESS-FRONTIER\.718|ppif/ahb_lite_subordinate\.ahb|intent\.ahb_profile_alias_subordinate|ial2_ahb_profile_alias_subordinate_pipeline_cli|source_kind.*ial2_profile_alias' docs/IAL2_AHB_SUBORDINATE_PROFILE_ALIAS_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.717` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.718`, bounded implementation of public
AHB subordinate `.ahb` profile-alias exposure.

The selected future alias path is `ppif/ahb_lite_subordinate.ahb`, mirroring
the shipped generic subordinate source `ppif/ahb_lite_subordinate.ppif`. The
source remains the same IAL2 `protocol-platform-intent` form, must keep
explicit `(profile ahb)`, and supports exactly one
`(ahb-subordinate ahb_lite_subordinate ...)` object.

The selected alias preserves generated `ahb_lite_subordinate.isf` before
generated `ahb_lite_subordinate.fsm`, report schema
`fsmgen.ial2.protocol_intent.ahb_subordinate.v1`, and HDL module
`ahb_lite_subordinate`.

The selected support-accounting identity is
`intent.ahb_profile_alias_subordinate`, coverage key
`ial2_ahb_profile_alias_subordinate_pipeline_cli`, and source kind
`ial2_profile_alias`.

At the end of `.717`, FSMGen still does not accept subordinate `.ahb`; `.718`
owns the implementation. AHB interconnect/decode, optional signals, burst
`SEQ`, byte-lane/narrow-transfer behavior, legacy two-bit `HRESP`, direct
backend behavior, verification-output generation, backend-language variants,
AXI, APB, and VHDL remain future owners.
