---
id: ial2-ahb-subordinate-profile-alias-behavior
title: AHB subordinate .ahb public profile-alias behavior ships
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.718 ship?"
  - "does FSMGen support AHB subordinate .ahb files?"
  - "what is ppif/ahb_lite_subordinate.ahb?"
  - "how is the AHB subordinate .ahb alias support-accounted?"
  - "does subordinate .ahb remove ahb_subordinate_profile_alias_deferred?"
date: 2026-06-29
status: current
tags: [ial2, ahb, subordinate, profile-alias, ppif, task-tree]
evidence: docs/IAL2_AHB_SUBORDINATE_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_SUBORDINATE_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_AHB_SUBORDINATE_PPIF_BEHAVIOR.md; ppif/ahb_lite_subordinate.ahb; ppif/ahb_lite_subordinate.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1477-ial2-ahb-subordinate-profile-alias.t; t/1475-ial2-ahb-subordinate.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ahb && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate.ahb && prove -Iperl t/1477-ial2-ahb-subordinate-profile-alias.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.718` ships
`ppif/ahb_lite_subordinate.ahb` as the bounded public AHB subordinate `.ahb`
profile alias. It mirrors `ppif/ahb_lite_subordinate.ppif`, keeps explicit
`(profile ahb)`, supports exactly one
`(ahb-subordinate ahb_lite_subordinate ...)` object, and lowers through
generated `ahb_lite_subordinate.isf` before generated
`ahb_lite_subordinate.fsm`.

The alias preserves report schema
`fsmgen.ial2.protocol_intent.ahb_subordinate.v1`, HDL module
`ahb_lite_subordinate`, output reset/default metadata, and broader AHB
residue. It removes `ahb_subordinate_profile_alias_deferred` only from
subordinate `.ahb` reports; the generic subordinate `.ppif` report keeps that
historical residue.

The support-accounting identity is `intent.ahb_profile_alias_subordinate`,
coverage key `ial2_ahb_profile_alias_subordinate_pipeline_cli`, and source
kind `ial2_profile_alias`.
