---
id: ial2-apb-alternate-width-contract-selection
title: APB alternate-width contract selects 16-bit data and 2-bit PSTRB first
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.593?"
  - "did .593 change APB behavior?"
  - "what APB alternate width contract was selected?"
  - "what comes after APB alternate width contract selection?"
  - "what APB data width does .594 implement?"
date: 2026-06-27
status: current
tags: [ial2, apb, alternate-widths, pstrb, pprot, contract, task-tree]
evidence: docs/IAL2_APB_ALTERNATE_WIDTH_CONTRACT_SELECTION.md; docs/IAL2_APB_ALTERNATE_WIDTH_READINESS_AUDIT.md; docs/IAL2_APB_SIDEBAND_STROBE_BEHAVIOR.md; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.593|IAL2-FEATURE-COMPLETENESS-FRONTIER\.594|width 16|PSTRB width = data_width / 8|sideband_data16|apb_alternate_widths_deferred' docs/IAL2_APB_ALTERNATE_WIDTH_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.593` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.594`, direct bounded implementation of the
first APB alternate data/strobe width contract, without changing behavior.

The selected first implementation keeps address width at 32, address-map
base/size parameter widths at 32, completer `wait_cycles` at width 4, `PPROT`
at width 3, and requester status at width 2. It adds sideband-aware 16-bit APB
data variants where requester/completer/composition write/read/register data
widths are 16 and `PSTRB`/requester write-strobe width is derived as
`data_width / 8`, therefore width 2.

`.594` must add sideband-aware `data16` requester, multi-register completer,
fixed multi-register composition, and multi-peripheral composition `.ppif` and
`.apb` sample pairs, plus matching support identities, reports, diagnostics,
tests, docs, and Knowledge Map updates.

Selected 16-bit reports replace `apb_alternate_widths_deferred` with a
narrower residue for address widths, wait-count widths, and data widths beyond
the selected 16/32-bit boundary. `PPROT` access-control effects and
back-to-back transfer policy remain deferred.

`.593` changes no parser behavior, generator behavior, source samples,
support-accounting identities, report schemas, JSON behavior, generated
artifacts, HDL/runtime behavior, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.
