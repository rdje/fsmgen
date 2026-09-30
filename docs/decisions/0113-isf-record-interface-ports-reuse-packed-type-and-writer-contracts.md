---
id: isf-aggregate-port-contract-selection
title: Selected record ports reuse packed types and qualified writers
answers:
  - "what contract is selected for ISF record interface ports?"
  - "what is the packed record port field order?"
  - "do record input reads require independent controller repairs?"
  - "are list ports and variant records part of required record-port delivery?"
  - "why must metadata validation predicates use scalar context?"
date: 2026-09-30
status: current
tags: [isf, record, ports, types, layout, writers, specforge]
evidence: perl/FSM/Support/ISFInterfacePortMetadata.pm; t/1983-isf-interface-port-metadata.t; docs/decisions/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md; docs/audits/specforge-aggregate-intake-20260930/packet.json; perl/FSM/Package/AggregatePathSupport.pm; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
---

# 0113 — ISF record interface ports reuse packed type and writer contracts

- Date: 2026-09-30
- Type: ISF language, lowering and public report contract
- Status: selected; implementation and qualification remain open
- Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.2`

## Context

The preserved SPECFORGE request is
`docs/audits/specforge-aggregate-intake-20260930/packet.json`.
Its required R1–R3 ask for declared packed record inputs/outputs, scalar field
access, whole same-type port/storage copies, and visible type/layout metadata.
R4 list-root ports and R5 variant records are optional. The intake's current
refusals are historical evidence, not a new regression oracle after delivery.

The parser currently admits aggregate aliases only on storage variables.
Lowering already preserves interface type references in `+size`; core `.fsm`
type/path machinery owns packed representation. Generated internal storage
handoffs do not establish authored aggregate-port support. Decisions `0107`
and `0109` retain state ownership, physical writer admission and execution
qualification. R13/R14 require stable public reports and ordered IAL1 → IAL0
lowering; this feature must not add a second type system or bypass IAL0.

## Decision

### Source and value contract

Select `(input NAME (type T))` and `(output NAME (type T))` for an existing
actor-local or imported package-qualified alias resolving to a packed record.
Reuse the existing recursive record/list member type system, including nested
members. Root list ports remain R4. Unknown types, malformed declarations,
unresolved/nonpacked types and unsupported carriers fail before successful
lowering, with the port/type/context identified. Width/type exclusivity,
closed options, declaration presence and existing domain ownership remain.
Typed output reset/default options remain outside this request and retain
their current explicit refusal.

Input fields are live scalar reads in each already-supported scalar expression
context: transaction conditions, set/update RHS, rules and named drives.
Existing explicit sampling remains the way to request a snapshot. Resolve
paths against the declared root type; unknown members, non-scalar leaves and
out-of-range nested items fail contextually. Do not infer fields by punctuation
or admit whole-record truthiness, arithmetic or subaggregate writes.

Whole copies involving a record port require the same resolved record type:
compare recursive kind, member names/order and scalar width/signed/state-model
properties under the existing type resolver; equal packed width alone is
insufficient. Alias spelling may differ when it resolves to that same type.
Support input-to-storage and storage-to-output, then other port/storage
directions whose declared input/output roles permit the read/write. Inputs
cannot become assignment targets. Preserve existing storage-only packed
transfers and scalar-port behavior; the new check applies to record-port
copies, not retroactively to all aggregate storage assignments.

Reuse typed `+size` and explicit `+interface` carrier entries. Record member
order is authored order, first member most significant, as already implemented
by `AggregatePathSupport::record_member_low_offset`. Scalar paths retain their
leaf widths and exact packed ranges. No scalarized public field pins, payload
register copies, implicit reset, added pipeline edge or silent arbitration.

### Detached public metadata

Select optional `source.interface_ports` on successful directly parsed ISF
check/semantic reports, and `interface_ports` in schedule JSON. One producer
must project fresh JSON-safe values from parsed declared ports through native,
API and actual newline MCP; it must not export parser/private IR objects.
Unrelated source formats and failure reports gain no invented ISF declarations.
Unknown declaration metadata in caller-created actors remains null, rather
than reconstructed from inferred hardware signals.

The snapshot orders inputs in their authored order followed by outputs in
their authored order, matching the existing parser handoff. Entries contain
`name`, `direction`, `width`, and optional authored `type` and resolved
`type_kind`; named-domain entries also contain `domain`. A record adds
`fields`, an ordered array of scalar leaves with port-relative `path`, `width`,
`lsb`, `msb`, `signed`, and optional `state_model`. Nested paths follow the
existing aggregate path syntax. The normalized semantic type catalog remains
the authority for recursive type declarations. Schedule domain details carry
the same snapshot for their declared ports. Generated private handoffs do not
appear as authored top ports. Advertise every added field family in the public
capability contracts and qualify detached values and complete report parity.

### Delivery and qualification order

1. Implement the detached metadata producer on the currently admitted scalar
   interface, with record-layout producer controls. Prove unchanged scheduled
   FSM and HDL; this preparatory slice does not admit record source ports.
2. Admit and qualify packed record inputs, scalar reads and input-to-storage
   whole copies. Cover local/imported/nested types, invalid paths/types, unused
   declarations, domains and generated children under their existing bounds.
3. Admit output records and whole copies only with sound physical writer
   ownership/admission, preserving unrelated scalar and storage controls.
4. Add scalar output-field writes after qualifying physical packed-range
   overlap. Whole-root/member overlap and generated competing writers must
   refuse unless a demonstrated compatibility/exclusion contract admits them.
5. Qualify affected backend profiles and the complete supplied consumer
   outcome. Direct SystemVerilog/Verilog and supported VHDL subsets have
   separate obligations; an unsupported profile must refuse precisely.

Input delivery does not depend on general independent-controller repairs.
Output writes consume those prerequisites only where their actual behavior
needs them. Native HDL observations require existing HIAL admission and
failure-only observation; never replay a spent capture to seek recurrence.
Each implementation leaf may split further before source changes.

## Consequences

R1–R3 remain unshipped until their owned slices and consumer qualification pass.
R4/R5 stay separately owned optional follow-ups after required duration/timer
work; transaction-local aggregate ports, banks and variant syntax are not
implicitly admitted. The book keeps present support boundaries and labels this
selection as future work. No external corpus counts, timing guarantees,
runtime signoff or downstream integration completion follow from this decision.

Permanent qualification must include independently authored packed values,
member-order/type mismatch and input-write negatives, unchanged baseline
controls, complete native/API/newline products, supported corpus cases,
capability/spec/book alignment and recoverable downstream response evidence.

## Retrieval signpost

Decision 0113 selects local/imported packed record ports and reuses the existing
IAL0 typed carriers. Authored member order puts the first member at the most
significant end; the core aggregate path resolver supplies exact leaf ranges.
Whole copies involving record ports require matching resolved recursive types,
not merely equal packed widths.

Detached declaration metadata precedes record source admission. Input fields
are live scalar reads; explicit sampling requests a snapshot. Input delivery
does not depend on general independent-controller repairs. Output whole/member
writes need their demonstrated physical writer ownership and overlap controls.
R1–R3 remain unshipped until implementation and consumer qualification complete.
Optional list-root ports and variants follow required record/duration/timer
delivery; transaction-local aggregate ports and banks gain no implicit support.

The historical intake preserves the old refusal, not a future acceptance
oracle. Follow the decision for the public snapshot shape and the task nodes
for current qualification. No new native runtime or external corpus measurement
is established by this selection.

## Producer implementation evidence — 2026-09-30

SEM `.60.4.3.1.1` qualifies the detached producer independently of source
admission and report wiring. T1983 retains independently expected nested/imported
ranges, signed/state-model leaves, mutation isolation and invalid metadata.
The draft's hostile controls found an argument-context defect: a failed regex
returns an empty list in list context, while an array returns its members.
Either can change the predicate/message argument slots of a validation helper.
Predicates now return explicit booleans or scalar counts; the helper also
requires exact argument arity. This is a producer repair, not a claim about
uninspected validators or a public record-port implementation.

Reproduce the failed-regex mechanism independently:

```bash
perl -e 'sub predicate { $_[0] =~ /\A[01]\z/ } sub guard { print "arguments=",scalar(@_)," first=",($_[0] // "undef"),"\n" } guard(predicate(2), "error message"); guard(scalar(predicate(2)), "error message");'
```

The first call places the message in the predicate slot; the scalar call keeps
both slots. The permanent hostile controls verify refusal rather than accepting
report parity as proof of valid metadata. No native HDL runtime is established.
