---
id: ial2-apb-data16-pprot-effects-contract-selection
title: APB data16 PPROT policy contract selects sideband_data16_protection
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.602?"
  - "what APB data16 PPROT policy contract was selected?"
  - "what APB data16 PPROT policy samples are selected?"
  - "what task implements APB data16 PPROT policy effects?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.603?"
date: 2026-06-27
status: current
tags: [ial2, apb, pprot, protection, data16, contract, task-tree]
evidence: docs/IAL2_APB_DATA16_PPROT_EFFECTS_CONTRACT_SELECTION.md; docs/IAL2_APB_DATA16_PPROT_EFFECTS_READINESS_AUDIT.md; docs/IAL2_APB_PPROT_EFFECTS_BEHAVIOR.md; docs/IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Adapter/IAL2/PPIF.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.602|IAL2-FEATURE-COMPLETENESS-FRONTIER\.603|sideband_data16_protection|apb_completer_multi_register_sideband_data16_protection|apb_additional_protection_policies_deferred|apb_remaining_widths_deferred' docs/IAL2_APB_DATA16_PPROT_EFFECTS_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.602` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.603`, direct bounded implementation of
sideband data16 APB `PPROT` policy effects.

The selected suffix is `sideband_data16_protection`. The selected sample pairs
are data16 protection completer, fixed composition, and multi-peripheral
composition `.ppif`/`.apb` sources.

The contract reuses the shipped register-local `(access-policy ...)` syntax:
`(read|write allow)` or `(read|write require (privileged 0|1))`. The predicate
still means sampled `PPROT[0] == VALUE`.

Selected data16 protection behavior keeps 16-bit `PWDATA`/`PRDATA`/register
data, 2-bit `PSTRB`, two byte lanes, 32-bit addresses, and 4-bit wait counts.
Denied reads return 16-bit zero data with `PSLVERR=1`; denied writes are
side-effect-free and remain errors even when `PSTRB=0`.

`.602` changes no parser, generator, sample, support-catalog, validation,
generated-artifact, report-schema, JSON, HDL/runtime, APB, AXI, AHB, backend,
verification-output, backend-language, or VHDL behavior.
