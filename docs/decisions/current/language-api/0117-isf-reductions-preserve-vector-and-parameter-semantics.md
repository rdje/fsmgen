---
id: isf-reduction-and-group-contract
title: ISF reductions preserve vector and parameter semantics
answers:
  - "what syntax and bit order are selected for SPECFORGE byte-group reductions?"
  - "what must be preserved before parameterized reductions can ship?"
  - "what reduction width groundwork is implemented?"
  - "how are declared reduction records prepared without source admission?"
  - "why do reductions preserve delegated storage sample declarations?"
  - "why did admitted reductions fail when transaction formals were present?"
  - "why do sampled clock/reset reductions need declared carrier widths?"
  - "why do direct transaction count parameters mask runtime reductions?"
  - "why did standalone static counts look like cross-domain wire reads?"
  - "why did qualified static names borrow record fields in reduction preview?"
  - "why did generated intermediate names overwrite declared inputs?"
  - "how are reduction values tied to actual write enables?"
  - "which unary generation profiles are qualified and which shapes refuse?"
  - "why did --quiet print ISF and PPIF progress banners?"
  - "why did traced check semantic or schedule reports contain non-JSON stdout?"
  - "which corpus phases and public queries cover maintained unary reductions?"
  - "why did corpus accounting fail after unary reduction admission?"
  - "how can failed reduction predecessor tests load current modules?"
  - "how is the complete retained reduction replay evidence set accounted?"
date: 2026-10-22
status: current
tags: [isf, reductions, specforge, parameters]
evidence: docs/audits/reduction-qualified-static-scopes-20261022.json.gz; docs/audits/domain-static-count-scopes-20261022.json.gz; docs/audits/reduction-parameter-scopes-20261022.json.gz; docs/audits/reduction-timing-sample-scopes-20261022.json.gz; docs/audits/specforge-reduction-intake-20261021/packet.json; docs/audits/unary-reduction-source-integration-20261022.json.gz; docs/tasks/ISF-REDUCTION-DELIVERY.md; perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm; perl/FSM/Scheduler/ISF/Emitter/FSM.pm; docs/audits/unary-corpus-public-products-20261022.json.gz; t/2089-unary-reduction-corpus-public-closure.t; docs/audits/reduction-replay-identity-20261022.json.gz; docs/audits/reduction-replay-activity-20261022.json.gz
---
# 0117 — ISF reductions preserve vector and parameter semantics

