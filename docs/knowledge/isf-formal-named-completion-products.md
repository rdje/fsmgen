---
id: isf-formal-named-completion-products
title: Named completion plans retain actual parent handoffs and local delayed pulses
answers:
  - "are named child completion declarations reserved before formal allocation?"
  - "what does parent_named_completion_products retain?"
  - "does planning named completion admit mixed parent writers?"
date: 2026-09-27
status: current
tags: [isf, formals, reservations, completion, children, ownership]
evidence: perl/FSM/Scheduler/ISF/ChildCompletionOutputs.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1953-isf-formal-named-completion-products.t; t/1913-isf-generated-child-named-completion.t
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl t/1953-isf-formal-named-completion-products.t t/1913-isf-generated-child-named-completion.t
---
Current integration: [production formal scope](isf-production-formal-scope.md)
now consumes the qualified preparation products. The producer-specific account
below records its original qualification boundary; pending global integration
statements are historical. Independent-controller and local-call execution
remain separately gated.


plan_child_completion_outputs shares actual parent declaration allocation with
detached source preparation after storage read/write handoffs. It retains
allocation input_names, explicit local completion width/type/reset contracts,
per-instance child input links, counters and widths/types/roles/resets,
explicit local pulse storage and output-view DTs. Each output has a typed
actor_completion_output identity, ordered pulse sources and its actual view DT.

Executable connection checks all local writers against complete_pulse and the
original delayed-pulse operator before invoking the plan. It then installs
those products and redirects the same local completion assignment objects to
the allocated pulse. Allocation order remains child inputs, then local pulse
and view per sorted output; no pulse stage or cycle is added.

Source preparation gathers potential local completions from actual retained
parent blocks and authored actor output contracts without merging unallocated
formal width/role maps. It retains detached parent_named_completion_products;
those potential products do not grant executable writer admission or finalize
a fabricated parent. Canonical child done and explicit local completion ports
do not invent automatic actor-output routing.

T1953 observes real production planning and installed products, compares
complete source/physical plans and tests shared/child-only, typed, literal reset,
multiple-instance and local-shadow/canonical cases. Portable formal/fixed/rule
helper collisions retain reservation coverage after projection. Caller/source,
child and preceding read products remain detached. Mixed non-completion writers
still fail executable admission. The full selected reader/completion/schedule
cohort passes, including T1913 independent named pulse timing and complete
native/API/newline report qualification.

Library readback preserves declaration names, as qualified in
[isf-library-parent-port-ownership](isf-library-parent-port-ownership.md).
Outer domain realization remains a separate coverage gate before complete
reservations and automatic production formal rewriting.
Canonical event behavior remains in
[isf-generated-child-named-completion](isf-generated-child-named-completion.md).
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.1.
