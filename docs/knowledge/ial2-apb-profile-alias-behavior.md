---
id: ial2-apb-profile-alias-behavior
title: .apb is the bounded APB requester-transfer IAL2 profile-alias suffix
answers:
  - "how does the .apb IAL2 profile alias behave?"
  - "can FSMGen accept .apb files now?"
  - "does FSMGen accept .apb now?"
  - "does APB PPIF accept .apb?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.554?"
  - "what support accounting entry covers the .apb alias?"
  - "what profile does .apb require?"
  - "does .apb lower directly to .fsm?"
date: 2026-06-26
status: current
tags: [ial2, apb, ppif, profile-alias, task-tree]
evidence: docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_APB_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md; ppif/apb_requester_transfer.apb; ppif/apb_requester_transfer.ppif; bin/fsmgen; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/Support/LanguageSurfaceSection.pm; perl/FSM/Support/RegressionCorpus.pm; t/1470-ial2-apb-profile-alias.t; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/13-intent-scheduling.md
reverify: prove -Iperl t/1470-ial2-apb-profile-alias.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`.apb` is the bounded APB requester-transfer IAL2 profile-alias suffix. It
accepts the selected APB source at `ppif/apb_requester_transfer.apb`, requires
explicit `(profile apb)`, and supports exactly one
`(apb-requester apb_requester ...)` object in this first alias slice.

The alias lowers through generated `apb_requester.isf` before generated
`apb_requester.fsm`; direct IAL2-to-IAL0 lowering remains forbidden. The
generated HDL module is `apb_requester`, and the report schema remains
`fsmgen.ial2.protocol_intent.apb_requester_transfer.v1`.

The alias is support-accounted as
`intent.apb_profile_alias_requester_transfer` with coverage
`ial2_apb_profile_alias_requester_transfer_pipeline_cli` and `source_kind`
`ial2_profile_alias`.

`.chi`, `.ace`, `.ahb`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi` remain
unsupported aliases. APB completer/interconnect generation, sidebands,
alternate widths, multi-peripheral decode, back-to-back policy, direct backend
lowering, verification-output generation, backend-language variants, and VHDL
remain deferred.
