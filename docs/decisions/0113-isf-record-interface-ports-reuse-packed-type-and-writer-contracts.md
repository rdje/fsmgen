---
id: isf-aggregate-port-contract-selection
title: Selected record ports reuse packed types and qualified writers
answers:
  - "what contract is selected for ISF record interface ports?"
  - "what is the packed record port field order?"
  - "do record input reads require independent controller repairs?"
  - "are list ports and variant records part of required record-port delivery?"
  - "why must metadata validation predicates use scalar context?"
  - "where are declared ISF interface ports exposed in reports?"
  - "how is declared interface metadata qualified against supported ISF source queries?"
  - "which type and lexical gates must precede record input admission?"
  - "how are record value gates and contextual diagnostic oracles qualified?"
  - "which existing domain-path defect must be repaired before record input admission?"
  - "how is foreign-domain scalar slice and input-index refusal repaired and qualified?"
  - "how are actual parsed record-value declaration scopes prepared?"
date: 2026-09-30
status: current
tags: [isf, record, ports, types, layout, writers, specforge]
evidence: perl/FSM/Support/ISFInterfacePortMetadata.pm; perl/FSM/Support/ISFRecordPortValues.pm; perl/FSM/Support/ISFRecordPortScopes.pm; t/1987-isf-record-port-declaration-scopes.t; t/1983-isf-interface-port-metadata.t; t/1984-isf-interface-port-report-integration.t; t/1985-isf-interface-port-public-qualification.t; t/1986-isf-record-port-value-gates.t; t/lib/FSM/Test/SourceQueryCoverage.pm; docs/decisions/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md; docs/audits/specforge-aggregate-intake-20260930/packet.json; perl/FSM/Package/AggregatePathSupport.pm; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
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


## Declaration report integration — 2026-09-30

SEM `.60.4.3.1.2` captures validated parser declarations before scheduler
port injection. Ordinary module IR carries a fresh closed snapshot; domain
sources select their original owned entries. Generated transaction children
have unknown declaration metadata, rather than pretending private ports are
actor declarations. Reports distinguish known empty arrays from unknown null;
unrelated and failed source reports omit the ISF source field.

The shipped preparatory surfaces are success `source.interface_ports`, schedule
`interface_ports` and owned `clock_domains[].interface_ports`, with one complete
shared discovery descriptor at `source_optional_fields.interface_ports` and
`schedule_report_interface_ports`. T1984 independently expects local/imported
scalar declarations, unused/undriven entries, source order and domain ownership;
actual event crossings and generated children demonstrate private-port exclusion.
This report delivery does not admit authored records. Complete transport and
supported-corpus qualification remains explicitly owned by `.60.4.3.1.3` before
record input implementation. No native HDL runtime is claimed.


## Complete metadata qualification — 2026-09-30

SEM `.60.4.3.1.3` qualifies complete typed native/API/actual newline products
against independent declaration witnesses. T1985 joins the live
`build_source_query_cohort()` selector's ISF rows to explicit reviewed source
identities and declared port lists, then executes every applicable check,
semantic and schedule query. The selector owns supported catalog applicability;
this is not a census of product features, all repository fixtures or runtime
coverage. `feature.isf_declared_interface_metadata` now names this delivered
metadata through the dedicated `isf/interface_port_metadata.isf` fixture in
the existing supported ISF pipeline corpus.

Local/imported aliases, unused/undriven declarations, known empty interfaces,
a named empty domain, malformed record/list/width refusals and unrelated
FSM/PPIF reports receive complete transport comparisons. Discovery compares
complete native, in-process, API and newline sections. Canonical typed JSON
comparisons retain scalar kinds; shared field loss, wrong width/direction/order,
private data and stringified widths still fail independent expectations even
when all three fabricated transport copies agree. No parser or report values
are repaired by the oracle. Source bytes remain unchanged across queries.

Together with T1983/T1984 and the retained historical report/carrier/HDL controls,
this closes the preparatory declaration metadata lane. Authored record source
ports and their hardware behavior remain owned by the subsequent input/output
leaves; no native HDL execution or complete consumer delivery is established.


