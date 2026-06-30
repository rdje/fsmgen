---
id: ial2-ahb-two-subordinate-profile-alias-behavior
title: AHB two-subordinate profile alias behavior shipped
answers:
  - "does FSMGen accept ppif/ahb_interconnect_two_subordinate.ahb?"
  - "does AHB two-subordinate interconnect have an .ahb alias?"
  - "what support accounting identifies the AHB two-subordinate .ahb alias?"
  - "does the AHB two-subordinate .ahb alias remove aggregate profile residue?"
date: 2026-06-30
status: current
tags: [ial2, ahb, interconnect, decode, profile-alias, behavior]
evidence: docs/IAL2_AHB_TWO_SUBORDINATE_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_interconnect_two_subordinate.ahb; ppif/ahb_interconnect_two_subordinate.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1481-ial2-ahb-interconnect-two-subordinate-profile-alias.t; t/1480-ial2-ahb-interconnect-two-subordinate.t; t/1479-ial2-ahb-interconnect-profile-alias.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: prove -Iperl t/1481-ial2-ahb-interconnect-two-subordinate-profile-alias.t && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate.ahb && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate.ahb && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.732|ppif/ahb_interconnect_two_subordinate\.ahb|intent\.ahb_profile_alias_interconnect_two_subordinate|ial2_ahb_profile_alias_interconnect_two_subordinate_pipeline_cli|one_requester_two_subordinate_static_window_interconnect|ahb_aggregate_profile_alias_deferred' docs/IAL2_AHB_TWO_SUBORDINATE_PROFILE_ALIAS_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.732` ships
`ppif/ahb_interconnect_two_subordinate.ahb` as the matching bounded public AHB
two-subordinate profile alias over
`ppif/ahb_interconnect_two_subordinate.ppif`.

The alias lowers through generated `amba_requester.isf`,
`ahb_status_subordinate.isf`, `ahb_control_subordinate.isf`, and
`ahb_interconnect.isf` before generated `amba_requester.fsm`,
`ahb_status_subordinate.fsm`, `ahb_control_subordinate.fsm`,
`ahb_interconnect.fsm`, and aggregate `ahb_tb.fsm`, then emits HDL module
`ahb_tb`.

Support accounting is
`intent.ahb_profile_alias_interconnect_two_subordinate`, source kind
`ial2_profile_alias`, and coverage
`ial2_ahb_profile_alias_interconnect_two_subordinate_pipeline_cli`. The report
schema is `fsmgen.ial2.protocol_intent.ahb_interconnect.v1` and topology is
`one_requester_two_subordinate_static_window_interconnect`.

The alias report removes `ahb_aggregate_profile_alias_deferred`; the generic
two-subordinate `.ppif` report keeps that residue as a source-surface
distinction. Broader AHB interconnect/decode behavior remains deferred.
