---
id: ial2-axi-profile-alias-behavior
title: .axi is the first bounded IAL2 profile-alias suffix and remains an AXI example
answers:
  - "how does the .axi IAL2 profile alias behave?"
  - "can FSMGen accept .axi files now?"
  - "does FSMGen now accept .axi or .smbus files?"
  - "does .axi make IAL2 AXI-only?"
  - "what support accounting entry covers the .axi alias?"
  - "which IAL2 profile-alias suffixes remain unsupported after .axi?"
  - "does .axi lower directly to .fsm?"
  - "what profile does .axi require?"
date: 2026-06-26
status: current
tags: [ial2, profile-alias, axi, ppif, task-tree]
evidence: docs/IAL2_AXI_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_FIRST_PROFILE_ALIAS_CONTRACT_SELECTION.md; ppif/axi_aw_valid_ready.axi; ppif/axi_aw_valid_ready.ppif; bin/fsmgen; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/LanguageSurfaceSection.pm; perl/FSM/Support/RegressionCorpus.pm; t/1469-ial2-axi-profile-alias.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: prove -Iperl t/1469-ial2-axi-profile-alias.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`.axi` is the first bounded IAL2 profile-alias suffix. It accepts the selected
AXI AW Valid-Ready source at `ppif/axi_aw_valid_ready.axi`, requires an explicit
AXI-family `(profile axi)`, `(profile axi3)`, `(profile axi4)`, or
`(profile axi5)`, and lowers through generated `.isf` before generated `.fsm`.

The alias is support-accounted as `intent.axi_profile_alias_aw_valid_ready`
with coverage `ial2_axi_profile_alias_aw_valid_ready_pipeline_cli` and
`source_kind` `ial2_profile_alias`. `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`,
`.smbus`, `.i2s`, `.pif`, and `.ppi` remain unsupported. `.axi` is only the
first profile-alias example over IAL2; it does not make IAL2 AXI-only.
