---
id: isf-storage-domain-path-ownership
title: Aggregate paths inherit actor ownership and inferred targets cannot redefine domains
answers:
  - "why must aggregate storage member accesses use the storage root domain?"
  - "can assigning an actor signal inside a transaction change its clock domain?"
  - "why does an explicit transaction port collide with actor storage?"
date: 2026-09-27
status: current
tags: [isf, domains, storage, aggregates, ownership, diagnostics]
evidence: t/1921-isf-child-port-storage-shadowing.t; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1920-isf-storage-domain-path-ownership.t; t/1919-isf-generated-child-whole-aggregate-writes.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1920-isf-storage-domain-path-ownership.t t/1247-isf-clock-domain-partition.t
---

The whole-aggregate writer qualification exposed a missed domain check:
_validate_domain_signal_access skipped dotted/indexed references, and inferred
transaction assignment names took precedence over declared actor ownership.
Public lowering admitted sibling-domain member reads/writes and whole-register
writes. Aggregate child reads could fail later as unconnected composition ports
instead of a contextual clock-domain violation.

The validator now resolves parsed member/index paths to a declared actor-storage
root for domain lookup, preserving the authored path in diagnostics. Package and
enum member names are not treated as storage unless their root is declared
actor storage. Inferred local assignment targets exclude actor signal names;
explicit transaction ports are then applied with their authored local domain.
T1920 checks transaction/rule/guard/nested path access, scalar/output writes,
read-before-assignment, same-domain controls, inferred locals and enum members.

Generated-child explicit ports sharing actor-storage names are qualified under
.49.1: inherited actor metadata is removed before local declarations merge, and
child storage cleanup preserves the local port metadata. T1920 now accepts those
input/output controls; T1921 proves independent actor/local values at runtime.
Direct/non-generated port collisions remain under .49.2; explicit local
declarations require separate .49.3 qualification.

Owner of the domain validation repair: .39.2.2.4.2 in
SEMANTIC-INTROSPECTION-MCP-FRONTIER. Terminal await_all without a following
completion also exposed a missing transition target; retained source and warning
are owned by .32.1.3.3.1, alongside the existing scheduling repairs.
