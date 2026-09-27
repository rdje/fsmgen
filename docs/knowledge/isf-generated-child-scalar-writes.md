---
id: isf-generated-child-scalar-writes
title: Sole scalar child writers transfer data and enable on the original edge
answers:
  - "how does a generated child write the parent actor storage register?"
  - "does a child storage write wait until completion or add a register cycle?"
  - "why are competing child or parent storage writers rejected?"
date: 2026-09-27
status: current
tags: [isf, storage, writers, composition, ownership, reset, mcp]
evidence: perl/FSM/Scheduler/ISF/ChildStorageOwnership.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm; t/1917-isf-generated-child-scalar-writes.t; docs/audits/generated-child-storage-ownership-20260926.json; docs/decisions/0107-actor-storage-has-one-owner-across-generated-children.md
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl t/1917-isf-generated-child-scalar-writes.t
---

The retained writer once updated a private child status register while its
parent observed reset value 19 instead of 37. Applying an internal role to both
copies could not repair shared actor-state semantics; reads were routed first.

prepare_child_storage_writes now turns each qualified full-width scalar
sequential assignment into combinational child write-data and write-enable
assignments in the same state/guard. The owner receives private input ports and
an always-active decision-tree assignment gated by that enable. The original
register/reset remains only in the owner. No payload register, extra state or
completion-edge delay is introduced. Child reads still use the live owner view.
Scalar aliases and field metadata preserve their existing whole-register meaning.

connect_child_storage_writes requires one generated instance per written scalar
and rejects any parent data writer. Multiple independent scalar targets are
allowed. Generated names reserve authored/internal/state names; explicit write
links bypass legacy output suffix matching so an unrelated public input cannot
become a second writer endpoint. Transaction-local ports continue to shadow
actor storage identities.

T1917 changes data immediately before the authored assignment edge and checks
the parent's next-cycle sequential observation, conditional hold paths, child
readback, explicit/default reset and repeated activation. It covers scalar
aliases, read-modify-write, field metadata, generated do and distinct targets,
and checks exact interfaces, scheduled replay and full native/API/newline reports.
The exact retained defect source is replayed independently. This qualifies
ordinary/single-domain SystemVerilog runtime. Multi-domain writers, competing
writers, bank/aggregate/member writes and wider VHDL composition remain outside
this slice; their task owners remain explicit.

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.3.1.
