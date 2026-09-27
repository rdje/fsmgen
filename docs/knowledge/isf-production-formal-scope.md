---
id: isf-production-formal-scope
title: Production lowering separates direct formal storage and authored reports
answers:
  - "does normal compilation separate direct formals from actor pins and storage?"
  - "how does production formal renaming preserve authored schedule provenance?"
  - "where does normal compilation check final formal reservations?"
date: 2026-09-27
status: current
tags: [isf, formals, scope, lowering, reports, domains]
evidence: perl/FSM/Scheduler/ISF/FormalLowering.pm; perl/FSM/Scheduler/ISF.pm; t/1963-isf-production-formal-families.t; t/1962-isf-production-formal-scope.t; t/1961-isf-formal-source-binding-reports.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1963-isf-production-formal-families.t t/1962-isf-production-formal-scope.t t/1961-isf-formal-source-binding-reports.t t/1955-isf-formal-domain-source-products.t t/1956-isf-formal-domain-outer-namespace.t; qualify Verilator runtime through FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 only on the already qualified host path.
---

Scheduler lower/report prepare source contexts and complete reservation products,
allocate canonical direct-formal identities, then apply the qualified transaction
and rule resolvers. Source actors are cloned. Actual parent/domain modules and
their generated/reusable children pass FormalReservationCoverage before emission.
Raw LoweringIR remains the strict executable primitive; the scheduler supplies
its physical source. Internal callers supplying fully marked projected formals
are not projected again. Mixed live marked/unmarked declarations fail closed;
parsed public ISF has no private projection marker syntax.

Parent/domain IR explicitly classifies direct formals as internal signals.
Width/role metadata alone allowed an unassigned read to become an inferred
public input; T1368 exposed this in family qualification. Final coverage now
requires the internal classification, and T1963 checks exact semantic and
SV/Verilog/VHDL ports, including read-only and unused formals. Declaration
preservation creates neither a driver nor an initial value.

Direct formals retain their own width/type/role and cannot merge with actor pins,
actor storage or sibling formals. Generated children retain public endpoint names.
Rules still resolve actor scope. Static count lookup, explicit-local shielding,
zero pruning and source validation retain their separately qualified contracts.
No public schema key is added.

A detached report IR restores canonical original binding records, wait/loop
source fields, temporal operands and bank accesses. Record identities and order
must match. Executable IR stays physical: wait_count_source and loop_condition
are consumed by executable call/loop wiring, so mutating those fields in place
would corrupt emission. Inferred-storage entries and generated helper names
remain actual physical artifact identities. Source operands and binding names
remain authored provenance. Domain reports use their original local preparation.

T1962 invokes ordinary lowering on actor-pin and actor-storage shadows, strict
checks exported carriers, and compares complete native/API/newline check,
semantic and schedule responses. Independent SystemVerilog and Verilog public-pin
oracles observe private payload values through dynamic waits, generated-child
reads of unchanged actor storage, reset and repeated activation with no replay.
Injected late declarations fail before the FSM emitter is called. Domain probes
exercise raw same-spelled different-width formals and strict exported composition.
T1961 distinguishes physical domain bindings from the restored source report view.

Re-derivation is actual production declaration/report observation; falsification
uses width/role shadows, source immutability, late unreserved declarations and
independent public-pin runtime; durability is the tests and checked scope guard.
T1963 also qualifies loop/exit/continue and bank source operands against
unchanged executable physical operands, actor-owned stages/monitors, typed
sibling permutations and a real rule-helper name collision. The broader family
cohort retains parameter/constant/package width and backend selector checks. Independent sibling-controller
and plain local-call execution, explicit-local physical ownership, and storage
access reporting for SPECFORGE remain separately owned prerequisites/features.
Passing these cases does not close the historical process-containment occurrence.
Owners: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.3.2 and .49.2.2.3.4.