The corpus accounting control rejects duplicate `(relpath, classification,
coverage)` tuples even under different IDs. Reusing an existing source for the
new identical contract failed that gate, so the delivered metadata owns a
separate runnable fixture. T248 also exposed stale exact expectations from the
prior storage-word-access entry (Git `3fa482924`, found with `git log -S`).
The pre-slice `241fad6b5` public catalog already exceeded those expectations;
the new fixture adds only its distinct entry. T248's exact census, tuple/ID and
classification/strict checks and T1883's complete cohort join retain the repair.
Counts describe catalog entries, not independently implemented features or
runtime qualification. Recount from the live public catalog; do not reuse the
old dated qualification receipt as a current total.

## Record-input ingress selection — 2026-09-30

SEM `.60.4.3.2.1` traces the refused input boundary before widening it. Parser
`_finalize_actor_type_references` admits aggregate aliases only on storage;
`_validate_actor_aggregate_storage_paths`, rule operand maps and enum
disambiguation currently select storage roots. Adding inputs to one map is
insufficient. Use a shared declaration-root description, with transaction
locals/formals and drive parameters masking outer names in their actual scope.
An input shadowed by a writable formal must not become that formal's role;
an unresolved local must not borrow its outer type or placeholder width.
The existing formal resolver and domain ownership remain authoritative.

Prepare a strict resolved-record identity gate separately from
`PayloadTypeSupport::payload_compatible_with_type_spec`. That public helper
intentionally checks payload shape and scalar width, allowing different signed
and state-model facts. Preserve it for its existing callers. Port copies compare
recursive kinds, ordered record members, ordered list children, widths, signed
values and optional resolved state-model presence/value. Unspecified stays
unspecified; do not substitute a backend rendering default. Alias names are not
part of resolved identity. Malformed/unresolved roots fail contextually.

Transaction conditions, switch values, set/update RHS, rule guards/assignments,
named-drive bodies/actuals and inline drives need explicit scalar-versus-copy
checks from the first admission. Whole-record values are permitted only in
qualified same-type assignments with allowed declaration roles; expression
operators, truthiness and subaggregate writes refuse. Existing storage-only
packed transfers retain their separate contract. Domain lookup resolves a path
to its declared root, honoring lexical masking and preserving the authored
path in diagnostics; it must not invent a crossing from a same-named formal.

The current aggregate validator handles `set`, but not `update` or `sample`
leaf paths. Sampling width collection copies exact root widths, not resolved
leaf facts. Input delivery therefore owns explicit scalar-leaf sampling in
entry/body contexts, with resolved width/type and existing capture timing.
Whole-record sampling into an inferred alias remains outside this bounded
delivery. No hidden sample, delayed edge or new aggregate local is introduced.
Typed `+size` and explicit `+interface` already preserve unused declarations;
generated/domain routes must retain those identities before behavior signoff.

Reproduce the identity distinction and current source refusal without HDL:

```bash
scripts/run_with_ram_guard.sh -- perl -Iperl -MFSM::Adapter::ISF -MFSM::Package::PayloadTypeSupport -MJSON::PP -e '
my $p = FSM::Adapter::ISF->new;
my $a = $p->parse_source(q{(actor controls
  (types (type plain (record (payload (bits 8)))) (type alias plain)
    (type signed_frame (record (payload (signed (bits 8)))))
    (type four (record (payload (four_state (bits 8)))))
    (type two (record (payload (two_state (bits 8))))))
  (interface (output done))
  (storage (var a (type plain)) (var b (type alias))
    (var c (type signed_frame)) (var d (type four)) (var e (type two)))
  (transaction main (complete done)))}, "controls.isf");
my @t = map { $_->{type_spec} } @{$a->{storage}};
my $j = JSON::PP->new->canonical;
die "alias mismatch" unless $j->encode($t[0]) eq $j->encode($t[1]);
for my $pair ([0,2], [0,3], [3,4]) {
  die "control lost" unless $j->encode($t[$pair->[0]]) ne $j->encode($t[$pair->[1]])
    && FSM::Package::PayloadTypeSupport->payload_compatible_with_type_spec(@t[@$pair]);
}
my $ok = eval { $p->parse_source(q{(actor refused
  (types (type frame (record (payload (bits 8)))))
  (interface (input packet (type frame)) (output done))
  (storage (var held (type frame)))
  (transaction main (set held packet) (complete done)))}, "refused.isf"); 1 };
die "refusal lost: $@" if $ok || $@ !~ /interface port.*references aggregate type/;
print "alias identity, distinct property controls and input refusal verified\n";
'
```

