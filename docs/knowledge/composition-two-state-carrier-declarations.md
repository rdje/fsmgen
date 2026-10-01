---
id: composition-two-state-carrier-declarations
title: Two-state composition carriers preserve their types on variable declarations
answers:
  - "how are mixed-state aggregate composition carriers declared?"
  - "does repairing two-state composition wires widen their state models?"
  - "how is the generated mixed-state typed-net declaration repair qualified?"
date: 2026-10-01
status: current
tags: [composition, backend, types, state-model, verification]
evidence: perl/FSM/Backend/VerilogFamily/TypeDeclarationSupport.pm; perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm; perl/FSM/Composition/LinkedPlanBuilder.pm; t/2026-structural-two-state-carrier-declarations.t; t/167-structural-connection-expr-helpers.t; docs/audits/typed-composition-carrier-repair-20261001/manifest.json; docs/audits/record-input-generated-observation-20261001/manifest.json; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/2026-structural-two-state-carrier-declarations.t t/167-structural-connection-expr-helpers.t
---

SEM .60.4.3.2.5.4.3.2 repairs the declared carrier class exposed by the actual
first generated-input compile rejection. The shared type renderer detects
explicit two_state scalar leaves recursively across ordered record members
and list items. Structural emission uses the same aggregate typedef as a
variable for those carriers, preserving every signed/state/layout declaration.
All-four-state typed wires and existing typed variable carriers remain.
Explicit scalar two_state wire metadata similarly renders bit variables with
its existing width/signedness; this statement covers that actual metadata path.
The supported planner reserves each target's driver and allocates each carrier
by one stable source-family key, adding fanout targets. This declaration
selection preserves its existing connectivity and owning register contracts.

Independent T2026 literals cover nested record/list and all-two/all-four state
declarations, explicit scalar/legacy nets, both families and complete caller
JSON. Actual public strict emission of the unchanged failing source matches the
sealed full predecessor HDL except the illegal carrier wire keyword and date.
Preloading the exact committed old emitter from a plain local include tree
makes both independent declaration and full public-product subtests RED.
Structural, typed, shared, generated/carrier and JSON regression passes.
Full saved positive/RED receipts and immutable source identities are retained
in docs/audits/typed-composition-carrier-repair-20261001/; its saved verifier
rejects unrelated/weakened receipts and executes no HDL.

Actual literal declarations and complete emitted products re-derive the repair.
Exact old-emitter RED and hostile receipt substitutions provide distinct
falsification. Tracked producers/tests, original compiler failure, sealed repair
records, fact/book/tasks and Git provide durability. No additional HDL compiles
or runs in this repair slice. Corrected genuine compiler/runtime and executed
P1 closure remain .5.4.3.3 after commit with fresh exact current identities.
X/Z, reset-free initialization and historical native causality remain unproved.
