---
id: ial2-ahb-interconnect-decode-generated-substrate-audit
title: AHB interconnect generated substrate is ready for implementation
answers:
  - "is the AHB interconnect generated substrate ready?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.722 select?"
  - "does AHB interconnect need another substrate repair before implementation?"
  - "what comes after the AHB interconnect substrate audit?"
  - "which task owns AHB interconnect implementation?"
date: 2026-06-29
status: current
tags: [ial2, ahb, interconnect, decode, generated-ial1, generated-ial0, substrate-audit, task-tree]
evidence: docs/IAL2_AHB_INTERCONNECT_DECODE_GENERATED_SUBSTRATE_AUDIT.md; docs/IAL2_AHB_INTERCONNECT_DECODE_CONTRACT_SELECTION.md; docs/IAL2_AHB_INTERCONNECT_DECODE_READINESS_AUDIT.md; docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_BEHAVIOR.md; ppif/apb_composition_multi_peripheral.ppif; ppif/ahb_requester.ppif; ppif/ahb_lite_subordinate.ppif; fsm/amba_requester.fsm; fsm/ahb_lite_subordinate.fsm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.722|IAL2-FEATURE-COMPLETENESS-FRONTIER\.723|AHB interconnect/decode generated substrate|ppif/ahb_interconnect\.ppif|apb_interconnect\.isf|ahb_interconnect\.isf|two-cycle unmapped ERROR' docs/IAL2_AHB_INTERCONNECT_DECODE_GENERATED_SUBSTRATE_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.722` finds the generated
IAL1/IAL0/SystemVerilog substrate ready for the selected bounded AHB
interconnect/decode implementation and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.723` as direct implementation owner.

No lower-layer repair is required first. APB generated-interconnect precedent
already proves generated `.isf`/`.fsm` interconnect artifacts, static hit
comparisons, local address subtraction, decoded select fanout, response muxing,
ready muxing, unmapped error response, and aggregate top wiring. Current AHB
endpoint generation proves requester/subordinate artifacts, output
reset/default metadata, one-bit and two-bit response fields, and a stateful
two-cycle ERROR pattern.

`.723` must still implement parser/generator/source/support-accounting behavior
for `ppif/ahb_interconnect.ppif`; aggregate `.ahb` alias behavior,
multi-subordinate fabrics, optional signals, burst `SEQ`, byte-lane/narrow
transfers, direct backend, verification-output generation, AXI, APB behavior,
and VHDL remain deferred.
