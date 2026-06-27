---
id: ial2-post-apb-status-field-next-slice-selection
title: Post APB status-field selector chooses multi-register decode readiness
answers:
  - "what comes after APB requester status field?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.579?"
  - "why audit APB multi-register decode next?"
  - "does .578 change APB behavior?"
  - "what APB work remains deferred after status output?"
date: 2026-06-27
status: current
tags: [ial2, apb, completer, composition, multi-register, task-tree]
evidence: docs/IAL2_POST_APB_STATUS_FIELD_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_REQUESTER_STATUS_FIELD_BEHAVIOR.md; docs/IAL2_APB_REQUESTER_STATUS_FIELD_CONTRACT_SELECTION.md; docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md; docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md; ppif/apb_completer.ppif; ppif/apb_composition_status.ppif; fsm/apb_completer.fsm; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_status.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_status.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.578|IAL2-FEATURE-COMPLETENESS-FRONTIER\.579|apb_multi_register_decode_deferred|supports exactly one \(register|storage.register|address 0' docs/IAL2_POST_APB_STATUS_FIELD_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm fsm/apb_completer.fsm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.578` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.579`, a no-behavior APB multi-register
decode readiness audit.

The selector chooses multi-register decode because `.577` removed the APB
requester busy/status deferral residues from status-capable requester-transfer
and fixed-composition reports, while APB completer and composition reports
still expose `apb_multi_register_decode_deferred`. The current APB completer
surface is fixed to one address-0 storage register, so the next safe step is an
audit that decides whether the follow-on owner is public contract selection,
lower-layer/storage work, parser/report/static-validation readiness,
implementation, or explicit deferral.

`.578` changes no source syntax, parser acceptance, diagnostics, generator
logic, samples, support-accounting, validation behavior, generated artifacts,
JSON schemas, HDL/runtime behavior, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, APB
behavior, or VHDL behavior.

Status-only APB samples, enum/custom status encodings, sticky status registers,
multi-peripheral APB topology, sidebands/strobes, alternate APB widths,
back-to-back transfer policy, direct backend lowering, verification-output
generation, backend-language variants, AXI follow-on behavior, and VHDL remain
deferred.
