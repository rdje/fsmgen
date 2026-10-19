---
id: isf-record-output-generated-ingress
title: Generated record outputs require live owner views and original-edge write handoffs
answers:
  - "why do generated record output writers refuse?"
  - "can generated children read actor record outputs?"
  - "does an unused record output permit generated children?"
  - "does local do create a generated record output child?"
  - "does successful output schedule preview prove connected child ports?"
date: 2026-10-19
status: current
tags: [isf, record, output, generated, ownership, composition]
evidence: >-
  docs/audits/record-output-generated-ingress-20261002/manifest.json;
  docs/audits/record-output-generated-ingress-20261002/verify.py;
  t/2038-isf-record-output-generated-ingress.t;
  perl/FSM/Scheduler/ISF/RecordOutputWriters.pm;
  perl/FSM/Scheduler/ISF/LoweringIR.pm;
  perl/FSM/Scheduler/ISF/ChildStorageOwnership.pm;
  perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2038-isf-record-output-generated-ingress.t
---

At ingress baseline `1a50d4f42806651ec247ca95364c000bb52e8919`, a record-output
owning module with any generated child refuses before publication. This
includes unrelated children, unused record outputs, a scalar formal shadow and
otherwise supported generated storage writes followed by a parent output copy.
Direct ordinary, plain local `do` and owning-domain direct record outputs pass.
Record-input and scalar-storage generated controls also pass strict queries.

Actual private child writers retain `(packet> held)` at their original state,
but their `packet` output has no parent update handoff or top route. Actual
reused readers retain `packet.payload` operands without a child `packet` input.
`LoweringIR::_build_child_ports` only inherits actor inputs and assigned outputs;
`ChildStorageOwnership` routes declared storage, not actor output views.
`CompositionTop` only routes registered handoffs/explicit result bindings.
Git pickaxe roots the generated pin/top routing in
`130bf13aec896f8090a149a6640610eb06d47a96`; storage-read routes were subsequently
added in `5c0f802646c69108d15995f7e8cd7e29c32ebdf5`. Formal pin shadowing was refined
later; no name-derived output owner route follows from that refinement.

Record check/semantic failure reports retain the exact mandatory mapping
refusal; schedule emits no native JSON and API/newline retain the closed
message-only error. Scalar output read/write siblings pass scheduler/report
and public schedule preview but strict check/semantic reject the unconnected
`one.packet` realized port. The scalar control proves why a successful preview
cannot establish complete executable wiring. No public silent miswiring or
executed output behavior is claimed from private emitter text.

Canonical selected-domain sources retain the real owning declarations,
clock/reset, child definitions and actual bound instances. The unrelated idle
domain has no child. No fabricated flattened physical naming map bypasses the
public gate. All complete sources, private IR/carriers, caller JSON kinds,
native/API/actual newline products and producer/source fingerprints are kept.
Only the exact repository prefix normalizes. No HDL tool is invoked.

Literal five-bit recursive types and leaf packing, role/order/absence facts,
actual writer/reader operands and route absence re-derive the findings.
Shared caller/transport parity survives hostile role, signed-kind, module,
instance and port omissions or false admission; independent literal witnesses
reject them. Sealed evidence, original source/code/history, the permanent test
and Git provide durability. This is ingress qualification, not feature delivery.

SEM `.60.4.3.3.5.2.1` owns live owner-view reads; `.2.2` owns typed data/enable
handoffs with one explicit public owner and the original clock edge. `.2.3`
then owns complete source/module/instance/target/type/activation admission.
Public integration and fresh HIAL-qualified binary execution follow separately.
Independent competing writers remain refused; no arbitration, field writes or
extra payload capture is inferred.

Detached `.2.1.1` preparation is now separately qualified in
[the output-read card](isf-generated-child-output-read-preparation.md).
It has no production call. First-`when` action loss `.2.1.3` now closes unsupported
entry payload admission. Macro repair `.2.1.5` still precedes read integration `.2.1.2`; the scalar X/Z
operand diagnosis `.2.1.4` is repaired. The public generated-output gate remains.
