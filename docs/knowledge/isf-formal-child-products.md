---
id: isf-formal-child-products
title: Independently built generated children supply actual module reservation products
answers:
  - "are generated child activation and storage helper names retained before formal allocation?"
  - "what does generated_child_products include in source preparation?"
  - "can real child products be collected while raw parent formal declarations conflict?"
date: 2026-09-27
status: current
tags: [isf, formals, reservations, children, storage, completion, scope]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1945-isf-formal-child-products.t; t/1934-isf-generated-pin-shadow.t; t/1917-isf-generated-child-scalar-writes.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1945-isf-formal-child-products.t t/1936-isf-formal-source-context.t t/1938-isf-formal-parent-products.t
---
Current integration: [production formal scope](isf-production-formal-scope.md)
now consumes the qualified preparation products. The producer-specific account
below records its original qualification boundary; pending global integration
statements are historical. Independent-controller and local-call execution
remain separately gated.


Generated transaction children are independently built before the parent IR.
Transaction-only child products omit names later created for activation history,
write interfaces, synthetic entry and named-point active signals. Preparation
now shares the real _build_generated_transaction_children loop with build_module
and retains generated_child_products keyed by child module. It passes a separate
actor clone and detaches the returned products, so producer edits cannot reach
the authored/prepared source or earlier transaction products.

The canonical child builder retains its own scope, storage read/write selection,
named completion handling, point resolution, activation guards and semantic
finalization. It requires no conflicting parent formal-width/role merge.
Statically pruned children are not built. This is actual child IR, not a fabricated
parent or a bypass of child validation; full parent/backend and composition
validation remain mandatory before treating the actor as executable.

T1945 compares complete production children across spawn, generated do and trigger,
physical parent projection, reused definitions and actual domain scopes. Exact
and case-folded public-port collisions exercise real helper allocation without
guessing suffixes. Strict child carriers and source/product mutation controls
pass. The complete source/context/pin-shadow/storage-read/scalar-write/schedule
cohort passes, and the native schedule is byte-identical across the builder
extraction. These checks do not add Darwin HDL runtime qualification.
Raw parent conflicts, unknown child anchors, unsupported bank writes and
pruned-body controls retain their existing boundaries. A set-bit negative-control
assumption was corrected by inspecting normalized source: it is a whole-word
read/modify/write and uses the qualified full-width handoff, not a partial LHS.

Reusable library and resolved ATL children now have [separate retained products](isf-formal-reusable-products.md).
[Arbitration/finalization declaration preservation](isf-formal-arbitration-namespace.md)
is also qualified. Parent connection names and outer domain realization still
need separate coverage before complete
reservations or automatic production renaming can be claimed. This adds no new
controller or storage runtime qualification. See the [scope contract](isf-direct-transaction-port-scope.md).
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.1.
