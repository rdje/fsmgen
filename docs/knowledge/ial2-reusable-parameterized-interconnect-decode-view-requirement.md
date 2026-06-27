---
id: ial2-reusable-parameterized-interconnect-decode-view-requirement
title: User input required protocol-specific reusable interconnect/decode audit
answers:
  - "what user input must .583 consider?"
  - "what reusable-view user input did .583 have?"
  - "what protocol-separation user input did .583 have?"
date: 2026-06-27
status: current
tags: [ial2, ial1, apb, axi, ahb, interconnect, decode, reusable-view, parameters, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md; docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_READINESS_AUDIT.md; docs/knowledge/ial2-apb-multi-peripheral-interconnect-readiness-audit.md
reverify: rg -n 'distinct protocols with distinct signal sets|cannot and may not share any multi-peripheral interconnect/decode logic|generated reusable IAL1|parameter/generic|IAL2-FEATURE-COMPLETENESS-FRONTIER\.584' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md MEMORY.md docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_READINESS_AUDIT.md docs/knowledge/ial2-apb-multi-peripheral-interconnect-readiness-audit.md
---

User input during `IAL2-FEATURE-COMPLETENESS-FRONTIER.583` requires the APB
multi-peripheral interconnect/decode audit to evaluate a reusable lowered view,
not only one-off composition glue.

The audit must explicitly decide whether APB interconnect/decode should lower
into a reusable standalone IAL2 view or generated IAL1 review artifact, and how
its topology/address map should be configured at instantiation time through
parameter/generic-like bindings.

The audit must also decide whether AXI and AHB multi-peripheral
interconnect/decode need their own protocol-specific reusable views or should
remain deferred behind separate exact owners. APB, AHB, and AXI are distinct
protocols with distinct signal sets and protocol contracts, so they cannot and
may not share any multi-peripheral interconnect/decode logic.

The `.583` outcome is recorded in
`docs/knowledge/ial2-apb-multi-peripheral-interconnect-readiness-audit.md`: it
selects APB-specific generated reusable IAL1 review lowering and advances to
`.584` public contract selection.
