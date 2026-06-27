---
id: ial2-apb-sideband-strobe-readiness-audit
title: APB sideband and strobe readiness selects contract selection
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.587?"
  - "what comes after APB sideband readiness?"
  - "are APB PPROT and PSTRB supported?"
  - "does .587 change APB behavior?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.588?"
date: 2026-06-27
status: current
tags: [ial2, apb, sideband, strobe, pprot, pstrb, byte-lane, audit, task-tree]
evidence: docs/IAL2_APB_SIDEBAND_STROBE_READINESS_AUDIT.md; docs/IAL2_POST_APB_MULTI_PERIPHERAL_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_CONTRACT_SELECTION.md; docs/IAL2_APB_MULTI_REGISTER_DECODE_BEHAVIOR.md; docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; ppif/apb_composition_multi_peripheral.ppif; ppif/apb_composition_status.ppif; ppif/apb_completer_multi_register.ppif; ppif/apb_requester_transfer_status.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1401-isf-bit-ops.t; t/1403-isf-set-field.t; t/1470-ial2-apb-profile-alias.t; t/1471-ial2-apb-completer.t; t/1472-ial2-apb-composition.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_status.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_status.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.587|IAL2-FEATURE-COMPLETENESS-FRONTIER\.588|apb_protection_and_strobes_deferred|PPROT|PSTRB|unsupported clause.*strobe|unsupported clause.*protection' docs/IAL2_APB_SIDEBAND_STROBE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.587` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.588`, public APB sideband/strobe contract
selection, without changing APB behavior.

APB `PPROT` and `PSTRB` are not supported yet. Current APB `.ppif` and `.apb`
bus blocks accept only the core APB signals and reject unselected
`(strobe ...)` or `(protection ...)` clauses as unsupported. Reports still
carry `apb_protection_and_strobes_deferred`.

The audit finds contract selection is the right next owner because the
generated IAL1/IAL0 path already has fixed-width ports, bitwise operations,
shifts, concatenation, and masked field-update support, while public syntax,
byte-enable semantics, report migration, support-accounting identities, and
composition/interconnect propagation are not selected.

`.587` changes no parser behavior, generator behavior, source samples,
support-accounting, validation behavior, generated artifacts, JSON behavior,
HDL/runtime behavior, direct backend lowering, verification-output generation,
backend-language variants, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior.
