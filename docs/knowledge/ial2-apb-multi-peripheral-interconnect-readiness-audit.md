---
id: ial2-apb-multi-peripheral-interconnect-readiness-audit
title: APB multi-peripheral interconnect/decode needs contract selection before behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.583 select?"
  - "is APB multi-peripheral interconnect implementation ready?"
  - "what comes after the APB multi-peripheral interconnect readiness audit?"
  - "should APB interconnect decode be reusable?"
  - "should APB multi-peripheral decode lower into its own IAL2 or IAL1 view?"
  - "should APB interconnect decode lower into IAL1 or standalone IAL2?"
  - "should APB interconnect topology be parameterized?"
  - "how should APB interconnect topology be configured?"
  - "does AXI need the same reusable interconnect decode audit?"
  - "does AHB need the same reusable interconnect decode audit?"
  - "should APB AXI and AHB share one interconnect decode logic block?"
  - "can APB AXI and AHB share multi-peripheral interconnect logic?"
  - "why can't APB AHB and AXI share interconnect decode logic?"
  - "do APB AHB and AXI share common signals?"
  - "does .583 change APB behavior?"
date: 2026-06-27
status: current
tags: [ial2, ial1, apb, interconnect, multi-peripheral, decode, reusable-view, task-tree]
evidence: >-
  docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_READINESS_AUDIT.md; docs/IAL2_POST_APB_MULTI_REGISTER_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_MULTI_REGISTER_DECODE_BEHAVIOR.md; docs/IAL2_APB_MULTI_REGISTER_DECODE_CONTRACT_SELECTION.md; docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md; docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md; docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; ppif/apb_composition_multi_register.ppif; ppif/apb_composition_status.ppif; ppif/apb_completer_multi_register.ppif; ppif/apb_requester_transfer_status.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm;
  perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_register.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_status.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_status.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.583|IAL2-FEATURE-COMPLETENESS-FRONTIER\.584|APB-specific generated reusable IAL1|generated reusable APB IAL1|APB, AXI, and AHB|different signal sets|apb_interconnect_multi_peripheral_decode_deferred|apb_multi_peripheral_decode_deferred' docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.583` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.584`, APB multi-peripheral
interconnect/decode public contract selection, before any behavior change.

Direct implementation is not ready because the current APB source/parser/
generator/report surface is still fixed to one requester, one completer, and
one composition object. It has no selected public contract for peripheral
lists, address maps, decode priority, response muxing, multi-peripheral
diagnostics, report fields, or sample/support/test scope.

The selected reusable-view direction is APB-specific IAL1 review generation:
IAL2 source should describe APB topology and address-map intent, including
parameter/generic-like instantiation bindings, and lowering should materialize
a generated reusable APB IAL1 review artifact before generated IAL0 `.fsm` and
HDL. `.583` does not select a standalone reusable IAL2 interconnect object.

AXI and AHB need separate future protocol-specific owners. APB, AXI, and AHB
have different signals and protocol contracts, so they cannot share
multi-peripheral interconnect/decode implementation logic.

`.583` changes no parser behavior, generator behavior, source samples,
support-accounting, validation behavior, generated artifacts, JSON behavior,
HDL/runtime behavior, AXI behavior, APB behavior, AHB behavior, or VHDL
behavior.
