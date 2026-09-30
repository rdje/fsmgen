---
id: isf-aggregate-record-context-and-first-touch-validation
title: Record context gates detach facts before numeric validation
answers:
  - "how are selected record input AST contexts prepared without admission?"
  - "why can numeric validation change caller JSON scalar kinds without an assignment?"
  - "how is first-touch record declaration mutation reproduced and repaired?"
  - "can a scalar pin share an enum namespace name during record context validation?"
  - "how do aggregate enum and rule validators share declaration-root classification?"
  - "how are explicit record-leaf sample facts and private scalar type declarations prepared?"
  - "how do contextual record-input gates consume sampled scalar alias facts?"
  - "why did a malformed record-input selector turn a caller null entry into an empty map?"
  - "how do prepared record-leaf samples retain private scalar types in actual modules?"
  - "why did raw parent product comparisons fail after payload snapshot integration?"
  - "how are private record samples qualified against actual generated helpers and writers?"
  - "why did first-touch interface metadata validation change caller JSON scalar kinds?"
  - "how are complete record-leaf sample states and actual semantic scalar types qualified?"
  - "how do prepared record input member paths retain their declared clock domain?"
  - "why did inline and named drive bodies bypass declared domain ownership?"
  - "why can an unused parameterized drive break strict multi-domain replay?"
date: 2026-09-30
status: current
tags: [isf, record, ports, types, layout, writers, specforge]
evidence: t/1995-isf-record-port-domain-roots.t; t/1994-isf-record-port-sample-replay.t; perl/FSM/Support/ISFInterfacePortMetadata.pm; t/1983-isf-interface-port-metadata.t; t/1993-isf-record-port-sample-ownership.t; perl/FSM/Support/ISFRecordPortSamples.pm; perl/FSM/Scheduler/ISF/RecordSamples.pm; t/1992-isf-record-port-sample-carriers.t; t/1990-isf-record-port-sample-facts.t; t/1991-isf-record-port-sample-contexts.t; perl/FSM/Support/ISFRecordPortContexts.pm; perl/FSM/Support/ISFRecordPortScopes.pm; perl/FSM/Support/ISFRecordPortValues.pm; t/1989-isf-record-port-root-classification.t; t/1988-isf-record-port-context-gates.t; t/1987-isf-record-port-declaration-scopes.t; t/1986-isf-record-port-value-gates.t; t/1938-isf-formal-parent-products.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
---

# 0114 — Record value validation detaches facts before reading

