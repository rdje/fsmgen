---
id: ial2-apb-sideband-data16-behavior
title: APB sideband data16 behavior ships 16-bit data and 2-bit PSTRB
answers:
  - "does APB support 16-bit data now?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.594?"
  - "how does APB data16 PSTRB width work?"
  - "what APB data16 samples are supported?"
  - "what APB widths remain deferred after data16?"
date: 2026-06-27
status: current
tags: [ial2, apb, alternate-widths, data16, pstrb, sideband, behavior, task-tree]
evidence: docs/IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR.md; docs/IAL2_APB_ALTERNATE_WIDTH_CONTRACT_SELECTION.md; ppif/apb_requester_transfer_sideband_data16.ppif; ppif/apb_requester_transfer_sideband_data16.apb; ppif/apb_completer_multi_register_sideband_data16.ppif; ppif/apb_completer_multi_register_sideband_data16.apb; ppif/apb_composition_multi_register_sideband_data16.ppif; ppif/apb_composition_multi_register_sideband_data16.apb; ppif/apb_composition_multi_peripheral_sideband_data16.ppif; ppif/apb_composition_multi_peripheral_sideband_data16.apb; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1471-ial2-apb-completer.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_sideband_data16.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register_sideband_data16.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_register_sideband_data16.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral_sideband_data16.ppif && prove -Iperl t/1470-ial2-apb-profile-alias.t t/1471-ial2-apb-completer.t t/1472-ial2-apb-composition.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.594` ships the selected APB
sideband-aware data16 behavior for requester-transfer, multi-register
completer, fixed multi-register composition, and multi-peripheral composition
`.ppif` and `.apb` samples.

The selected data16 APB variants keep address width 32, address-map parameter
width 32, wait-count width 4, `PPROT` width 3, and requester status width 2.
They use 16-bit write/read/register data and derive `PSTRB` or requester
write-strobe width as `data_width / 8`, therefore width 2. Register addresses
and address-map windows align to the selected 2-byte data beat.

Existing 32-bit APB behavior is preserved. Data16 reports add `width_policy`
metadata and use `apb_remaining_widths_deferred` instead of
`apb_alternate_widths_deferred`. `PPROT` access-control effects,
back-to-back policy, APB address widths other than 32, wait-count widths other
than 4, and data widths beyond the selected sideband-aware 16/32-bit boundary
remain deferred.
