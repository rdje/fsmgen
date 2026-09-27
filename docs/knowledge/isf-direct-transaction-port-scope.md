---
id: isf-direct-transaction-port-scope
title: Direct transaction ports still share raw identities and require controller qualification
answers:
  - "can direct transaction ports share actor storage names?"
  - "why does a caller local port bind with the actor storage width?"
  - "do different direct transactions have independent same-named formal ports?"
  - "what must precede direct transaction port scope repair?"
date: 2026-09-27
status: current
tags: [isf, transactions, ports, scope, storage, bindings, control-flow]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/Emitter/FSM.pm; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; t/1241-isf-transaction-port-bindings.t; t/1243-isf-port-binding-schedule-report.t
reverify: Read the .49.2.1 direct-port audit reproduction recipes and rerun public check/schedule/semantic probes under the RAM guard; inspect the scoped task status before inferring runtime support.
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

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.1.
