---
id: ial2-ahb-interconnect-profile-alias-behavior
title: AHB interconnect .ahb now ships as the aggregate profile alias
answers:
  - "does FSMGen ship ppif/ahb_interconnect.ahb?"
  - "how does the aggregate AHB .ahb profile alias behave?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.726 implement?"
  - "what support accounting identifies AHB interconnect .ahb?"
  - "does aggregate AHB .ahb remove ahb_aggregate_profile_alias_deferred?"
date: 2026-06-29
status: current
tags: [ial2, ahb, interconnect, decode, profile-alias, behavior]
evidence: docs/IAL2_AHB_INTERCONNECT_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_INTERCONNECT_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_AHB_INTERCONNECT_DECODE_BEHAVIOR.md; ppif/ahb_interconnect.ahb; ppif/ahb_interconnect.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1479-ial2-ahb-interconnect-profile-alias.t; t/1478-ial2-ahb-interconnect.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: >-
  prove -Iperl t/1479-ial2-ahb-interconnect-profile-alias.t && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ahb && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect.ahb && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect.ahb && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.726|ppif/ahb_interconnect\.ahb|intent\.ahb_profile_alias_interconnect|ial2_ahb_profile_alias_interconnect_pipeline_cli|source_kind.*ial2_profile_alias|ahb_aggregate_profile_alias_deferred|ahb_tb\.fsm|fsmgen\.ial2\.protocol_intent\.ahb_interconnect\.v1' docs/IAL2_AHB_INTERCONNECT_PROFILE_ALIAS_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md
  ppif/ahb_interconnect.ahb
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.726` implements
`ppif/ahb_interconnect.ahb` as the selected bounded public aggregate AHB
profile alias.

The alias mirrors `ppif/ahb_interconnect.ppif`: explicit `(profile ahb)`,
one requester object, one subordinate object, and one interconnect object. It
lowers through generated `amba_requester.isf`,
`ahb_lite_subordinate.isf`, and `ahb_interconnect.isf` before generated
`amba_requester.fsm`, `ahb_lite_subordinate.fsm`,
`ahb_interconnect.fsm`, and aggregate `ahb_tb.fsm`, then emits HDL module
`ahb_tb`.

Support accounting identifies the alias as
`intent.ahb_profile_alias_interconnect` with source kind
`ial2_profile_alias`, coverage
`ial2_ahb_profile_alias_interconnect_pipeline_cli`, report schema
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, and semantic root kind
`top`.

The aggregate `.ahb` report removes `ahb_aggregate_profile_alias_deferred`
while preserving broader AHB residue for multi-subordinate decode, optional
signals, burst `SEQ`, direct backend, and verification-output/backend
variants.
