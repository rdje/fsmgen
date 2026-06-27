---
id: ial2-post-apb-multi-peripheral-next-slice-selection
title: APB sideband and strobe readiness follows multi-peripheral decode
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.586?"
  - "what comes after APB multi-peripheral interconnect decode?"
  - "why audit APB sidebands and strobes next?"
  - "does .586 change APB behavior?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.587?"
date: 2026-06-27
status: current
tags: [ial2, apb, sideband, strobe, byte-lane, selector, task-tree]
evidence: docs/IAL2_POST_APB_MULTI_PERIPHERAL_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_CONTRACT_SELECTION.md; docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_READINESS_AUDIT.md; docs/IAL2_APB_MULTI_REGISTER_DECODE_BEHAVIOR.md; docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; ppif/apb_composition_multi_peripheral.ppif; ppif/apb_composition_multi_peripheral.apb; ppif/apb_composition_status.ppif; ppif/apb_completer_multi_register.ppif; ppif/apb_requester_transfer_status.ppif; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_status.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_status.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.586|IAL2-FEATURE-COMPLETENESS-FRONTIER\.587|APB sidebands|strobes|byte-lane|PPROT|PSTRB' docs/IAL2_POST_APB_MULTI_PERIPHERAL_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/Support/LanguageSurfaceSection.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.586` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.587`, a no-behavior APB
sidebands/strobes/byte-lane readiness audit.

The selector follows `.585` because APB now has requester-transfer, completer,
multi-register completer decode, fixed composition, and multi-peripheral
composition topology behavior through `.ppif` and `.apb` sources. Live schedule
probes during `.586` must be read through `unsupported_residue`: top-level
multi-peripheral composition removes the top-level multi-peripheral decode
residue, but APB sideband/strobe, alternate-width, and back-to-back residues
remain explicit.

`.587` must audit whether APB sideband/strobe work should proceed through a
public source contract, a lower-layer generated-IAL1 or APB FSM prerequisite,
parser/static-validation/report readiness, an alternate-width prerequisite, or
explicit deferral.

`.586` changes no parser behavior, generator behavior, source samples,
support-accounting, validation behavior, generated artifacts, JSON behavior,
HDL/runtime behavior, direct backend lowering, verification-output generation,
backend-language variants, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior.
