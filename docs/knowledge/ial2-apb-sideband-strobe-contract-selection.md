---
id: ial2-apb-sideband-strobe-contract-selection
title: APB sideband and strobe contract selects PPROT/PSTRB implementation
answers:
  - "what is the APB sideband strobe source syntax?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.588?"
  - "what comes after APB sideband readiness?"
  - "does .588 change APB behavior?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.589?"
  - "how will APB PSTRB byte lanes work?"
date: 2026-06-27
status: current
tags: [ial2, apb, sideband, strobe, pprot, pstrb, byte-lane, contract, task-tree]
evidence: docs/IAL2_APB_SIDEBAND_STROBE_CONTRACT_SELECTION.md; docs/IAL2_APB_SIDEBAND_STROBE_READINESS_AUDIT.md; docs/IAL2_POST_APB_MULTI_PERIPHERAL_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_BEHAVIOR.md; docs/IAL2_APB_MULTI_REGISTER_DECODE_BEHAVIOR.md; docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1471-ial2-apb-completer.t; t/1472-ial2-apb-composition.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.588|IAL2-FEATURE-COMPLETENESS-FRONTIER\.589|write-strobe req_wstrb width 4|protection req_prot width 3|PSTRB\\[0\\]|apb_requester_transfer_sideband|apb_protection_policy_effects_deferred' docs/IAL2_APB_SIDEBAND_STROBE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.588` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.589`, direct bounded APB `PPROT`/`PSTRB`
sideband/strobe implementation, without changing behavior in `.588`.

The selected source syntax adds requester-side `(protection req_prot width 3)`
and `(write-strobe req_wstrb width 4)` fields, plus bus-side `(protection
PPROT width 3)` and `(strobe PSTRB width 4)` fields on requester, completer,
and composition bus/wiring blocks.

The selected byte-lane policy is fixed 32-bit APB: `PSTRB[0]` controls
`PWDATA[7:0]`, `PSTRB[1]` controls `PWDATA[15:8]`, `PSTRB[2]` controls
`PWDATA[23:16]`, and `PSTRB[3]` controls `PWDATA[31:24]`. `PPROT` is propagated
and sampled but access-control effects remain deferred.

`.588` changes no parser behavior, generator behavior, source samples,
support-accounting, validation behavior, generated artifacts, JSON behavior,
HDL/runtime behavior, direct backend lowering, verification-output generation,
backend-language variants, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior.
