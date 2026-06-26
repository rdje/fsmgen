---
id: ial2-apb-profile-alias-completer-composition-contract-selection
title: APB .apb alias widening contract selects completer and composition
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.568 select?"
  - "what comes after APB .apb completer/composition contract selection?"
  - "which .apb sample paths are selected for APB completer and composition?"
  - "what support-accounting entries will cover APB completer and composition .apb aliases?"
  - "does .568 change APB .apb behavior?"
date: 2026-06-26
status: current
tags: [ial2, apb, profile-alias, ppif, composition, task-tree]
evidence: docs/IAL2_APB_PROFILE_ALIAS_COMPLETER_COMPOSITION_CONTRACT_SELECTION.md; docs/IAL2_POST_APB_COMPOSITION_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md; docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; ppif/apb_composition.ppif; ppif/apb_completer.ppif; ppif/apb_requester_transfer.apb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.apb && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.568` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.569`, direct bounded implementation of APB
`.apb` profile-alias widening for the shipped APB completer and fixed
requester/completer composition shapes.

The selected future `.apb` sample paths are `ppif/apb_completer.apb` and
`ppif/apb_composition.apb`. Both mirror the existing generic `.ppif` sources,
keep explicit `(profile apb)`, preserve generated `.isf` and `.fsm` review
artifacts, and keep authored `.apb` paths in check JSON and semantic JSON.

The selected support-accounting identities are
`intent.apb_profile_alias_completer` and
`intent.apb_profile_alias_composition`, both with `source_kind`
`ial2_profile_alias`. The selected coverage names are
`ial2_apb_profile_alias_completer_pipeline_cli` and
`ial2_apb_profile_alias_composition_pipeline_cli`.

`.568` changes no behavior. At `.568` closeout, temporary `.apb` copies of the
APB completer and APB composition sources still fail closed with the current
requester-transfer-only alias diagnostic. Multi-peripheral APB interconnect,
multi-register decode, sidebands/strobes, alternate widths, requester
busy/status exposure, back-to-back policy, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, and
VHDL remain future owners.
