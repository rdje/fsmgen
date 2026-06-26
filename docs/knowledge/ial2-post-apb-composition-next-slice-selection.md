---
id: ial2-post-apb-composition-next-slice-selection
title: APB alias contract selection follows shipped APB composition PPIF
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.567 select?"
  - "what comes after APB composition .ppif support?"
  - "is APB completer .apb alias exposure next after composition?"
  - "is APB composition .apb alias exposure next?"
  - "which APB residue is next after .566?"
date: 2026-06-26
status: current
tags: [ial2, apb, profile-alias, ppif, composition, task-tree]
evidence: docs/IAL2_POST_APB_COMPOSITION_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md; docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md; ppif/apb_composition.ppif; ppif/apb_composition.apb; ppif/apb_completer.ppif; ppif/apb_completer.apb; ppif/apb_requester_transfer.apb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.apb && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.567` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.568`, APB `.apb` profile-alias public
contract selection for the shipped APB completer and fixed
requester/completer composition shapes.

The selector chooses a contract-selection leaf rather than immediate behavior.
`.568` must decide exact `.apb` sample paths, support-accounting identities,
coverage names, diagnostics, source-kind behavior, check/semantic source-path
preservation, generated review-artifact preservation, validation, and rollback
before any parser or generator behavior changes.

At `.567` selection time, `ppif/apb_requester_transfer.apb` was accepted while
APB completer and APB composition behavior were available through generic
`.ppif` only. `.569` later implements the selected alias widening through
`ppif/apb_completer.apb` and `ppif/apb_composition.apb`.

Requester busy/status exposure, multi-peripheral interconnect/decode,
multi-register decode, sidebands/strobes, alternate widths, back-to-back
policy, direct backend lowering, verification-output generation,
backend-language variants, AXI, and VHDL remain future owners.