- Type: language and lowering contract
- Status: selected; unary source integration implemented; qualification continues
- Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.92.1`

## Context

SPECFORGE request `.12` requires scalar reductions and grouped reductions over
parameter-dependent widths. Its retained source and current refusals are in
`docs/audits/specforge-reduction-intake-20261021/`. The illustrative
`(! (^ DATA))` means inversion of a whole-vector parity bit; it cannot mean a
vector of independently inverted byte parities.

At intake the shared expression builder required multiple operands for `^`,
`&` and `|`. ISF preserves expressions in scheduled IAL0 text, but emitting a
numeric default width loses its dependency. At intake, unary AST nodes and their
width consumers also needed explicit reduction result semantics. Passing a
source check cannot establish HDL behavior or safe external parameter overrides.

## Decision

### Unary reductions

Select `(^ X)`, `(& X)` and `(| X)`: reduce every bit of X to an unsigned
single-bit result. X is a declared positive-width packed scalar signal, its
supported scalar field, a legal static slice, or a bit selection. A bit reduces
to itself. Reuse existing declared types, path bounds and lexical/domain rules.
Reject aggregate roots, strings, unresolved/unknown signals, parameter values,
unsized numbers and unsupported expression operands with the operand and
source context identified. Do not infer a missing declaration from a reduction.
The existing normalized aliases `xor`, `and`, `or` have the same arity-dependent
meaning. Multiple operands retain their current behavior and association;
negated multi-operand forms and logical `!` retain their existing semantics.

### Grouped reductions

Select `(reduce-groups OP X N)`, with literal OP one of `^`, `&`, `|` and N a
positive decimal integer literal. The packed scalar operand contract is the
same as for unary reduction. For operand width W, the result width is
`ceil(W/N)`. Result bit i reduces the operand positions starting at `N*i`,
through `min(W-1, N*i+N-1)`. Positions are relative to X's packed value, so a
slice starts at its own least significant bit. The final group may be short;
no padding bit changes the result. N greater than W produces a single group.
Invalid operators, nonliteral/nonpositive N and invalid operands fail closed.

Assignment targets must have exactly the grouped result width under strict
checking. Diagnostics name the target width and derived group count. Nested
uses retain the grouped result width; a logical `!` over that vector still
produces a single Boolean, never elementwise odd parity.

Select optional `(~ X)` as width-preserving bitwise inversion, independently
qualified after required unary semantics. It may invert a grouped result.
Without it, required grouped reduction remains usable; optional inversion must
not block required delivery. No reinterpretation of `!` is permitted.

### Parameters and lowering

Preserve authored width dependencies separately from resolved defaults through
ISF parsing, LoweringIR, IAL0, semantic metadata and HDL. Never reconstruct a
dependency from equal numeric widths. Coordinate generic-port-width ownership
`.33.3` and derived-width ownership `.32.3`; do not create a second evaluator.
An external HDL override must resize the operand, result, associated registers,
intermediates, constants and group loop together. Independent DATA_WIDTH and
DATA_BYTES parameters remain legal only when their values satisfy the group
count relation. Reject invalid source/use-site settings; emit supported
elaboration-time guards for externally overridden relationships. Unsupported
backend/profile combinations fail closed before claiming a valid artifact.

Use canonical IAL0 expressions and typed AST semantics, rather than generated
HDL text replacement or a default-width unroll. Group emission must operate on
the elaborated width and preserve the short tail. Actual default/override HDL
behavior and width declarations require independent qualification.

### Public reports and supported profiles

Add a detached `reductions` inventory to successful ISF schedule reports and
`source.reductions` to successful check/semantic reports when reductions occur.
Entries name source owner/context, `kind` (`unary` or `grouped`), `operator`,
authored `operand`, resolved `operand_width` and `result_width`; grouped entries
also name `group_size` and `group_count`. Preserve a declared width dependency
as `operand_width_source` where applicable. These resolved numbers describe
the selected parameter environment, not every possible external instantiation.
Do not leak parser/AST/private IR objects or invent entries in failed or
unrelated source reports. API, real newline MCP and capability contracts must
agree with native reports. Normalized expression reports retain the actual
operator and result width.

Qualify each existing HDL backend/profile independently. SystemVerilog is the
first delivery target; other profiles retain an explicit refusal until their
expression and parameter contracts are verified. A parser success, generated
carrier, lint result or sibling emitter option is not runtime qualification.

Preserve existing bounded generation contracts while qualifying new source
forms. The fixed-width generation cohort below verifies compatibility Verilog
text and the existing direct-VHDL fold subset; it does not qualify external
parameter overrides, analyzers or runtime. Unsupported shapes retain refusals.

### Delivery order and evidence

`docs/tasks/ISF-REDUCTION-DELIVERY.md` owns bounded implementation slices under
SEM `.92`. Deliver unary semantics independently. Then preserve generic widths,
qualify overrides and legality, and implement grouped reductions. Required
SPECFORGE delivery stays open until R1–R3 all qualify. Optional inversion has
its own acceptance boundary. Keep corpus, public discovery, book, feedback and
roadmap intent aligned in each slice.

Re-derivation uses retained exact caller inputs and native check/schedule/
semantic/carrier products. Falsification uses independently computed scalar
truth tables, group order/short-tail/width mismatch controls, actual HDL
parameter overrides and unchanged binary controls. Durability is tracked
sources, corpus/tests, decision, task evidence and per-slice Git commits.
Runtime and implementation evidence are missing at contract selection.
Publication additionally requires the existing full-CI and exact-SHA hosted
qualification; SPECFORGE separately owns pin/bundle regeneration and integration.

## Width prerequisite

`ISF-REDUCTION-DELIVERY.1.1` prepares scalar reduction width inference across
Core/runtime/substituted AST consumers, distinct named intermediates and
operand-preserving context propagation. The corrected regression fails against
exact predecessor modules and passes against the repair, alongside existing
expression/backend-text controls. Its complete dated audit is
`docs/audits/unary-reduction-width-foundation-20261021.json`.

Reverify with `scripts/run_with_ram_guard.sh -- prove -Iperl t/2074-unary-reduction-width-foundation.t`.
That prerequisite retained source refusal; the integration below opens declared
unary forms. Full source/profile and HDL behavior qualification remain successors.

## Declared-expression record prerequisite

`ISF-REDUCTION-DELIVERY.1.2.1` prepares detached unary records from selected
expression payloads and existing declaration/path/sample facts. Expression
preorder preserves separate occurrences and canonicalizes the bitwise aliases.
Source clauses and assignment pairs are not expression payloads: their heads
can be signal names. The integrating caller must select contexts and bind
owner/scope to source. Structural snapshots alone do not attest provenance.
Lost authored width dependencies remain omitted rather than inferred.

Real parsed caller rules, scalar paths, local/sample and drive scopes plus
hostile operand/schema and mutation controls qualify the private producer.
The first draft admitted an invalid owner through a dropped regex predicate;
scalar predicates and exact helper arity apply decision 0113. Detaching before
numeric reads follows 0114. Complete draft, diagnosis and checks remain in
`docs/audits/reduction-record-preparation-20261022.json`.
Reverify with `scripts/run_with_ram_guard.sh -- prove -Iperl t/2075-isf-reduction-record-preparation.t`.
No source, public-report or runtime admission is claimed by this preparation.

## Unary source integration

`ISF-REDUCTION-DELIVERY.1.2.2` connects explicit declaration/path validation,
canonical IAL0 unary parsing and detached optional schedule/check/semantic
records. Source selection visits expression positions, preserving owner/context
and expression order; an assignment target named `xor` is not an operator.
Static values mask same-named wires consistently with shared frontend resolution.
A scalar sample retains its explicit private declaration and known type/width
before its reduction is read by the canonical frontend. No inferred declaration
or width fallback admits an unknown operand. The reduction consumer uses the
existing port-only sample plan and leaves its unresolved/delegated samples
masked. Whole packed-storage captures and their sample chains retain the
legacy inference owner instead of receiving scalar declarations merely because
an unrelated reduction occurs. Record-port whole samples remain refused.
Reverify with `scripts/run_with_ram_guard.sh -- prove -Iperl t/2077-isf-reduction-delegated-samples.t`.

Formal operand rewriting must share canonical normalization and unary reduction
classification. Its former family-only arity check rejected an already admitted
reduction whenever direct formals activated source rewriting. T2078 exercises
all canonical/alias spellings, nested use, distinct physical formal widths and
authored source inventories through actual carriers and native/API/newline
products. The detached formal report view re-derives reduction records from its
original preparation actor: LoweringIR must retain physical operand identities
for execution, while source reports retain authored spellings. The initial
arity-only repair exposed this second omission rather than qualifying the
generated spelling as authored provenance. It preserves unrelated arity and
role controls. Reverify with
`scripts/run_with_ram_guard.sh -- prove -Iperl t/2078-isf-reduction-formal-arity.t`.
The independent existing mixed-record/private-formal write refusal is owned by
`.8`; this arity repair does not broaden source write roles.

Declared timing samples need the same scalar facts in source and carriers.
The record-port sample plan intentionally omits timing roots; the reduction
consumer can still resolve a known scalar root in its already declared scope.
Qualified namespaces, delegated aggregates and unknown/static masks remain
outside this fallback. Sample chains retain the resolved scalar facts.
`record_timing_scope` shares actual clock/reset declarations with source and
width consumers, preserving nearer declarations and unresolved masks without
inventing an absent reset. Reduced-actor width propagation projects actual
nearest scalar declarations before sample chains; report numbers supply no
width evidence. The existing feature boundary preserves ordinary actors.
The first source repair exposed a second RED: missing sample declarations made
actual canonical replay refuse the timing operand. T2079 binds both stages to
real sources/carriers, exact sample storage widths/roles, no phantom timing
storage, complete native/API/newline products and named/no-reset/nearest-mask
controls. Reverify with
`scripts/run_with_ram_guard.sh -- prove -Iperl t/2079-isf-reduction-timing-samples.t`.
This scoped source qualification does not close broader source/profile/corpus,
external HDL runtime, generic groups or required R1-R3 publication.


Unary AST, canonical serializers and the executed enable-graph capture renderer
group both the operand and expression. Direct VHDL recognizes exactly one
balanced operand wrapper through its existing bounded fold path. The real
negation predicate must also classify Core/runtime/substituted reductions as
one bit, consistently with exact width inference; otherwise it emits a redundant
compound NOR that the VHDL converter refuses. Source negation keeps its Boolean
meaning. Other unary behavior stays unchanged; the independent private scalar
complement classifier gap is P2-owned under `.7.1` after unary delivery. Direct VHDL still refuses range slices; this
integration does not qualify external VHDL execution under decision 0023.
`isf/unary_reductions.isf` is the supported source fixture; T2076 binds literal
source records to native/API/newline products and actual generated IAL0.
Broader source/profile/corpus coverage and actual HDL runtime remain `.1.2.3`
through `.1.4`; generic widths/groups and publication remain required. This
source milestone does not close R1–R3 or unblock SPECFORGE `.46.c`.

## Direct count-parameter and runtime expression scopes

`ISF-REDUCTION-DELIVERY.1.2.3.1.2.2.2.1` retains paired native sources and
actual source preparation/declared-scope facts in
`docs/audits/reduction-direct-count-scope-diagnosis-20261022.json.gz`.
A direct transaction parameter `count=2` controls standalone waits while the
runtime `count` is a declared actor pin or private formal. Canonical T1936 and
current preparation exclude that parameter from runtime static symbols, but
include it in standalone count symbols. Ordinary reads strict-check; unary
reductions formerly refused because `_without_static_values` masked every
transaction parameter regardless of placement/expression context.

`LoweringIR::expression_static_scopes` now detaches source before querying the
existing live generated-child classifier and canonical static declarations.
Formal preparation and the query share transaction expression-scope composition;
standalone count scopes remain separate. Reduction capture queries these facts
lazily, avoiding a Parser/LoweringIR compile-time cycle. Generated-child capture
selects its transaction from the full source actor instead of discarding the
activation graph that establishes parameter ownership. Qualified static paths
remain under their existing namespace/path validator, not invented root masks.

T2080 checks declared runtime widths, static waits, generated/static/unknown
refusals, canonical live/zero-pruned placement, domains, caller-kind isolation
and actual source/carrier/native/API/newline products. Reverify with
`scripts/run_with_ram_guard.sh -- prove -Iperl t/2080-isf-reduction-parameter-scopes.t`.
This bounded repair does not close remaining unary qualification, runtime,
generic groups or publication.
The domain probe separately reproduced an ordinary-source defect: after formal
rewriting, domain validation treated standalone static counts as reads of a
same-named foreign-domain actor wire. `.9` shares the unchanged static branch of
`_wait_count_spec` through `_static_wait_count_spec`; repeat domain validation
reuses its existing static count resolver. Only standalone count positions use
these facts. Expression counts, guards and loop bodies keep runtime ownership
checks. T2081 binds exact source scopes, actual domain report/state producers,
strict complete carrier bundles and native/API/newline equality, with hostile
runtime-crossing controls. Generated artifacts are joined through their actual
`scheduled_fsm` identities, never guessed from logical domain spellings.
Reverify with `scripts/run_with_ram_guard.sh -- prove -Iperl t/2081-isf-domain-static-count-scope.t`.

Multi-domain report aggregation must use the detached original-source view for
both domain-local and top-level inventories. A physical parent IR supplies
execution identities, not authored operand spellings. Complete transport parity
alone cannot detect this error: every transport can repeat the same physical
name. The independent authored inventory and executed report-call probe bind
the missing top-level projection while checking IR/source/carrier isolation.

Predecessor replay must establish the loaded module identity, not just retain a
command line. The earlier count-scope audit put `-Iperl` before its overlay and
therefore loaded current code; its exact-predecessor identity claim is invalid.
The corrected overlay-first INC/helper probe plus native c51 replay reproduce
the ordinary domain refusal. The final unchanged T2081 also fails against the
independently inspected 300b23660 predecessor. Preserve the old receipt and this
explicit correction; matching exit status never repairs a wrong source identity.

## Qualified static operand identity

The declared-value scope accepts declaration roots. Filtering qualified static
keys from that root projection therefore cannot by itself preserve namespace
ownership: an enum/package token can also name a colliding record member.
Actual canonical membership and declared/masked scopes demonstrated the false
field width before native carrier validation rejected the same static operand.
Schedule preview had incorrectly advertised success and signal provenance.

Source capture now passes the canonical transaction or actor static set into
expression capture. Exact membership, including a selected descendant of a
known static value, is checked before declared-field resolution. This is a
membership query over existing canonical facts; declaration paths and bounds
remain owned by the common value resolver. Unrelated fields stay declared.
Namespace maps are sets: marker values are not read or coerced. Private callers
without a static namespace retain their existing declared-scope behavior;
source callers supply actual canonical facts, not a copied report inventory.

T2082 retains the genuine native/preview discrepancy, actual parsed scopes,
caller-kind checks, source-owner/alias and selection controls, and complete
native/API/newline refusal products. Reverify with
`scripts/run_with_ram_guard.sh -- prove -Iperl t/2082-isf-reduction-static-namespaces.t`.
This repair adds no static/literal reduction admission and does not close the
remaining operand/type/carrier cohort, full unary runtime, groups or publication.

## Generated intermediate identity

Capture qualification found an ordinary parser defect independent of unary
reductions. A declared input whose name matched an intermediate candidate was
reused by `register_signal`, promoted to an intermediate and given a driving
AST. Native success concealed duplicate HDL declarations/internal input drivers
and missing semantic input records. The original sources, complete streams and
executed ordinary trace retain in
`docs/audits/intermediate-namespace-first-20261022.json.gz`.

Intermediate allocation now probes the SignalManager's existing declaration
namespaces before registration. Membership uses keys, including zero-valued
symbols, without resolving values or changing caller data. Occupied suffixes
are skipped; normal signal refinement remains unchanged. Noncolliding helper
names keep their existing counter sequence. This shared allocator also serves
computed test selectors; no generated HDL text rewriting is used.

Reverify with `scripts/run_with_ram_guard.sh -- prove -Iperl t/2085-parser-intermediate-namespace.t`.
Its unchanged settled RED-to-GREEN comparison and independent literal input,
object/driver and real mux checks falsify accidental aliasing. Renamed controls
retain complete native reports and generated SV except its date banner.
Tracked tests, dated audits and Git retain durability. External HDL runtime and
public corpus/profile qualification stay separately owned. Capture results follow.

## Executed capture qualification

`ISF-REDUCTION-DELIVERY.1.2.3.2.2` joins independently authored operator/operand
and width expectations to actual output-drive families, generated helper
definitions, output mux arms and continuous enable chains. State constants are
read from generated declarations; readable RHS labels alone are not identity.
Repeated writes retain XOR, AND, OR and authored scalar inputs independently.
Nested concatenation keeps scalar reductions and logical negation at their
declared result widths; ordinary vector XOR and unrolled parity stay distinct.

T2086 qualifies actual source/carriers, complete native/API/newline products
and caller data. A real source control replaces the first XOR with AND: native
validation accepts that well-formed source, while the independent value/enable
oracle rejects its first write. An operand with only its low bit set separates
the two intended values. First complete sources/products are retained in
`docs/audits/reduction-capture-first-20261022.json.gz`.
Reverify with `scripts/run_with_ram_guard.sh -- prove -Iperl t/2086-isf-reduction-capture-identity.t`.
These checks establish source/generated-text associations, not HDL execution.
Public corpus/profile closure and the fixed runtime witness remain successors.

## Source target-profile qualification

T2087 joins actual ISF and canonical carriers to every public language/alias.
Independent output widths and physical write values qualify the fixed-width
SystemVerilog and compatibility-Verilog cohort. Existing direct VHDL scalar
and static-bit reductions retain identity; declared vectors use required
`std_logic` fold helpers with the selected neutral value, operator and range.
The tested negation/concatenation forms retain these results. Range slices and
ordinary unrolled indexed-bit XOR chains retain their precise scaffold refusals;
existing destinations stay byte-exact and absent destinations remain absent.
Target-neutral schedules and complete native/facade products retain their roles.

The first draft oracle incorrectly required blanket non-SystemVerilog refusal.
Canonical VHDL readiness/lowering contracts already preserve bounded generation
and withhold external execution. Its complete RED is retained; correcting that
oracle is not a compiler repair. Wrong actual mux values and fold neutral values
or operators are rejected independently. Reverify with
`scripts/run_with_ram_guard.sh -- prove -Iperl t/2087-unary-reduction-target-profiles.t`.
No backend expression code changes or compiler/runtime claims follow.

## Quiet intent generation and traced reports

Profile qualification then found genuine CLI defects. Intent headings and
`Wrote:` announcements checked machine mode without consistently checking
quiet. Trace-file routing started after intent lowering, so early events reached
stdout and traced check/semantic/schedule reports became undecodable; their
early-return paths could leave the requested trace file absent.

`bin/fsmgen` now derives one informational-output predicate and routes requested
trace files before source lookup/lowering. Help/capability fast paths and
argument validation keep their order. Quiet suppresses informational notices;
verbose messages, human errors, generated artifacts and machine products retain
their contracts. The unchanged settled T2088 RED-to-GREEN comparison covers
actual ISF, single-channel PPIF and bundle paths, both quiet aliases, complete
HDL/lowered bytes, early trace delivery and whole traced/untraced machine reports.
Reverify with `scripts/run_with_ram_guard.sh -- prove -Iperl t/2088-cli-quiet-intent-progress.t`.
Separate immutable wrong-oracle, first quiet and settled trace epochs retain
the distinction between qualification and the actual CLI repair. Earlier
first-quiet trace-file content was missing; the superseding epoch retains full
available trace files and records absent files explicitly. Raw-root byte
reconstruction and a whole original worktree snapshot remain missing.

## Maintained unary corpus and discovery

`feature.isf_unary_reductions` already owns `isf/unary_reductions.isf`; no new
membership is needed. Its internal supported phases now distinguish parse,
typecheck, lowering, check, semantic/schedule reports and fixed-width
SystemVerilog/Verilog generation from VHDL range generation, compilation,
simulation, X/Z execution, external parameter overrides, grouped reductions
and complete consumer delivery. Internal phase/nonclaim arrays survive cohort
selection without extending the sanitized public manifest/catalog schema.

T2089 preserves complete catalog, every supported source/version/query cohort,
all catalog source bytes, whole native/API/newline discovery and actual
maintained success/refusal products. Independently literal declarations and
ordered owner/operator/operand/width records reject shared transport corruption,
including JSON-kind changes. An invalid declared operand keeps complete failed
check/semantic products without successful source snapshots; schedule retains
its existing RPC error boundary. Full discovery records applicability, not
execution of every source query. The source target-profile and caller/capture
qualifications above retain their separately bounded evidence.

Reverify with `scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/2089-unary-reduction-corpus-public-closure.t t/248-regression-corpus-accounting.t`.
The immutable draft receipts preserve capture-regex and discovery-schema oracle
corrections separately from actual catalog metadata qualification. A draft also
assumed the wrong native schedule status and RPC code; the observed refusal
boundary is retained unchanged. The first caller probe is rejected by the
test runner's safe-identity gate before source execution; its settled successor
uses exact canonical retained inputs, without relaxing that gate.

The broader preservation run finds stale T248 accounting literals: commit
`21843f970e94f91cbe3a2b2bd3226a602a42ade1` added exactly the unary owner but
left the pre-admission supported/strict census expectations. Full retained
allocation and removal of only that exact owner independently explain both
differences. The minimal test correction retains every membership assertion
and passes with the width/record foundations. No parser/backend repair or new
runtime maturity follows from this corpus slice.

## Declared predecessor payload identities

`ISF-REDUCTION-DELIVERY.10.1` qualifies the retained corrected width wrapper
and its separately strengthened final variant. Their hoisted native directory
loads the declared predecessor blobs; both `%INC` file hashes and compiled
method source locations match. Other dependencies are observed current source,
so this establishes the named-module comparison, not a complete historical build.
The root-first control loads current width methods and those width groups pass.
Its historical source-refusal assertions still fail because unary admission was
deliberately opened later. The different nonzero exits retain different causes.

The count audit's existing correction remains intact. Fresh source-only loads
qualify its declared historical lowerers and coherent dependencies against Git;
the root-first control selects current code. Prepared module snapshots, actual
before-edit worktree probes, captured extension-help examples and reconstructed
predecessor launches remain separate evidence classes. No historical HIAL,
compiler, simulator or native count workload is replayed. Full original loaded
footprints and environments remain unrecorded; new observations cannot restore
them retroactively.

The frozen filename-family census and its explicit selectors pass the read-only
verifier in `docs/audits/reduction-replay-identity-verify-20261022.py`, with full
source observations retained in `docs/audits/reduction-replay-identity-20261022.json.gz`.
Reverify with `scripts/run_with_ram_guard.sh -- python3 -B docs/audits/reduction-replay-identity-verify-20261022.py`.
The independent `.10.2` census derives evidence from work-unit Git commits and
all changed artifact paths, then joins the core records and canonical intake.
It accounts additional CLI/corpus receipts and the earlier static QA verifier.
Their library-root hints are ordinary repository/test roots, captured extension
help, task narratives or declaration metadata. None establishes an additional
reconstructed predecessor launch. Before-edit and supplied source observations
remain distinct from qualified reconstruction; every original stays byte-exact.

Reverify the complete join with `scripts/run_with_ram_guard.sh -- python3 -B docs/audits/reduction-replay-activity-verify-20261022.py`.
That read-only verifier also runs the core verifier and rejects omitted work
units/artifacts or a fabricated execution class. Full observations are retained
in `docs/audits/reduction-replay-activity-20261022.json.gz`. The retained-evidence
identity audit is closed within these explicit historical limits. The fixed
HDL witness/admission and actual runtime qualification remain successors.

## Fixed unary runtime witness preparation

`ISF-REDUCTION-DELIVERY.1.3.1` fixes the source, public-pin bench, vector table
and T2090 before HDL execution. The source covers declared vector/scalar/bit/
slice operators, odd parity, nested results, binary/unrolled controls and a
helper-like external input. Golden production uses population counts; the
independent oracle walks bits and packs strings without wide-integer assumptions. Every stored input/result bit and hostile missing,
substituted or changed-vector controls are checked.

The exact source and actual carrier emit identical Verilog-family HDL except
for date banners. A real source counterfactual changes only unary XOR to AND.
The planned runtime bench compares complete public pins, repeats the fixed
sweep and checks disabled writes/reset. Process completion and semantic result
are distinct: positives require complete PASS/hold/reset markers; the wrong
source must report its distinguishing value mismatch with no PASS.

The fixed stage membership is both Verilog-family positives and the wrong
SystemVerilog source, through unchanged VerilatorRuntime compile/runtime APIs.
T2090 defaults to source/generation checks with an explicit unadmitted runtime
skip. This is preparation, not simulation qualification. Fresh target-specific
observer/admission qualification under .1.3.2 precedes .1.4 execution. No spent
admission, historical workload, X/Z or external-override claim is introduced.
Reverify source-only preparation with `scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/2090-isf-unary-reduction-runtime.t`.
