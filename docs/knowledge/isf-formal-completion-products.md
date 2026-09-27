---
id: isf-formal-completion-products
title: Parent completion products retain actual instance allocation and join views
answers:
  - "what does parent_completion_products include in source preparation?"
  - "how are completion seen and ready names owned before formal allocation?"
  - "can a completion helper change its physical spelling after formal projection?"
date: 2026-09-27
status: current
tags: [isf, formals, reservations, completion, children, scope]
evidence: perl/FSM/Scheduler/ISF/ChildCompletion.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1946-isf-formal-completion-products.t; t/1908-isf-generated-child-completion-memory.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1946-isf-formal-completion-products.t t/1908-isf-generated-child-completion-memory.t
---

ChildCompletion's real producer returns its pre-allocation input_names and
instances keyed by generated activation instance, with explicit typed identity,
start_signal, done_signal, seen_signal and ready_signal. Executable parents retain
this private metadata without changing the public schedule. No consumer derives
ownership by stripping a helper prefix.

Source preparation runs that producer on cloned point-resolved states and
registered activations, with declaration membership assembled from actor storage,
constants/parameters/system names, final wiring ports, retained direct transaction
products, activation and point products, potential resource declarations and
actor-network handoffs. Membership booleans are not executable widths. Only fresh
producer outputs populate returned counters, signal_widths, storage_roles,
reset_values, dt_blocks and explicit_internal_signals. No conflicting raw
width/role maps are merged; no parent is finalized or emitted. Source admission
and final executable collision/resource checks remain mandatory.

T1946 compares actual allocation inputs, ownership, declarations, completion
assignments and rewritten joins before and after detached formal projection.
It qualifies dynamic-wait guards, exact/case-folded fixed and formal collisions,
static/storage/point/arbitration namespace inputs, permutation and mutation
isolation, raw width conflicts, absent/pruned joins and strict parent carriers.
If an uppercase formal ISF_COMPLETION_SECOND_READY moves to a private name,
the real helper can move from isf_completion_second_ready_completion to
isf_completion_second_ready. The source inventory reserves the latter under the
allocator's case-insensitive comparison, even though exact spelling is absent.
This qualified example is not a general proof of reservation closure.

Completion retention semantics remain owned by
[generated-child-completion-memory](generated-child-completion-memory.md).
This slice adds no new HDL runtime qualification. Grant/priority processing,
parent storage/named-completion connections and final domain composition remain
separate coverage gates. Reusable library and resolved ATL children now have
[retained products](isf-formal-reusable-products.md); production formal renaming
remains gated.
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.1.
