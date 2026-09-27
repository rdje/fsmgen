---
id: isf-multi-domain-generated-children
title: Multi-domain generated transaction children are realized in the flat outer top
answers:
  - "why were generated child transaction artifacts missing in multi-domain actors?"
  - "how does multi domain generated child composition wire clocks and CDC inputs?"
  - "why did a generated do child execute again while start stayed high?"
date: 2026-09-27
status: current
tags: [isf, domains, composition, children, activation, naming, mcp]
evidence: perl/FSM/Scheduler/ISF.pm; perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm; perl/FSM/Scheduler/ISF/ChildActivation.pm; t/1912-isf-multi-domain-generated-children.t; t/1247-isf-clock-domain-partition.t
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl t/1912-isf-multi-domain-generated-children.t t/1247-isf-clock-domain-partition.t
---

The scheduler formerly rebuilt each domain IR but emitted only its parent FSM.
The outer top omitted generated transaction children and their handshake/data
wiring. Domain realization now emits domain-owned child definitions, allocates
module/file identities against the outer module namespace, and allocates flat
instance identities against all public pins, domains and CDC children. Reused
instances retain separate bindings. Ordinary CompositionTop component emission
supplies the same wiring contract; domain boundary maps replace virtual parent
ports with their existing public or CDC sources/destinations. Nested tops are
not introduced. Domain clocks and reset policies remain on the child IR.

Schedule domain/local names stay logical. The lower-result artifact map and
semantic composition children identify the allocated source/module/instance;
native, adapter and newline MCP reports preserve the same schema and values.
Transaction-local payload ports take precedence over same-name actor signals
when validating domain access; unowned actor crossings remain rejected.

Generated do holds start until completion. Delayed done can reach the caller
after the child's terminal state has returned to idle. ChildActivation retains
private start history so that held assertion cannot execute the child again;
deassertion rearms it. Reset belongs to the child domain. The accepted start
edge, state sequence and done timing are unchanged. The generated-do output
binding remains combinational and valid during the child's done pulse.

T1912 checks independent domain clocks, reset isolation, repeated activations,
exact output-pulse counts, reused definitions, parameter handoffs, CDC ready
input routing, collisions, reset absence, scheduled replay and full public
report parity. Its child-await runtime TODO belongs to `.32.1.3.3.3`; named
completion timing is qualified by `.46`; default-domain library parent interfaces
are qualified by `.47`. Nondefault library system bindings remain owned by `.48`.
Domain storage-read admission remains owned by `.39.2.2.2.3.2`.
This fact does not qualify those pending behaviors or multi-domain VHDL.

Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.3.1`.
