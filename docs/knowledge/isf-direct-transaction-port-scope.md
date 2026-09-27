---
id: isf-direct-transaction-port-scope
title: Direct transaction formal identity plan and remaining scope integration
answers:
  - "can direct transaction ports share actor storage names?"
  - "why does a caller local port bind with the actor storage width?"
  - "do different direct transactions have independent same-named formal ports?"
  - "what must precede direct transaction port scope repair?"
  - "how are private direct formal identities planned without changing execution?"
  - "why do bit helpers use an actor width instead of a shadowing formal width?"
date: 2026-09-27
status: current
tags: [isf, transactions, ports, scope, storage, bindings, control-flow]
evidence: perl/FSM/Scheduler/ISF/FormalIdentityPlan.pm; t/1925-isf-formal-identity-plan.t; docs/audits/direct-formal-bit-width-scope-20260927.json; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/Emitter/FSM.pm; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; t/1241-isf-transaction-port-bindings.t; t/1243-isf-port-binding-schedule-report.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1925-isf-formal-identity-plan.t t/1241-isf-transaction-port-bindings.t t/1243-isf-port-binding-schedule-report.t; rerun the tracked direct-formal-bit-width-scope parser sources before classifying the parser boundary.
---

Generated children have separately qualified local port metadata under .49.1.
Direct transactions still merge into the actor module under raw formal names.
_build_parent_ir seeds actor storage maps, then merges _build_transaction maps;
same-name actor/local roles or widths conflict. Separate direct transactions
with equal-width same-named formal ports can instead share one emitted storage
identity. That admission is not independent local state.

_binding_signal_info searches actor interface and storage before caller-local
widths. An explicit narrower caller port can therefore be rejected against the
actor width when used as an activation input binding. _build_signal_width_map
has local port precedence, so expression inference and scalar endpoint lookup
also need consistent lexical resolution.

The audit reproduction uses actor status width 8 and reset 19, a worker status
input or output width 8, and a narrower input control width 4. Role/width merges
fail. A parent status input width 4 bound to worker payload width 4 is wrongly
validated as actor status width 8. Separate first/second transactions with
status output width 4 assign 3/5; public reports admit them but emit one status
register and disconnected state loops inside one FSM root.

Scope repair must distinguish caller and callee endpoints, declaration metadata,
typed operands, rule payload fan-in destinations and authored report names.
Global textual replacement can corrupt state/type/member names or messages.
.49.2.2 owns collision-safe private identities and lexical binding lookup;
.49.2.3 owns local-call runtime signoff. The prerequisite .32.1.3.3.1 owns the
already reproduced unreachable local caller and independently triggered
consumer. Its leaves separate terminal synchronization, controller contract
selection and executable repair. Existing binding tests prove artifact/report
shape, not completion of that runtime prerequisite.

FormalIdentityPlan now provides a detached declaration plan. Owner identities
are structured actor/transaction/formal tuples. Each direct formal receives a
separate proposed physical name; generated child formals retain their public
name in their own module. Allocation is deterministic under source declaration
permutation and checks case-folded collisions through the existing portable
identifier allocator. Source names and complete local declaration metadata
remain separate from physical names; no actor reset/type/width is inherited.
Lookup stays within the requested owner and returns a detached value.

The caller must supply generated-child membership and a complete additional
physical reservation set. Source identifiers are conservatively reserved too.
This is a planner contract, not proof that the current lowerer supplies that
complete set: production integration has not happened. Private selectors,
monitor/counter names, named drives, handoffs and implicit samples must be
accounted at integration; unsupported grammar cannot be rewritten by guessing.
.49.2.2.2 owns typed operand/binding rewriting and .3 owns production integration
and source-facing report preservation. Existing public lowering is unchanged.

The paired parser audit retains the former width-lookup defect: a wider formal
was rejected and a narrower formal admitted an out-of-range bit against an
actor's same-name width. .49.2.2.4 now fixes literal formal precedence and keeps
unresolved formal/type widths from borrowing actor widths or using placeholder
values. The canonical [bit-helper card](isf-bit-helper-literal-width-precedence.md) and T1926
qualify that repair separately from this still-unintegrated identity planner.
Typed operand rewriting .2 is next; it cannot substitute for parser validation.

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.1.
