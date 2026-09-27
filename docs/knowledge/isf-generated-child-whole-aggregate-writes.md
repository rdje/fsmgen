---
id: isf-generated-child-whole-aggregate-writes
title: Sole generated children write whole record and list storage on the original edge
answers:
  - "can a generated child write an entire actor-owned record or list?"
  - "do aggregate child writes preserve imported aliases and owner resets?"
  - "can two children write different members of an actor storage record?"
date: 2026-09-27
status: current
tags: [isf, storage, writers, aggregates, domains, ownership, mcp]
evidence: perl/FSM/Scheduler/ISF/ChildStorageOwnership.pm; t/1917-isf-generated-child-scalar-writes.t; t/1919-isf-generated-child-whole-aggregate-writes.t; docs/decisions/0107-actor-storage-has-one-owner-across-generated-children.md
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl t/1917-isf-generated-child-scalar-writes.t t/1919-isf-generated-child-whole-aggregate-writes.t
---

ChildStorageOwnership accepts whole actor var targets whose resolved type is
bits, record or list. It preserves the exact type alias on the private child
write-data output and owner input. Data and enable remain combinational in the
authored state/guard, and the owner alone clocks and resets the aggregate register.
Actual child reads retain their typed live owner handoff. The same connection
runs inside each declared domain; there is no implicit crossing or payload stage.

T1917 covers ordinary record/list writes, late input changes, child readback,
owner observation, guard holds and repeated/reset activations. T1919 covers
record/list layouts, nested types, imported package aliases and generated do in
independent domains, including a nondefault owner. Its packed-value oracle
reconstructs old values from scalar leaves and checks original write edges,
zero-valued updates, repeated live updates, distinct reset policies, stopped
clocks and reset isolation. Both tests replay generated modules and compare
complete native/API/newline check, semantic and schedule reports, with exact
public interfaces and no private storage/handshake leaks.

This supports whole-value replacement. Partial/member writes, scalarized bank
stores and competing parent/child or multiple-child writers retain explicit
refusals. Two children updating different record members are not implicitly
merged. Source-supported partial updates and contention remain separately owned
by .39.2.2.4.3 and .39.2.2.4.5. Aggregate authored interface/transaction ports and
generated VHDL composition are outside this qualification.

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.4.2.
