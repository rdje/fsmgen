---
id: isf-aggregate-port-request-baseline
title: Authored record ports remain a separate boundary from typed storage
answers:
  - "can ISF interface ports carry packed records?"
  - "where is the SPECFORGE aggregate interface request preserved?"
  - "does internal generated aggregate handoff support authored record ports?"
date: 2026-09-30
status: current
tags: [isf, aggregate, record, ports, types, specforge]
evidence: docs/audits/specforge-aggregate-intake-20260930/manifest.json; docs/audits/specforge-aggregate-intake-20260930/capture.t; docs/audits/specforge-aggregate-intake-20260930/verify.py; perl/FSM/Adapter/ISF/Parser.pm; t/1259-isf-aggregate-storage-type-aliases.t; docs/book/src/13j-type-enum-aggregate.md
reverify: python3 -B docs/audits/specforge-aggregate-intake-20260930/verify.py
---

The preserved `sf-isf-aggregate-interface-ports` packet requests local/imported
packed record inputs and outputs, input scalar-field reads, output field writes,
whole same-type port/storage copies and public type/layout metadata. List ports
and variant records are optional. SEM `.60.4` owns delivery; intake is not
implementation.

Parser `_finalize_actor_type_references` permits aggregate aliases only for
actor storage variables; `_resolve_typed_width_entry` rejects aggregate
interface and transaction ports. The supplied whole-copy and field-guard forms
both fail at that boundary. The scalar-input/record-storage control succeeds,
preserving authored member order, typed storage width and the actual scalar
leaf assignment in its scheduled carrier.

The current control's complete strict-check report matches the supplied report
after exact source relocation and the separately shipped reset-provenance
addition. Complete native/API/newline reports, source identities and actual
carrier are retained. Offline hostile controls corrupt matching reports,
member order and the actual target to distinguish parity from semantic proof.
No new native runtime or external corpus count is claimed.

Generated internal typed handoffs are qualified by
`isf-generated-child-aggregate-reads.md` and
`isf-generated-child-whole-aggregate-writes.md`. Those internal carriers do not
establish authored-port support. Input reads and output writer/overlap admission
need separate, demonstrated dependencies; transaction-local ports and banks
are not implied by this packet. Future feature delivery may intentionally
invalidate the historical capture's refusal expectations.