- Date: 2026-09-30
- Status: qualified preparation; source admission remains pending
- Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.3.2.2`
- Parent contract: [0113](0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md)

## Context

Record inputs need contextual scalar reads and strict same-type copies before
their first authored source admission. Existing qualified value gates accept
resolved declaration facts, and detached scope preparation consumes parsed
actor/formal/local declarations and untyped drive parameters. This preparation
is still unwired; current scalar/storage authoring remains unchanged.

T1988's complete actor comparison exposed a mutation missed by the earlier
T1987 baseline: validation changed string widths into JSON numbers on fresh
copies of parsed facts. The earlier mutation baseline followed a previous
projection. Direct fresh parser controls stayed equal; the fresh copied
controls were RED. T1986 independently reproduced the same change in each
scope, reference and copy gate using explicitly string-valued widths.

## Decision

Detach caller-owned declaration/type/reference maps before numeric validation
or comparison. Perl numeric reads can change a scalar's flags and subsequent
JSON representation without an assignment to that scalar. A clone made after
validation cannot protect the original. `Storable::dclone` detaches before
reads and retains cycles for the existing closed type validator to reject;
core type/path/layout contracts remain unchanged.

Reproduce the mechanism independently:

```bash
perl -MJSON::PP -e 'my $j=JSON::PP->new->canonical; my $x={width=>"7"}; print $j->encode($x),"\n"; my $n=0+$x->{width}; print $j->encode($x),"\n";'
```

The outputs are `{"width":"7"}` then `{"width":7}`. This is a caller-data
mutation mechanism, not a new numeric value or public field contract.

`ISFRecordPortContexts` now prepares selected transaction set/update RHS,
when/while/until conditions, switch selectors/branches, nested bodies, rule
guards/assignments, named/inline drive bodies and named-drive actuals. Whole
record ports refuse scalar contexts, including negated and compact comparison
spellings. Port-involved whole assignments consume qualified recursive type
identity and role gates; input targets, bad paths, operator-position paths and
unsupported subaggregate uses refuse. Existing storage-only packed transfers
retain their original owner. Explicit leaf sampling, domain ownership and
first source admission remain separate prerequisites.

The gate validates references, not the complete source grammar. Unknown tokens,
operator/arity/static-value rules and enum/package member validation retain
their existing validators. State-active arguments denote states, and local/
parameter declaration names are not read operands. No successful preparatory
gate establishes that an otherwise invalid source is accepted.

A scalar pin may share an enum/package root name. Actual namespace roots remain
delegated unless the nearest aggregate or an explicitly shadowed outer
aggregate identifies a declaration path. The draft incorrectly rejected the
admitted enum token `mode.BUSY` when the actor had scalar input `mode`.
T1988 retains the repaired source control and the counterexample in which a
scalar formal must not borrow a same-named outer record's member via an enum.
Common aggregate/enum/rule root projection is prepared below; frontend integration remains pending.

## Qualification and limits

T1987's fresh copied actor/transaction/drive controls first reproduce the scalar
kind change; T1986's independently authored typed JSON does so for each value
gate. All preserve complete caller products after the repair. T1988 retains
independent selected AST cases and exact first-line negatives, same-type alias
copies, equal-width signed/state mismatches, input writes, formal shadows,
unknown-path controls, unsupported sampling/count/trigger contexts and enum
delegation. Complete currently admitted parser and scheduled products, including
emitted file bytes, remain unchanged. No oracle normalizes the caller product
before comparison.

```bash
scripts/run_with_ram_guard.sh -- prove -Iperl \
  t/1988-isf-record-port-context-gates.t \
  t/1987-isf-record-port-declaration-scopes.t \
  t/1986-isf-record-port-value-gates.t \
  t/1983-isf-interface-port-metadata.t \
  t/1259-isf-aggregate-storage-type-aliases.t t/1391-isf-local-variables.t