The input lane now separately owns closed gates, source admission, generated/
domain carriers and independent HDL/public completion. This planning receipt
does not establish new input acceptance, sampling support or native behavior.

## Unwired value-gate qualification — 2026-09-30

SEM `.60.4.3.2.2` prepares `ISFRecordPortValues` without parser or scheduler
wiring. `record_value_scope` takes closed resolved outer/local declarations;
the nearest binding masks its outer type and role even when unresolved.
`record_value_reference` retains scalar path type/width/range through
`AggregatePathSupport`, refuses input writes and whole/subaggregate scalar
values, and returns unknown tokens to their existing validator. The caller must
still validate those tokens and supply actual lexical bindings; a prepared map
does not establish parser, domain or generated-child integration.

`validate_record_port_copy` uses the existing composition declared-type
comparison after closed resolved-shape validation by the qualified declaration
producer. Root aliases are absent from that identity. Equal packed widths,
renamed/reordered members, bit/bits kinds, nested shape/list order, signed and
optional state-model differences are independently distinguished. Transfers
with no whole record port keep their existing scalar/storage assignment owner.
Scalar formal/local slices use a one-member wrapper for existing core traversal;
the wrapper preserves offsets and adds no source carrier or type declaration.

T1986's draft negative helper matched an expected regex passed as a caller
argument inside `Carp::confess` stack text. That concealed a wrong-key diagnostic
projection (`reason` instead of the resolver's `code`), yielding `unresolved`
for otherwise specific invalid paths. Restricting the oracle to the first
diagnostic line first made the unknown-member/index/syntax controls fail. The
producer now retains the core code. A permanent independently wrong message
with the expected pattern only in its stack demonstrates the original false
match and the corrected oracle's rejection. This is a repaired unshipped draft
and test-helper defect, not a finding about uninspected diagnostic oracles.

T1986 retains resolved alias/imported positives, independently authored ranges,
same-width counterexamples, lexical unresolved/scalar/formal shadows, input-role
negatives, malformed/cyclic facts, storage-only bypass and unchanged aggregate
source refusal. T1983/T1259 and core path, structural type and interface-boundary
controls pass alongside it. Source admission, sample timing, carriers, complete
public products and HDL behavior remain owned by later leaves.

## Contextual integration and domain prerequisite — 2026-09-30

SEM `.60.4.3.2.3.1` splits actual lexical/contextual gate preparation, explicit
leaf sampling carriers, declared-domain protection, first input admission and
frontend/public replay before implementation. Parser type finalization precedes
aggregate/enum checks, but their current maps select storage roots. Locals,
formals, drive parameters and explicit samples require their actual binding
facts; inferred writes must not redefine an actor input. Sampling preparation
must retain signed/state facts as well as leaf width through existing typed
carriers, with no new snapshot edge or whole-record inferred local.

At pre-repair revision `02827d840254d6cdbfa4020be7910bb7ae9ac4cb`, public
parse/lower probes reject a foreign-domain whole scalar input and unsliced
record-storage member, yet accept the same input's bit/indexed slices and the
member/storage scalar slices. `_validate_domain_signal_access` recognizes only
single-index path suffixes and only actor-storage roots for non-identifiers.
The missing colon form and interface-root exclusion bypass domain admission.
This proves a source/lowering validation defect; no HDL runtime is established.
P1 repair `.60.4.3.2.3.4.1` is next, before unrelated contextual implementation;
`.4.2` retains future record/formal/domain qualification. Do not widen the
matcher blindly into enum/package namespaces or erase nearest-binding roles.

Reproduce the bounded existing source defect without native HDL execution:

```bash
scripts/run_with_ram_guard.sh -- perl -Iperl -MFSM::Adapter::ISF -MFSM::Scheduler::ISF -MJSON::PP -e '
my $header = q{(actor domain_probe
 (clock-domains (domain core (clock clk) :default) (domain aux (clock aux_clk)))
 (types (type frame (record (payload (bits 8)))))
 (interface (input start) (input data (width 8) (domain aux)) (output seen (width 8)))
 (storage (var record_value (type frame) (domain aux)) (var scalar (width 8) (domain aux)))};
my @rows;
for my $token (qw(record_value.payload record_value.payload[3:0] scalar[3:0] data data[3:0] data[0])) {
 my $ok = eval {
  my $a = FSM::Adapter::ISF->new->parse_source($header
    . "(transaction main (on start) (set seen $token)))", "domain-probe.isf");
  FSM::Scheduler::ISF->new->lower($a); 1;
 };
 my ($message) = split /\n/, $@;
 push @rows, {token => $token, accepted => $ok ? JSON::PP::true : JSON::PP::false,
   diagnostic => $message // ""};
}
print JSON::PP->new->canonical->pretty->encode(\@rows);
'
```

Before repair, `record_value.payload` and `data` refuse with their authored
foreign-domain ownership; the slice/index cases accept. Permanent first-line
negative oracles and same-domain/lexical/enum/package/crossing controls must
retain the repair. After repair this dated receipt remains historical; the
current command and owning task establish present admission.

## Existing domain-path repair — 2026-09-30

SEM `.60.4.3.2.3.4.1` closes the confirmed existing source-validation defect
before record admission. Domain lookup now recognizes scalar colon slices and
uses the nearest declared actor/formal/local root for indexed references.
Dotted paths retain their existing storage classification, preserving enum and
package names. Future authored record-input member ownership remains under
`.4.2`, after scoped contextual preparation; record source ports still refuse.

T1920 first goes RED on the recorded foreign member/storage slices and input
slice/index controls, then passes the repair. Its first diagnostic line must
name the exact path, access and declared domains. Nested list/member slices,
reversed and single-bit ranges, same-domain values, unrelated enum names and
explicit generated formal shadows are included. The unchanged command above
now rejects every recorded foreign case with its authored ownership message.

T1985 adds complete typed native/API/actual newline check/semantic comparisons
and existing schedule transport errors for these sources, with independent
exact diagnostic messages, absent successful declaration snapshots, no partial
schedule and unchanged source bytes. T1982 preserves complete earlier domain
reports, actual scheduled FSM files and SystemVerilog/Verilog HDL except date.
T1247/T1259/T1986 retain domain partition, storage/types and unwired value gates.
This repairs validation; it establishes no new record authoring, general
controller repair, native HDL runtime or downstream completion.

## Actual declaration-scope preparation — 2026-09-30

SEM `.60.4.3.2.3.2.1` prepares detached actor, transaction and drive scopes in
`ISFRecordPortScopes`. Actor ports and `var` storage consume finalized declaration
widths and resolved type facts. Transaction formals replace outer declarations;
explicit top-level local clauses provide the nearest width-only binding.
Resolved type facts retain signed and optional state-model properties. An
unresolved typed declaration never uses its placeholder width. Symbolic local
widths remain unknown because existing local admission requires positive
literal widths; that admission is not changed by this projection.

Named-drive parameters carry names without resolved types. They mask outer
roles and types without inferring a type from a drive target. Assignment targets
create no declarations here. Explicit sample aliases and their leaf facts remain
owned by `.3.3`; contextual AST and enum/rule namespace integration remain under
`.3.2.2` and `.3.2.3`. These helpers are unwired, and record authoring still refuses.

T1987 independently expects parsed symbolic/scalar/formal facts and imported
record identity, exact packed leaf ranges, signed/state properties, unresolved
shadows, known input roles and mutation isolation. Malformed declared widths,
duplicate port roles and invalid parameter names fail. Complete parsed actors
and scheduled objects, including emitted file bytes, remain unchanged after
projection. The first draft fixture incorrectly assumed an authored pin/storage
collision was accepted; the actual parser refused it. The corrected fixture
retains that refusal and the existing explicit-local pin-collision refusal.
Caller-supplied conflicting facts cannot erase a pin role, but their projection
establishes no new source admission or physical identity contract.

Reverify with guarded T1987/T1986/T1983/T1259/T1391. The competing borrowed-type,
placeholder-width and inferred-target interpretations fail the independent
scope/range witnesses and negative controls. Tracked producers, source controls
and tests make this preparation reproducible; no sample timing, new public
transport field, generated-child carrier or native HDL behavior is established.

Contextual preparation and first-touch caller-data correction are retained in
[0114](0114-record-value-validation-detaches-facts-before-reading.md). The original
scope mutation baseline followed an earlier projection; fresh copied facts now
have independent pre-projection controls. This qualification remains unwired.
