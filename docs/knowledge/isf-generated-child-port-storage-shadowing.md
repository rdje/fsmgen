---
id: isf-generated-child-port-storage-shadowing
title: Generated child ports keep local metadata when their names match actor storage or pins
answers:
  - "can a generated transaction formal shadow an actor input or output pin?"
  - "why does spawn bind a same-named child input twice?"
  - "can a child transaction input or output share an actor storage name?"
  - "does an actor register reset or type leak into a same-named child port?"
  - "how do child ports differ from same-named actor storage across domains?"
date: 2026-09-27
status: current
tags: [isf, composition, ports, storage, ownership, types, reset, domains]
evidence: t/1934-isf-generated-pin-shadow.t; perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/ChildStorageOwnership.pm; t/1921-isf-child-port-storage-shadowing.t; t/1920-isf-storage-domain-path-ownership.t
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl t/1934-isf-generated-pin-shadow.t t/1921-isf-child-port-storage-shadowing.t t/1920-isf-storage-domain-path-ownership.t
---

_build_child_ir previously seeded actor-storage width/type/reset/role maps before
merging transaction ports. An explicit same-named port failed the width/role
merge before child storage selection could distinguish it. Cleanup also removed
reset/role entries under that name even though they could belong to the local
port. Generated children now remove inherited metadata for explicit local port
names before merging local declarations, and storage cleanup skips those names.

The child port retains its own direction, width, alias and role. Actor reset
metadata does not leak into it. It requests no actor storage read/write handoff;
the original actor register remains owned, reset and updated independently.
Explicit bindings keep their published activation timing and payload semantics.
The trigger qualification also exposed a separate input-handoff defect: its
per-rule register captured the payload, but a redundant start-pulse guard drove
the child input back to zero before a delayed read. The generated handoff now
continuously exposes that captured register, retaining existing capture/start
and completion-output timing. It adds neither a new request queue nor a policy
for overlapping requests.

An actor register in a sibling domain does not change the explicit port's local
domain. This is local naming, not a data crossing.

T1921 exercises input/output collisions, narrower local widths, distinct signed
aliases, owner/local reset independence, repeated calls, scalarized bank-entry
names, generated do, generated rule-trigger input snapshots and independently
clocked owners. Exact IR/interfaces,
scheduled replay and complete native/API/newline reports accompany independent
runtime observations. T1920 retains the initial same-name domain controls.

Generated actor-pin shadows use the same local ownership rule. Child port
construction excludes inherited actor inputs under explicit formal names and
does not classify formal writes as actor-output assignments. This preserves
formal direction and width as well as the already independent type/reset maps.
Spawn automatic input wiring excludes explicitly bound child endpoints, in
addition to its existing source-name filter. Otherwise a different actual
could supply one explicit handoff while the actor pin supplied a second driver.
Generated do already excluded bound endpoints; that behavior is retained.
T1934 qualifies actor input/output and formal input/output combinations across
spawn, generated do and parameterized trigger, with exact IR, strict carriers,
complete native/API/newline reports and repeated/reset payload provenance.
The typed-output/reset combination remains outside the parser's admitted
surface; output reset controls use explicit scalar widths.

Direct/non-generated transaction-port collisions remain owned by .49.2 because
both identities share the parent module. Explicit local declarations are a
separate source form and remain under .49.3. No success for those scopes is
inferred from generated-child ports.

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.1.