```

The competing borrowed-type, whole-record scalar, equal-width identity and
post-read detachment interpretations fail independent witnesses and negative
controls. Producers and permanent source/AST controls are tracked; ignored
logs are supplementary. This establishes unwired preparation and the repaired
caller-data contract, not new source/public transport admission, sample timing,
generated/domain carriers, external HDL execution or complete consumer delivery.

## Common root-classification preparation

SEM `.60.4.3.2.3.2.3` prepares `record_context_scope` and
`record_reference_root_kind` in the existing scope owner. One actual actor,
transaction or drive declaration selection supplies detached value roots,
resolved aggregate traversal roots, enum-exclusion roots, existing namespace
roots and actor rule-declaration roots. Transaction locals/formals and drive
parameters never become actor rule inputs. Rule roots also retain authored
storage signals, parameters/constants and legacy/named-domain clock/reset pins.

Nearest scalar or unresolved bindings remove an outer record from aggregate
traversal while keeping that outer name excluded from enum fallback. Scalar
pins that only share an enum/package root remain namespace tokens. Member
validity and enum/package resolution stay with their existing owners; root
classification does not turn an unknown member into a valid value.

The unwired contextual gate consumes this common projection instead of its
private namespace classifier. Existing frontend aggregate/enum/rule validators
remain unchanged until sampling/domain prerequisites permit source integration.
This is deliberate preparation, not record authoring or carrier admission.
T1989 independently expects every map and tests actual imported enum/type/
constant facts, named-domain system pins, nearest scalar/unresolved/drive shadows,
input roles, first-read caller JSON and separate output-map mutation isolation.
T1985 and T1982 qualify complete current public transport products and historical
domain reports, actual IAL0 carriers and generated HDL bytes except date. The
combined producer command and captured result are retained by this leaf in
the task evidence; no new authored record-port behavior is established.

## Explicit scalar-leaf sample facts

SEM `.60.4.3.2.3.3.1` prepares `ISFRecordPortSamples` without source or
carrier wiring. Actual transaction scopes resolve explicit entry/body/control
sample sources into detached scalar references, root-relative ranges and local
alias bindings. A record leaf retains scalar kind, width, signed property and
optional state model; chained explicit samples retain their record provenance.
Unknown/formal/enum facts remain unknown or delegated, and an explicit sample
alias masks outer declaration facts without borrowing a record layout. No
implicit sample or declaration is inferred from unrelated assignments.

Whole records/subaggregates, invalid members/items, input targets, existing
declaration collisions for private record-derived aliases and inconsistent
repeated sample types refuse. Repeated explicit captures of the same scalar
type may reuse their own alias. A record-derived alias cannot replace authored
local/formal/storage/output declarations or inherit their reset/type metadata.

A separate pure type-product boundary generates ordinary core scalar type ASTs,
type references and exact widths only for record-derived aliases. Private type
names are sorted and deterministically reserve existing names before suffixing
collisions. Signed and declared two/four-state wrappers are retained; no backend
state default, reset/default fact or hardware edge is introduced. The actual
public type resolver reconstructs these scalar properties independently.

T1990 retains an independently authored nine-bit nested layout, exact scalar
facts, imported aliases, formal/local/unresolved and namespace shadows, repeated
captures, declaration/role/path negatives and complete first-read copied JSON
isolation. Its first lexical-local fixture failed because the helper replaced
all clauses, removing the declaration; the repaired control retains that actual
local AST. A separate draft collision predicate trusted a previous sample alias
and permitted scalar-then-record sample reuse of authored storage `held`. An
isolated copy of that predicate makes the permanent declaration-collision
witness RED. The production gate retains the original declaration set, so no
intermediate sample scope can erase an authored collision. Existing entry/
piggyback/pre-data capture and malformed-source tests remain green. Complete current parsed/scheduled products stay unchanged. Native
structured authored record-input refusal is also retained at this boundary.

The task leaf retains the combined producing command and captured result.
Permanent source/AST witnesses falsify width-only, outer-type borrowing, shared
output-map and leaked reset/default interpretations. Producers are tracked;
ignored logs are supplementary. Typed private carrier integration and actual
IAL0 replay/timing remain `.3.3.2` and `.3.3.3`; first authored record admission
and independently supervised HDL behavior retain their later owners.

## Contextual sample consumption

SEM `.60.4.3.2.3.3.2.1` lets the unwired contextual gate consume the ordered
sample plan for supplied resolved record-input actors. Explicit entry/body/
control leaf samples receive local scalar alias bindings before contextual
reads/copies. Input roles, exact alias widths and scalar path refusals remain
qualified; sampling cannot replace an authored declaration or invent a record.

The consumer's `port_only` selection delegates existing storage-only aggregate
samples to their packed-width/inference owner; no new aggregate alias layout is
borrowed. Ordinary scalar, formal/local and namespace facts retain their existing
contracts. An unresolved forward sample chain which later names a record-derived
alias refuses rather than losing its newly resolved signed/state facts. Sample
collection does not reorder any capture state or permit a new clause placement.

T1991 covers entry, standalone, nested control and chained samples, independently
checks alias member/width/input/collision/type failures and nearest scalar/
unresolved/local masks, and preserves complete caller JSON. Existing packed
storage and enum samples remain delegated. An isolated exact predecessor
`ISFRecordPortContexts` from e0015db1314cfc0625609a358219c85a8d4cfa4b makes these
selected-sample controls RED: its first diagnostic refuses packet.count through
`_unsupported`. The new consumer passes without changing parser, scheduler or
module emission. Complete ordinary parsed/scheduled products and actual emitted
bytes remain equal; authored record-input sources still refuse.

Module widths/types, actual generated-helper/private alias ownership and full
replay/capture qualification remain the next children. The combined command and
result are retained in the task leaf; tracked predecessor history, current
producer and permanent AST controls retain re-derivation, falsification and
durability independently of ignored logs. No new public admission, backend
behavior or native HDL execution is established here.

## Selector shape validation precedes dereference

The `.3.3.2.1` draft selector read `type_spec` from an unchecked input entry.
A direct first-touch call returned false but changed caller `inputs` from
`[null]` to `[{}]`: Perl autovivified the undefined array entry. T1991's added
malformed-entry controls went RED for the mutation and unclassified raw hash
errors. This is distinct from the earlier numeric-flag mutation mechanism.

Reproduce autovivification independently:

```bash
perl -MJSON::PP -e 'my $j=JSON::PP->new->canonical; my $a=[undef]; print $j->encode($a),"\n"; my $unused=$a->[0]{type_spec}; print $j->encode($a),"\n";'
```

The outputs are `[null]` then `[{}]`. The repair validates interface/input-list
shape and each declaration map before its first dereference. It scans the full
list so a valid record prefix cannot conceal a malformed suffix. Absent
interfaces remain absent. Permanent first-touch controls preserve complete
caller JSON on both successful and refused selection; existing sample and
context controls remain qualified. At selector qualification, no public parser
or module emitter consumed it. Module preparation now follows below.

## Private scalar sample module carriers

SEM `.60.4.3.2.3.3.2.2` consumes the qualified port-only plan for supplied
resolved record-input actors in actual transaction and module preparation.
Known scalar alias widths enter the existing width map before data-operation
collectors. After transaction helpers are built, private sample declarations
retain the existing `sample_alias` role. The exact eleven transaction products
remain unchanged; no extra return product carries the new type information.

The module consumer runs after actual parent/child helpers and writers exist.
It checks alias ownership, declarations, widths and reset/default/type facts
before adding ordinary core scalar type ASTs and typed size references. Actual
type names are reserved deterministically. Explicit internal declarations keep
unused aliases private rather than allowing inference to create public pins.
Existing authored storage retains its reset; private samples inherit none.
Parent, generated transaction child and owning-domain modules use this same
consumer. Capture assignments, guards and state order retain their existing
lowering owner. Source record ports still refuse before scheduler preparation.

T1992 independently expects signed four-state and two-state bit declarations,
exact private widths/roles, reserved-name suffixing, unchanged capture states,
caller JSON and strict native CLI replay of actual emitted IAL0. Its generated
fixture initially used local `do`, which creates no child; documented `spawn`
and the emitted `worker.fsm` identity qualify the actual generated route.
An isolated exact LoweringIR predecessor from
`24d0abf84622ffaf6e665ae425e86f687968995c` makes these type/width/private-carrier
controls RED even though its untyped parent FSM passes strict parsing. Replay
alone cannot prove the expected scalar type, width or private role. The current
consumer passes these distinct assertions. Tracked producer, test and predecessor
history retain re-derivation, falsification and durability; ignored logs are
supplementary. Complete existing facade and historical carrier regressions
remain the no-regression oracle, with their command/result in the task leaf.

Actual generated-helper/cross-writer collision qualification remains `.3`;
complete replay/capture timing, domain-root validation and authored admission
retain their subsequent owners. No native HDL execution or complete backend/
consumer delivery is established by typed carrier preparation.

## Raw and finalized parent-product oracle calibration

The carrier slice's broader gate exposed P2 test drift in T1938. Its raw
`parent_activation_products` comparison expected the pre-snapshot payload mux
to equal finalized parent assignments. The exact 24d0 predecessor reproduces
the same failure at its original line 27: expected `guard.port` is replaced
by the qualified request/initial-state `guard.expr`. The existing accepted-
payload contract remains owned by decision 0109 and T1965/T1966, rather than
being reverted to satisfy this older comparator.

The repaired comparator selects complete `parent_payload_snapshot_products`
for transformed DTs and retains exact raw assignment comparisons elsewhere.
Independent literal witnesses require the requesting initial-state view,
entry-qualified capture and held view outside that window, for both exact and
case-folded rule names. Initial witness spelling was corrected to the actual
IR contract: `state_active` remains symbolic here and conjunctions flatten.
An isolated LoweringIR copy omitting only
`_apply_local_rule_payload_snapshots($ir, $payload_products)` makes both the
complete-product and independent capture/held witnesses RED. Production code
is unchanged for this repair. T1938 and the tracked transform retain a
reproducible oracle; no native HDL replay or new timing claim follows.

## Actual sample ownership and metadata first-touch repair

SEM `.60.4.3.2.3.3.2.3` qualifies actual private sample ownership through
T1993. Ordinary production modules supply the selected drive request/payload,
dynamic wait-counter and spawn start/done names, roles and declarations; the
controls do not guess helper prefixes. Reusing those names for a record-derived
sample refuses before emission. Module-local aliases cannot have multiple
record/ordinary sample owners or another transaction/rule writer. Repeated
same-owner captures share one private scalar type; unused aliases remain
internal. The same authored alias spelling can belong to separate parent and
generated-child modules, each with its own strict typed IAL0 carrier.

An isolated RecordSamples copy removes its transaction collision predicate,
multiple-record-owner predicate and module ownership-check block while retaining
plan and type installation. The permanent helper/cross-writer negatives go
RED; positive distinct-module owners still pass. The production ownership code
needed no change. Tracked producer and test retain the controls independently
of ignored logs. Complete replay/timing and source admission remain later work.

Fresh copied actors in T1993 separately expose P2 metadata mutation on refused
actual drive/spawn collisions. Original interface metadata widths are strings;
`ISFInterfacePortMetadata` numerically validates/rebuilds borrowed facts before
returning its detached output. Numeric reads change their subsequent JSON kinds.
A direct snapshot of `[{name=>"p",direction=>"input",width=>"3"}]` changes the
caller width from string to number, independently of scheduler/helper logic.
The pre-repair metadata producer is retained at
`53c7f9a5361fa0af96dcc94af7150218b3c22b14`. T1983's new first-touch controls go RED for capture and snapshot on valid
nested layouts and malformed suffixes. Earlier deep comparisons and baselines
after producer calls did not preserve the pre-read scalar-kind observation.

Both public metadata boundaries now clone their validated container before
reading any numeric member. The normalized result remains the independently
expected numeric layout, while caller facts stay unchanged on successful and
refused validation. Output edits remain detached. The earlier standalone Perl
numeric-read demonstration reproduces the mechanism independently. T1983 and
T1993 retain the missing first-touch cases; current complete public report
regressions retain the normalized-product contract. Their combined command and
captured result live in the task leaf. No metadata schema, authored record
admission, capture timing, backend state default or native HDL execution changes.


## Complete sample states and actual semantic replay

SEM `.60.4.3.2.3.3.3` closes sampling preparation through T1994 at production
boundary `401aea31d1159e4136c3903304373f6ea43b099f`. The reference parses
admitted scalar sample sources. A detached preparatory actor replaces storage
with a supplied resolved record input and substitutes only explicit sample
operands with nested record leaves. Expected complete states change only those
capture RHS values and retained control-clause sample operands. Every other
assignment, guard, transition and state field compares exactly. The draft's
authored storage-leaf sampling reference was invalid under the current parser;
correcting the reference did not widen that source grammar.

Entry, preceding await/drive samples, dedicated pre-data capture and nested
when/while/until/repeat/switch samples preserve their existing structures.
Independent literal witnesses require the start-qualified entry assignment,
the existing unguarded capture in a pending await state and pre-data successor
ordering. The entry assignment is selected by its alias, rather than assuming
a fixed array position before other helper assignments. This qualification
compares capture-state structure; it does not claim observed HDL timing.

Actual emitted IAL0 runs through native strict `--emit-semantic-json`. Exact
independent leaf specs must agree with both `symbol_contract.types` and private
`forward_ir.structural_rtl_ir.nets[].declared_type_spec`, alongside successful
replay, source identity and no public alias pins. Real imported nested leaves
and renamed nearest scalar formals retain their distinct contracts. Whole
input snapshots, invalid members and scalar-formal member borrowing refuse
with precise first diagnostics while complete caller JSON remains unchanged.

For a reproducible known-bad control, copy that production LoweringIR module
into an isolated repository-local Perl include tree. Immediately after `_ir_on`
constructs `@assignments` from `_inline_on_samples`, insert:

```perl
delete $_->{guard} for grep { $_->{rhs} =~ /\Apacket\./ } @assignments;
```

Run T1994 with that include tree before `-Iperl` and preload
`-MFSM::Scheduler::ISF::LoweringIR`. Complete entry/imported state comparisons
and the independent entry-guard witness go RED, while native semantic replay
and scalar-type witnesses stay green. This distinguishes structural guard
loss from a merely parseable, correctly typed carrier. The current production
module needs no repair. Tracked tests, module history and this mutation recipe
retain re-derivation, falsification and durability; ignored logs supplement
them. Domain preparation and authored admission remain subsequent owners.
Native HDL execution and full frontend/backend/consumer delivery remain
unqualified by this preparation slice.


## Record/formal path-domain preparation — 2026-09-30

SEM `.60.4.3.2.3.4.2` qualifies supplied resolved record-input ownership before
source admission. At `8698b1a897752036b875c27336306582665dc4e3`, T1995's
foreign nested member, scalar slice, list-leaf, control, rule, drive-actual and
explicit sample controls go RED: public scheduler lowering accepts the foreign
path with no diagnostic. `_validate_domain_signal_access` admitted dotted paths
only for storage roots; record inputs were absent from that path boundary.
Whole-root copies already refused their foreign declared domain.

The domain map now marks only finalized record input roots for member traversal.
Indexed scalar lookup retains nearest formal ownership, and dotted scalar
namespace names remain delegated. T1995 independently validates each selected
leaf context, then requires the exact original path, access and declared domains
in the first lowering diagnostic. Complete fresh caller JSON stays unchanged.
Same-domain nested reads and copies, real imported record aliases, renamed
nearest scalar formals and foreign scalar pins sharing enum/package names
strictly replay every actual domain and top IAL0 carrier. Declaration snapshots
retain the selected input in its actual owning domain. This is preparatory
actor qualification; authored record ports remain refused.

The first positive fixture attempted implicit scalar widening and guessed a
nested input/output metadata shape. Native strict diagnostics established the
width mismatch; width-aligned assignments and the actual flat declaration
array repaired the fixture. Its named-drive declaration separately exposed
the admitted-source defect retained below rather than being dismissed as a
fixture problem. Current domain-path qualification isolates that pending defect
by declaring the named drive only in its actual drive-call control.

## Existing inline and named-drive domain bypass repairs

T1995's inline control still failed after the record-root repair. Actual
`_ir_drive` emits assignments beginning at clause index one when that first
operand is an array, but domain validation always began at index two. The
first read/write assignment bypassed ownership. Used named-drive bodies were
never validated either; only their call arguments and multiple-domain reuse
were checked. Ordinary scalar-only parser/scheduler probes accepted core
inline/named reads of aux `data` and writes of aux `remote`. New T1920 first-line
storage read/write controls go RED for both forms before the repair.

Inline domain validation now uses the same admitted assignment boundary as
emission. After drive-use collection and reuse admission, each used named body
checks its targets and expressions in its actual activation-site domain. Its
scalar parameter names mask outer declarations with that domain. Unused bodies
have no activation owner and are not checked by this new call-site gate.
Nearest parameter shadows, nested record input body reads, same-domain paths
and explicit crossing contracts pass. T1985 adds complete native/API/newline
check and semantic diagnostic parity, existing schedule transport refusal,
no successful declaration/partial schedule products and unchanged source bytes
for admitted inline/named foreign read/write sources.

Re-derive with guarded T1995/T1920/T1985 and the owning leaf's cohort. Falsification
is the captured pre-repair RED domain/drive controls, independent exact domain
messages, nearest bindings and foreign scalar namespace witnesses; durability
is these tracked tests and the immutable production predecessor above. These
are source-validation repairs and preparatory path ownership, not native HDL
execution or complete frontend/backend/consumer record delivery.

The scalar namespace distinction has an observed known-bad control. Copy this
leaf's tracked LoweringIR into an isolated repository-local include tree and
replace only the resolved-record condition assigning `record_root` with
`if 1;`. Run T1995 with that include tree before `-Iperl`, preloading
`-MFSM::Scheduler::ISF::LoweringIR`. It exits nonzero on the valid `mode.ON`
constant with a false aux-to-core clock-domain violation. The production
condition passes the complete enum and imported-package controls. Marking
every scalar input as a record root is therefore not a valid domain repair.

## Owned unused-drive domain carrier defect

SEM `.60.4.3.2.3.4.3` owns the separate P2 strict-replay defect, scheduled
immediately after `.4.2` and before authored record input admission. This
ordinary admitted scalar source reproduces it without record-port preparation:

```lisp
(actor unused_drive_domains
 (clock-domains (domain core (clock clk) :default) (domain aux (clock aux_clk)))
 (interface (input start) (input data (width 8)) (output seen (width 8)) (output done))
 (drive (publish value) (seen value))
 (transaction main (on start) (set seen data) (complete done)))
```

Save it under a repository-local path and run native
`./bin/fsmgen --quiet --strict --check --json PATH`. At the predecessor above,
success is false and no generated output is emitted. The diagnostic names
undeclared top input `publish_value`: core's child input has width 8 while
aux's has width 1, blocking consistent inference. The drive is unused. The
same cause breaks positive prepared top replay, independently of record types.
DomainSource currently copies all drive definitions into each local actor,
but responsible helper/width production and its verified repair remain that
next leaf. Ignored probe JSON/logs supplement this tracked exact source and
version identity; no fix is claimed here.
