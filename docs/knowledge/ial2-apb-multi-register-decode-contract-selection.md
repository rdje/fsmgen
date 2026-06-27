---
id: ial2-apb-multi-register-decode-contract-selection
title: APB multi-register contract selects repeated register clauses
answers:
  - "what is the selected APB multi-register source syntax?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.580 select?"
  - "how will APB multi-register reports look?"
  - "does .580 change APB behavior?"
date: 2026-06-27
status: current
tags: [ial2, apb, completer, composition, multi-register, contract, task-tree]
evidence: docs/IAL2_APB_MULTI_REGISTER_DECODE_CONTRACT_SELECTION.md; docs/IAL2_APB_MULTI_REGISTER_DECODE_READINESS_AUDIT.md; docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md; docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md; ppif/apb_completer.ppif; ppif/apb_composition_status.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; t/1471-ial2-apb-completer.t; t/1472-ial2-apb-composition.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.580|IAL2-FEATURE-COMPLETENESS-FRONTIER\.581|apb_completer_multi_register|apb_composition_multi_register|bindings.storage.registers|transfer.registers|repeated.*register' docs/IAL2_APB_MULTI_REGISTER_DECODE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.580` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.581`, direct bounded implementation of APB
multi-register completer decode for generated APB completer and
fixed-composition IAL2 surfaces.

The selected source syntax is repeated `(register ...)` clauses inside the
existing `(storage ...)` block. Register order is source order. Register
addresses must be unique, decimal, width 32, and 4-byte aligned. Register data
width remains 32 and reset remains 0 for the first multi-register slice.

Existing one-register reports remain unchanged with `bindings.storage.register`
and `transfer.register`. New multi-register reports use additive
`bindings.storage.registers[]` and `transfer.registers[]` lists in source
order, and remove `apb_multi_register_decode_deferred` only from the new
multi-register-capable reports.

`.580` changes no parser behavior, generator behavior, source samples,
support-accounting, validation behavior, generated artifacts, JSON schemas,
HDL/runtime behavior, direct backend lowering, verification-output generation,
backend-language variants, AXI behavior, APB behavior, or VHDL behavior.
