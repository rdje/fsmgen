---
id: ial2-apb-multi-peripheral-interconnect-contract-selection
title: APB multi-peripheral interconnect/decode contract selects composition widening
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.584 select?"
  - "what is the APB multi-peripheral interconnect source syntax?"
  - "does APB multi-peripheral use apb-composition or apb-interconnect?"
  - "how are APB peripherals listed in the multi-peripheral contract?"
  - "how are APB address-map windows specified?"
  - "how is APB interconnect topology parameterized?"
  - "does the APB interconnect lower into a generated IAL1 artifact?"
  - "what is apb_interconnect.isf?"
  - "what is the selected APB response mux policy?"
  - "what diagnostics must APB multi-peripheral implementation add?"
  - "what samples will APB multi-peripheral implementation add?"
  - "does .584 change APB behavior?"
  - "what comes after APB multi-peripheral contract selection?"
date: 2026-06-27
status: current
tags: [ial2, ial1, apb, interconnect, multi-peripheral, decode, contract, task-tree]
evidence: docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_CONTRACT_SELECTION.md; docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_READINESS_AUDIT.md; docs/IAL2_APB_MULTI_REGISTER_DECODE_BEHAVIOR.md; docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; ppif/apb_composition_multi_register.ppif; ppif/apb_composition_status.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1471-ial2-apb-completer.t; t/1472-ial2-apb-composition.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.584|IAL2-FEATURE-COMPLETENESS-FRONTIER\.585|apb_composition_multi_peripheral|apb_interconnect\.isf|\(peripheral status apb_status_regs\)|\(address-map apb_decode|overlap reject|unmapped-address error' docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.584` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.585`, direct bounded implementation of APB
multi-peripheral interconnect/decode for generated APB composition sources.

The selected source remains `(apb-composition ...)`; no top-level
`(apb-interconnect ...)` IAL2 object is selected. The multi-peripheral form
adds repeated `(peripheral INSTANCE OBJECT)` child entries, an
`(address-map ...)` block with static parameter/generic-like `base` and `size`
bindings, and a `(decode ...)` block selecting `overlap reject`,
`priority source-order`, and `unmapped-address error`.

Lowering must generate a reusable APB-specific IAL1 review artifact named
`apb_interconnect.isf` before generated IAL0 `apb_interconnect.fsm` and the
generated composition top `apb_tb.fsm`.

The selected response mux forwards requester-side `PREADY`, `PRDATA`, and
`PSLVERR` from the selected peripheral. If requester `PSEL && PENABLE` is
active and no address window matches, the mux returns `PREADY=1`, `PRDATA=0`,
and `PSLVERR=1`.

`.585` must add `ppif/apb_composition_multi_peripheral.ppif` and
`ppif/apb_composition_multi_peripheral.apb`, support identities
`intent.ppif_apb_composition_multi_peripheral` and
`intent.apb_profile_alias_composition_multi_peripheral`, focused diagnostics,
focused APB tests, docs, mdBook, Memory, and Knowledge Map updates.

`.584` changes no parser behavior, generator behavior, source samples,
support-accounting, validation behavior, generated artifacts, JSON behavior,
HDL/runtime behavior, AXI behavior, APB behavior, AHB behavior, or VHDL
behavior.
