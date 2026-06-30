---
id: ial2-ahb-two-subordinate-behavior
title: Generic PPIF AHB two-subordinate interconnect behavior shipped
answers:
  - "does FSMGen ship AHB two-subordinate interconnect behavior?"
  - "what does ppif/ahb_interconnect_two_subordinate.ppif generate?"
  - "what support accounting identifies the AHB two-subordinate PPIF?"
  - "does two-subordinate AHB interconnect have an .ahb alias?"
  - "what topology does the AHB two-subordinate report use?"
date: 2026-06-30
status: current
tags: [ial2, ahb, interconnect, decode, ppif, behavior]
evidence: docs/IAL2_AHB_TWO_SUBORDINATE_BEHAVIOR.md; docs/IAL2_AHB_TWO_SUBORDINATE_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_interconnect_two_subordinate.ppif; ppif/ahb_interconnect_two_subordinate.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1480-ial2-ahb-interconnect-two-subordinate.t; t/1481-ial2-ahb-interconnect-two-subordinate-profile-alias.t; t/1478-ial2-ahb-interconnect.t; t/1479-ial2-ahb-interconnect-profile-alias.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: prove -Iperl t/1480-ial2-ahb-interconnect-two-subordinate.t t/1481-ial2-ahb-interconnect-two-subordinate-profile-alias.t && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate.ahb
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.730` ships the bounded public generic
`.ppif` AHB two-subordinate interconnect/decode source
`ppif/ahb_interconnect_two_subordinate.ppif`.

The source contains one requester, two subordinate objects, two subordinate
child bindings, and two non-overlapping static windows: `status` at base 0 size
4 and `control` at base 4 size 4. It lowers through generated
`amba_requester.isf`, `ahb_status_subordinate.isf`,
`ahb_control_subordinate.isf`, and `ahb_interconnect.isf` before generated
`amba_requester.fsm`, `ahb_status_subordinate.fsm`,
`ahb_control_subordinate.fsm`, `ahb_interconnect.fsm`, and `ahb_tb.fsm`, then
emits HDL module `ahb_tb`.

Support accounting for the generic source is
`intent.ppif_ahb_interconnect_two_subordinate`, `source_kind ppif`, and
coverage `ial2_ppif_ahb_interconnect_two_subordinate_pipeline_cli`. The report
schema is `fsmgen.ial2.protocol_intent.ahb_interconnect.v1` and topology is
`one_requester_two_subordinate_static_window_interconnect`.

The matching `.ahb` alias now ships as
`ppif/ahb_interconnect_two_subordinate.ahb`, support-accounted as
`intent.ahb_profile_alias_interconnect_two_subordinate` with source kind
`ial2_profile_alias`.
