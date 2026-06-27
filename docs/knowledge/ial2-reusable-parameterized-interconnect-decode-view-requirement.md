---
id: ial2-reusable-parameterized-interconnect-decode-view-requirement
title: APB, AXI, and AHB interconnect decode should be audited for reusable parameterized views
answers:
  - "should APB interconnect decode be reusable?"
  - "should APB multi-peripheral decode lower into its own IAL2 or IAL1 view?"
  - "should APB interconnect topology be parameterized?"
  - "does AXI need the same reusable interconnect decode audit?"
  - "does AHB need the same reusable interconnect decode audit?"
  - "what user input must .583 consider?"
date: 2026-06-27
status: current
tags: [ial2, ial1, apb, axi, ahb, interconnect, decode, reusable-view, parameters, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'reusable.*IAL2|generated IAL1 review artifact|parameter/generic|AXI and AHB multi-peripheral|user input on reusable parameterized interconnect' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md MEMORY.md
---

User input during `IAL2-FEATURE-COMPLETENESS-FRONTIER.583` requires the APB
multi-peripheral interconnect/decode audit to evaluate a reusable lowered view,
not only one-off composition glue.

The audit must explicitly decide whether APB interconnect/decode should lower
into a reusable standalone IAL2 view or generated IAL1 review artifact, and how
its topology/address map should be configured at instantiation time through
parameter/generic-like bindings.

The audit must also decide whether AXI and AHB multi-peripheral
interconnect/decode can share the same abstraction, should mirror it with
protocol-specific reusable views, or should remain deferred behind separate
exact owners.
