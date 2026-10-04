---
id: isf-aggregate-port-request-baseline
title: Preserved aggregate-port intake precedes qualified record-input admission
answers:
  - "can ISF interface ports carry packed records?"
  - "where is the SPECFORGE aggregate interface request preserved?"
  - "does internal generated aggregate handoff support authored record ports?"
  - "what does T1986 record-value helper check?"
date: 2026-10-04
status: current
tags: [isf, aggregate, record, ports, types, specforge]
evidence: docs/audits/specforge-aggregate-intake-20260930/manifest.json; docs/audits/specforge-aggregate-intake-20260930/capture.t; docs/audits/specforge-aggregate-intake-20260930/verify.py; perl/FSM/Adapter/ISF/Parser.pm; t/1259-isf-aggregate-storage-type-aliases.t; t/2014-isf-record-input-public-sources.t; t/2016-isf-record-input-public-refusals.t; t/2017-isf-record-input-frontend-closure.t; docs/book/src/13j-type-enum-aggregate.md
reverify: python3 -B docs/audits/record-value-runtime-20261004/verify.py && scripts/run_with_ram_guard.sh -- prove -Iperl t/2017-isf-record-input-frontend-closure.t
---

The `sf-isf-aggregate-interface-ports` packet requests local/imported
packed record inputs and outputs, input scalar-field reads, output field writes,
whole same-type port/storage copies and public type/layout metadata. List ports
and variant records are optional. SEM `.60.4` owns delivery; intake is not
implementation.

At intake, `_finalize_actor_type_references` permitted
aggregate aliases only for actor storage variables; `_resolve_typed_width_entry`
rejected aggregate interface and transaction ports. Supplied whole-copy/field-guard forms failed there. The scalar-input/record-storage control accepted with member order, typed width
and its leaf assignment preserved.
These receipts are historical.

Record-kind actor inputs were admitted by
25c01f0127144922ade78951b91439e1d9221c08. Local/imported input aliases, scalar
field reads and same-type input-to-storage copies are public-source qualified
in T2014/T2016 and the record-input book. [Record outputs](isf-record-output-source-admission.md) now admit declarations/whole copies;
fields, root-list and transaction aggregate ports stay closed. Frontend closure:
SEM .60.4.3.2.3.6.3; generated/domain/backend/native and
external consumer qualification stays separate.

Captured control's full strict-check matches the supplied report after
exact source relocation and the shipped reset-provenance addition. Full native/API/newline reports, identities/carrier are retained. Offline hostile
controls corrupt matching reports, member order and the actual target to
distinguish parity from semantic proof. Reverify authenticates intake/controls;
checks current supplied sources, exact baseline products, strict carriers
and full public discovery. No native runtime or external corpus count is claimed.

Generated typed handoffs are qualified by
`isf-generated-child-aggregate-reads.md` and
`isf-generated-child-whole-aggregate-writes.md`. Internal carriers do not establish authored-port support. Output writer/overlap admission needs separate dependency proof; this packet implies no transaction-local ports/banks. Future delivery may invalidate historical refusal expectations.

T1986 [profile](../audits/record-value-runtime-20261004/scope.txt) binds calls, first-line fragments,
synthetic checks and typed graphs; copy/cause/product proof stays open.
