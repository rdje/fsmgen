---
id: isf-aggregate-port-request-baseline
title: Preserved aggregate-port intake precedes qualified record-input admission
answers:
  - "can ISF interface ports carry packed records?"
  - "where is the SPECFORGE aggregate interface request preserved?"
  - "does internal generated aggregate handoff support authored record ports?"
date: 2026-10-01
status: current
tags: [isf, aggregate, record, ports, types, specforge]
evidence: docs/audits/specforge-aggregate-intake-20260930/manifest.json; docs/audits/specforge-aggregate-intake-20260930/capture.t; docs/audits/specforge-aggregate-intake-20260930/verify.py; perl/FSM/Adapter/ISF/Parser.pm; t/1259-isf-aggregate-storage-type-aliases.t; t/2014-isf-record-input-public-sources.t; t/2016-isf-record-input-public-refusals.t; t/2017-isf-record-input-frontend-closure.t; docs/book/src/13j-type-enum-aggregate.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2017-isf-record-input-frontend-closure.t
---

The preserved `sf-isf-aggregate-interface-ports` packet requests local/imported
packed record inputs and outputs, input scalar-field reads, output field writes,
whole same-type port/storage copies and public type/layout metadata. List ports
and variant records are optional. SEM `.60.4` owns delivery; intake is not
implementation.

At the captured intake revision, `_finalize_actor_type_references` permitted
aggregate aliases only for actor storage variables; `_resolve_typed_width_entry`
rejected aggregate interface and transaction ports. The supplied whole-copy and
field-guard forms failed at that boundary. The scalar-input/record-storage
control succeeded, preserving member order, typed width and its leaf assignment.
These are historical receipt facts, not current admission claims.

Record-kind actor inputs were subsequently admitted by
25c01f0127144922ade78951b91439e1d9221c08. Local/imported input aliases, scalar
field reads and same-type input-to-storage copies have current public source
qualification in T2014/T2016 and the record-input book section. Record outputs,
root-list ports and transaction-local aggregate ports remain deferred. Frontend closure is qualified under
SEM .60.4.3.2.3.6.3; generated/domain/backend/native and
external consumer qualification remain separate work.

The captured control's complete strict-check report matches the supplied report
after exact source relocation and the separately shipped reset-provenance
addition. Complete native/API/newline reports, source identities and actual
carrier are retained. Offline hostile controls corrupt matching reports,
member order and the actual target to distinguish parity from semantic proof.
The reverify command authenticates the immutable intake receipt and its hostile
controls, then independently exercises current supplied sources, exact baseline
products, strict carriers and full public discovery. No new native runtime or
external corpus count is claimed.

Generated internal typed handoffs are qualified by
`isf-generated-child-aggregate-reads.md` and
`isf-generated-child-whole-aggregate-writes.md`. Those internal carriers do not
establish authored-port support. Output writer/overlap admission
needs its separate demonstrated dependencies; transaction-local ports and banks
are not implied by this packet. Future feature delivery may intentionally
invalidate the historical capture's refusal expectations.
