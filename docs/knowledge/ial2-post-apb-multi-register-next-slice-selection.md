---
id: ial2-post-apb-multi-register-next-slice-selection
title: APB multi-peripheral interconnect readiness follows multi-register decode
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.582?"
  - "what comes after APB multi-register decode?"
  - "why audit APB multi-peripheral interconnect next?"
  - "does .582 change APB behavior?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.583?"
date: 2026-06-27
status: current
tags: [ial2, apb, interconnect, multi-peripheral, decode, selector, task-tree]
evidence: docs/IAL2_POST_APB_MULTI_REGISTER_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_MULTI_REGISTER_DECODE_BEHAVIOR.md; docs/IAL2_APB_MULTI_REGISTER_DECODE_CONTRACT_SELECTION.md; docs/IAL2_APB_MULTI_REGISTER_DECODE_READINESS_AUDIT.md; docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md; docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md; ppif/apb_composition_multi_register.ppif; ppif/apb_composition_status.ppif; ppif/apb_completer_multi_register.ppif; ppif/apb_requester_transfer_status.ppif; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_register.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_status.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_status.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.582|IAL2-FEATURE-COMPLETENESS-FRONTIER\.583|apb_interconnect_multi_peripheral_decode_deferred|apb_multi_peripheral_decode_deferred|multi-peripheral interconnect' docs/IAL2_POST_APB_MULTI_REGISTER_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.582` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.583`, a no-behavior APB
multi-peripheral interconnect/decode readiness audit.

The selector follows `.581` because APB now has requester-transfer,
completer, fixed-composition, requester busy/status, and completer
multi-register behavior. Current schedule reports still expose
`apb_interconnect_multi_peripheral_decode_deferred` on completer/composition
surfaces and `apb_multi_peripheral_decode_deferred` on requester surfaces.

`.583` must audit source-shape, address-map, child/peripheral list, decode
priority, response muxing, diagnostics, report-schema, sample, support
accounting, validation, and preservation boundaries before any APB
multi-peripheral behavior can be selected.

`.582` changes no parser behavior, generator behavior, source samples,
support-accounting, validation behavior, generated artifacts, JSON behavior,
HDL/runtime behavior, direct backend lowering, verification-output generation,
backend-language variants, AXI behavior, APB behavior, or VHDL behavior.
