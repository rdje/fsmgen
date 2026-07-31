# VIAL Source And VIALSemanticIR Version-1 Contract

Date: 2026-07-31
Owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.2`
Status: bounded semantic profile implemented by `.3`; `.10.1` adds the public
normal/terse source-tooling projection without changing typed meaning

## Outcome

VIAL version 1 is one public, reviewable `.vial` S-expression language with a
dedicated span-aware parser. Its first implementation profile is
`core_directed_single_clock_v1`: typed declarations and DUT references, two
bounded directed scenarios, deterministic fibers, checking, a deterministic
model, a bounded scoreboard, explicit coverage, one bounded fault, and one
stable random decision. The profile is semantic-intent only; it does not bind
a HIAL bridge, elaborate an execution plan, emit a fixture, or run a backend.

The parser and semantic builder construct private immutable
`FSM::VIAL::SemanticIR`. The object contains normalized typed meaning and exact
provenance, never the raw token tree. Bounded sanitized semantic and
provenance-free meaning projections cross the public tool boundary; raw forms
and IR do not. Decision `0033` records why VIAL owns a dedicated parser
instead of publishing the current `Lispish` representation.

Implementation `.3` now ships the four private `FSM::VIAL` packages, the
checked source, focused regression, `.vial` language-surface entry, and
semantic-only support/capability accounting selected here. Completed `.10.1`
adds the separate public capabilities/check/format CLI/API and normal/terse
normalization. Neither slice produces a bridge, execution plan, artifact,
compile, simulation, result, parity, or scale claim.
The checked source is 4,986 bytes / 123 lines with SHA-256
`2205b3b4f073a61374b19cb72f06afe31d75fc4d88f903c414b9b28a744ca4cd`.

## Version And Profile Boundary

Every source starts with exactly one root:

```lisp
(vial
  (version 1)
  (package package_name
    ...))
```

Version 1 has one initially implemented profile,
`core_directed_single_clock_v1`. The profile is derived from the constructs
actually present; authors do not write a profile clause. A file requiring a
recognized but unimplemented future construct fails closed instead of being
accepted as an inert annotation.

Version 1 deliberately excludes absolute-time behavior, analog/real values,
host-language callbacks, raw HDL/UVM/VHDL blocks, native hierarchy, dynamic
allocation, recursion, unbounded loops/queues/crosses, runtime-created names,
and backend lifecycle hooks. Decision `0036` and
`docs/VIAL_EXECUTION_IR_V1_CONTRACT.md` now select typed native, execution,
replay, plan, result, and parity contracts. Private target-neutral execution
now ships through `.7.3`; public plan/artifact, backend/runtime/result, and
parity remain owned by `.10.2` through `.11`.

Decision `0034` makes this an initial-profile boundary, not VIAL's expressive
ceiling. VIAL is not constrained by synthesizability: later typed native
profiles may abstract full selected SV/UVM/VHDL verification semantics,
including UVM event/callback behavior. Decision `0039` and
`docs/VIAL_PUBLIC_TOOLING_V1_CONTRACT.md` now select exact `normal_v1` and
`terse_v1` source projections of one semantic model: terse form removes only
closed structural wrappers and adds no implicit meaning. Completed `.10.1`
normalizes both styles into the unchanged `.3` builder and proves public
format/reparse semantic-digest equivalence through `t/1555`.

“Abstract” means simplify for the author: learning this source language does
not require prior SV/UVM/VHDL knowledge. Those languages are backend targets,
analogous to assembly targets for C/C++ or Rust, rather than vocabulary that
VIAL reproduces. Later lowering contracts own efficient, readable,
source-mapped artifacts while preserving this target-independent semantic
boundary.

## Lexical Contract

The dedicated VIAL lexer owns these rules:

- Input is valid UTF-8. LF and CRLF line endings are accepted; bare CR and NUL
  are rejected. The original bytes and line endings remain the source-identity
  input and span authority.
- ASCII space, tab, CRLF/LF, and form feed separate tokens. `;` begins a
  comment through the next line ending outside a string.
- `(` and `)` delimit lists. Quote, quasiquote, unquote, dotted-pair, reader
  macro, and character-literal syntax do not exist.
- Identifiers match `[A-Za-z_][A-Za-z0-9_]*`. Qualified names are two or more
  identifiers separated by single dots. Each component is at most 128 bytes.
- Strings use JSON double-quote escapes: `\"`, `\\`, `\/`, `\b`, `\f`, `\n`,
  `\r`, `\t`, and `\uXXXX` with valid surrogate pairing. Decoded strings may
  not contain NUL.
- Integer tokens are decimal, `0b` binary, or `0x` hexadecimal with optional
  interior underscores. A leading `-` is allowed only for decimal signed
  values. Leading `+`, octal, unsized X/Z, exponent, and floating forms fail.
- Four-state vector literals are `#b` followed by one or more `0`, `1`, `x`,
  or `z` digits, with optional interior underscores. Case is accepted and
  normalized to lowercase. Literal width is the digit count.
- `true` and `false` are Boolean literals.
- A source name and every imported path must be forward-slash repository-
  relative, end in `.vial`, contain no empty, `.` or `..` segment, backslash,
  drive prefix, home prefix, URI scheme, or NUL.

Source spans use original input coordinates: zero-based half-open byte offsets
plus one-based inclusive start and end line/Unicode-scalar columns. The end
line/column identifies the final token character; an empty construct uses its
opening delimiter. This dual representation keeps byte identity exact without
making columns encoding-dependent.

## Closed Source Grammar

The notation below uses `*`, `+`, `?`, and `|` only in this specification; they
are not source tokens.

```text
SOURCE      := (vial (version 1) PACKAGE)
PACKAGE     := (package NAME IMPORTS TYPES TRANSACTIONS MODELS SCOREBOARDS FIXTURES)
IMPORTS     := (imports IMPORT*)
IMPORT      := (import NAME STRING)
TYPES       := (types TYPE_DECL*)
TRANSACTIONS:= (transactions TRANSACTION_DECL*)
MODELS      := (models MODEL_DECL*)
SCOREBOARDS := (scoreboards SCOREBOARD_DECL*)
FIXTURES    := (fixtures FIXTURE+)
```

The six package sections are mandatory and appear in exactly that order.
Empty sections are written explicitly. This keeps the version-1 grammar and
normalized record stable and makes unknown or misplaced clauses errors rather
than silently ignored extensions.

An import is `(import ALIAS "repository/relative/source.vial")`. Imports are
explicitly qualified: imported declarations are referenced as `ALIAS.NAME`.
There are no wildcard/re-export/import-search-path semantics. Alias and package
names are distinct namespaces. The graph must be acyclic, every source must be
supplied by the caller's in-memory source catalog, and one canonical source
name may be parsed only once.

## Type And Value Contract

### Type declarations

```text
TYPE_DECL := (type NAME TYPE_EXPR)
           | (enum NAME SCALAR_TYPE ENUM_MEMBER+)
ENUM_MEMBER := (NAME LITERAL)

TYPE_EXPR := bool
           | (u WIDTH)
           | (s WIDTH)
           | (logic WIDTH)
           | (slogic WIDTH)
           | (type QUALIFIED_NAME)
           | (record FIELD+)
           | (list LENGTH TYPE_EXPR)
FIELD     := (NAME TYPE_EXPR)
```

- `bool`, `u`, and `s` are two-state. `logic` and `slogic` are four-state.
- `u`/`logic` are unsigned; `s`/`slogic` are two's-complement signed.
- Width and list length are literal positive integers from 1 through 65,536.
- A record has 1 through 256 uniquely named ordered fields. Lists and records
  may nest to 32 aggregate levels inside the global parse-depth cap.
- An enum base is one scalar type. Members are unique, authored in order, and
  their literals must fit exactly without truncation or sign reinterpretation.
- A `(type ...)` reference resolves locally or through an explicit import.
  Recursive aliases and width-equal-but-shape-different substitutions fail.

Integer literals are untyped until a scalar context supplies exact signedness
and width. They must fit; there is no implicit truncation, extension across
signedness, or wrap. `#b` is four-state and must exactly match a `logic` or
`slogic` width. X/Z never coerces into a two-state type. Aggregate values are
constructed only through transaction field lists or model state declarations;
there is no positional aggregate literal in version 1.

These are semantic types, not forced hardware-carrier spellings. Decision
`0037` preserves them through later binding: a VIAL Boolean, numeric value, or
enum remains that type in SemanticIR and ExecutionIR even when a closed
directional proof represents it on a same-width HIAL logic carrier. The source
language never asks an author to insert a SystemVerilog/VHDL cast or weaken a
two-state/enum declaration merely to match a hardware port.

The normalized four-state value is target-neutral:

```text
kind: logic_vector
width: positive integer
signed: Boolean
value_bits: big-endian lowercase hexadecimal bits (unknown positions zero)
known_mask: big-endian lowercase hexadecimal mask
z_mask: big-endian lowercase hexadecimal mask; subset of !known_mask
```

Leading hex digits are retained to cover the declared width. No backend string
or SystemVerilog/VHDL literal is semantic truth.

### Expressions and properties

An expression is a literal, an enum member such as `htrans_t.nonseq`, a model-
local input/state identifier while validating that model's rules, or one of
the closed typed reference/operator forms below:

```text
(sample ENDPOINT_ALIAS)
(event TRANSACTION_OR_HANDLE EVENT_NAME)
(event_count TRANSACTION_OR_HANDLE EVENT_NAME)
(model MODEL_INSTANCE STATE_NAME)
(choice CHOICE_NAME)
(field EXPR FIELD_NAME)
(not EXPR)
(and EXPR EXPR+)
(or EXPR EXPR+)
(xor EXPR EXPR)
(same EXPR EXPR)
(value_eq EXPR EXPR)
(known EXPR)
(+ EXPR EXPR)
(- EXPR EXPR)
(< EXPR EXPR)  (<= EXPR EXPR)
(> EXPR EXPR)  (>= EXPR EXPR)
```

`same` is exact shape-and-four-state equality, so X equals X and Z equals Z in
the same position. `value_eq` is numeric/Boolean equality and requires both
operands to be known; an unknown operand becomes a typed runtime check error,
not false or target-language X. Arithmetic rejects four-state values and
overflow; later execution may not silently wrap.

A property is a Boolean expression or exactly one of the repository's
canonical property forms selected by decision `0008`:

```text
(=> PROPERTY PROPERTY)
(next PROPERTY)
(within PROPERTY MAX_CYCLES)
(within PROPERTY MIN_CYCLES MAX_CYCLES)
```

Bounds are positive literal cycle counts with `1 <= min <= max <= 2^31-1`.
VIAL does not introduce `eventually`, `until`, `throughout`, or a second
property grammar. Future temporal growth must extend the shared property
language and its typed projection for HIAL and VIAL together.

## Reusable Declarations

### Transactions

```text
(transaction NAME
  (fields (FIELD_NAME TYPE_EXPR)+)
  (events EVENT_NAME+))
```

Fields and events are ordered and unique. A transaction is a semantic record,
not a packed bus or UVM sequence item. DUT bindings later associate it with an
opaque bridge transaction reference, verify field/event identity, and prove
each field's direction-specific semantic-type-to-HIAL-carrier relation. That
proof is owned by ExecutionIR decision `0037`; it is not an implicit source-
language coercion and does not mutate the authored transaction type.

### Deterministic models

```text
(model NAME
  (inputs (INPUT_NAME (type-or-event TYPE_EXPR|event))+)
  (state (STATE_NAME TYPE_EXPR LITERAL)+)
  (rules (on INPUT_NAME (set STATE_NAME EXPR)+)+))
```

Version 1 models are deterministic event-driven state machines. An `on` input
must have type `event`. Rules appear in input declaration order, one rule per
event input. Assignments are simultaneous, target only declared model state,
and use pre-rule state. Every state is scalar in the first profile; aggregate
model state is recognized by the type system but rejected as an unimplemented
profile capability. There is no I/O, time, randomness, recursion, host call,
or hidden state.

### Scoreboards

```text
(scoreboard NAME
  (transaction TRANSACTION_REF)
  (policy in_order | keyed)
  (key FIELD_NAME)?
  (capacity POSITIVE_INTEGER))
```

`key` is absent for `in_order` and required for `keyed`; it must name a scalar
transaction field. Capacity is 1 through 1,000,000. Version 1 has no implicit
unbounded queue, unordered matching, tolerance callback, or backend-owned
comparison rule. `same` semantics compare fields unless a later contract adds
a typed comparator.

## Fixture Contract

```text
(fixture NAME
  DUT
  INSTANCES
  COVERAGE
  FAULTS
  RANDOMNESS
  SCENARIOS)
```

### Unbound DUT references

```text
(dut NAME
  (unit STRING)
  (domains (domain ALIAS STRING)+)
  (endpoints
    (endpoint ALIAS STRING TYPE_EXPR public_port|verification_probe)+)
  (transactions
    (transaction ALIAS STRING TRANSACTION_REF)+))
```

Strings are opaque logical bridge references at the semantic phase. They must
be non-empty single-line strings and unique within kind, but `.3` does not
pretend they exist. The future bridge binder validates them. An endpoint's
authored expected type and access class are binding assertions. Core v1 rejects
`native_hierarchy`; typed native extension binding is selected by `.6` and
remains unimplemented until its later semantic/profile owners act.

The first profile requires exactly one domain per fixture, at least one public
endpoint, and at least one transaction binding. Multiple domains parse only as
`VIAL_PROFILE_UNSUPPORTED` so source capability cannot exceed execution proof.

### Model and scoreboard instances

```text
(instances
  (model INSTANCE MODEL_REF (bind INPUT_NAME VALUE_OR_EVENT_REF)+)*
  (scoreboard INSTANCE SCOREBOARD_REF (actual TRANSACTION_ALIAS))*)
```

Every model input is bound exactly once with equal type. A scoreboard actual
binding must use the declaration's transaction type. Instance names share one
fixture-local namespace.

### Coverage

```text
(coverage
  (coverpoint NAME
    (sample DOMAIN_ALIAS)
    (expr EXPR)
    (bins (bin NAME normal|illegal|ignore MATCHER)+))*
  (cross NAME
    (points COVERPOINT_NAME COVERPOINT_NAME+)
    (max_bins POSITIVE_INTEGER))*)

MATCHER := (value LITERAL) | (range LITERAL LITERAL)
```

Bin names are unique per point. Matcher values must equal the expression type;
ranges require known ordered two-state scalar endpoints. Cross point names are
unique, distinct, scalar, and from the same sample domain. `max_bins` is
mandatory and 1 through 1,000,000; the Cartesian product must not exceed it.
Sampling occurs at the logical check phase for the declared domain. No
implicit bins or cross expansion exists.

### Bounded faults

```text
(faults
  (fault NAME
    (target (transaction TRANSACTION_ALIAS FIELD_NAME))
    (action (substitute EXPR))
    (duration (cycles DOMAIN_ALIAS POSITIVE_INTEGER)))*)
```

The substitute expression must match the transaction field type. Duration is
1 through `2^31-1` cycles. This first fault form changes the value presented to
one declared transaction field for the bounded interval after `(inject NAME)`.
Omission, delay, corruption policies beyond substitution, endpoint force, raw
HDL force/release, and probe mutation remain unsupported.

### Randomness and replay identity

```text
(randomness
  (seed UNSIGNED_64_BIT_INTEGER)
  (choice NAME TYPE_EXPR
    (decision_id STRING)
    (distribution (uniform LOW_LITERAL HIGH_LITERAL))
    (constraints PROPERTY*))*)
```

Choices are two-state scalar, names and non-empty single-line decision IDs are
unique, bounds fit the type and satisfy low <= high, and constraints may refer
only to the choice and immutable fixture declarations. The semantic IR stores
the seed, explicit decision ID, distribution, constraint AST, and semantic
source identity. `.2` does not select a random algorithm or chosen value;
completed `.6` selects exact plan-time `sha256_counter_rejection_v1` and replay
records without changing this semantic source contract.
Within one scenario, the first evaluation of one choice creates exactly one
logical decision and later references reuse that value; a new scenario starts
a new decision occurrence with the same declared decision ID plus its scenario
identity. This freezes identity without prematurely choosing the algorithm.

### Scenarios, actions, and concurrency

```text
(scenarios
  (scenario NAME
    (timeout (cycles DOMAIN_ALIAS POSITIVE_INTEGER))
    (steps ACTION+))+)
```

Actions are closed:

```text
(reset DOMAIN_ALIAS CYCLES)
(drive ENDPOINT_ALIAS EXPR)
(start HANDLE TRANSACTION_ALIAS (fields (FIELD_NAME EXPR)+))
(await PROPERTY)
(parallel all|any (fiber NAME ACTION+)(fiber NAME ACTION+)+)
(repeat POSITIVE_INTEGER ACTION+)
(expect NAME PROPERTY)
(scoreboard_expect SCOREBOARD_INSTANCE (fields (FIELD_NAME EXPR)+))
(scoreboard_check SCOREBOARD_INSTANCE)
(inject FAULT_NAME)
```

- A transaction start supplies every field exactly once and creates a unique
  scenario-local handle whose declared events become valid references.
- `await` completes when its property is true at check phase. Scenario timeout
  is mandatory, so an unbounded wait cannot exist.
- `parallel all` joins every fiber. `parallel any` joins the first fiber in
  deterministic event order and cancels the remaining fibers before their next
  action. There is no host-thread or target-scheduler meaning.
- Fibers are ordered by source; names are unique in the parallel. Nested
  parallel depth is at most 16 and each parallel has 2 through 256 fibers.
- `repeat` is literal-bounded from 1 through 1,000,000. Recursion and dynamic
  loops do not exist.
- Expectation names are unique per scenario. `expect` evaluates at the action's
  check phase and does not create a second temporal grammar.
- Scoreboard expected fields are complete and typed; `scoreboard_check` is
  explicit. No end-of-scenario implicit drain claim is made.
- A fault may be injected once per scenario and auto-expires by its declared
  duration. Overlapping injections of the same fault fail elaboration later.

## First Bounded Source

Implementation `.3` owns the new checked source
`vial/ahb_subordinate_base_output_arbitration.vial`. It is a semantic rewrite
of `t/data/ahb_generated_subordinate_base_output_arbitration_tb.svt`, not an
executable replacement. The selected shape is:

```lisp
(vial
  (version 1)
  (package ahb_subordinate_base_output_arbitration
    (imports)
    (types
      (enum htrans_t (logic 2)
        (idle #b00)
        (nonseq #b10))
      (type address_t (logic 32))
      (type data_t (logic 32)))
    (transactions
      (transaction ahb_write
        (fields
          (address (type address_t))
          (transfer (type htrans_t))
          (write bool)
          (size (logic 3))
          (data (type data_t))
          (wait_cycles (u 4)))
        (events requested accepted captured held completed error)))
    (models
      (model event_counter
        (inputs (tick event))
        (state (count (u 32) 0))
        (rules (on tick (set count (+ count 1))))))
    (scoreboards
      (scoreboard accepted_writes
        (transaction ahb_write)
        (policy in_order)
        (capacity 4)))
    (fixtures
      (fixture base_output_arbitration
        (dut dut
          (unit "unit/ahb_lite_subordinate")
          (domains (domain bus "domain/ahb_bus"))
          (endpoints
            (endpoint ready_out "endpoint/HREADYOUT" (logic 1) public_port)
            (endpoint response "endpoint/HRESP" (logic 1) public_port)
            (endpoint read_data "endpoint/HRDATA" (logic 32) public_port)
            (endpoint stored_data "probe/reg_data_q" (logic 32) verification_probe))
          (transactions
            (transaction write "transaction/ahb_write" ahb_write)))
        (instances
          (model accepts event_counter (bind tick (event write accepted)))
          (model completions event_counter (bind tick (event write completed)))
          (scoreboard writes accepted_writes (actual write)))
        (coverage
          (coverpoint stall_seen
            (sample bus)
            (expr (same (sample ready_out) #b0))
            (bins
              (bin not_stalled normal (value false))
              (bin stalled normal (value true)))))
        (faults
          (fault unsupported_size
            (target (transaction write size))
            (action (substitute #b111))
            (duration (cycles bus 1))))
        (randomness
          (seed 1)
          (choice success_wait (u 4)
            (decision_id "success.wait_cycles")
            (distribution (uniform 1 2))
            (constraints (>= (choice success_wait) 1))))
        (scenarios
          (scenario success
            (timeout (cycles bus 256))
            (steps
              (reset bus 3)
              (scoreboard_expect writes
                (fields
                  (address #b00000000000000000000000000000000)
                  (transfer htrans_t.nonseq)
                  (write true)
                  (size #b010)
                  (data #b11001010111111101011101010111110)
                  (wait_cycles (choice success_wait))))
              (start success_write write
                (fields
                  (address #b00000000000000000000000000000000)
                  (transfer htrans_t.nonseq)
                  (write true)
                  (size #b010)
                  (data #b11001010111111101011101010111110)
                  (wait_cycles (choice success_wait))))
              (parallel all
                (fiber complete
                  (await (within (event success_write completed) 1 256)))
                (fiber stall
                  (await (within (same (sample ready_out) #b0) 1 256))))
              (expect accepted_once
                (value_eq (event_count success_write accepted) 1))
              (expect completed_once
                (value_eq (event_count success_write completed) 1))
              (expect response_ok (same (sample response) #b0))
              (expect read_zero
                (same (sample read_data) #b00000000000000000000000000000000))
              (expect storage_written
                (same (sample stored_data) #b11001010111111101011101010111110))
              (scoreboard_check writes)))
          (scenario unsupported_size
            (timeout (cycles bus 256))
            (steps
              (reset bus 3)
              (inject unsupported_size)
              (start error_write write
                (fields
                  (address #b00000000000000000000000000000000)
                  (transfer htrans_t.nonseq)
                  (write true)
                  (size #b010)
                  (data #b11111111111111111111111111111111)
                  (wait_cycles 1)))
              (await (within (event error_write completed) 1 256))
              (expect accepted_once
                (value_eq (event_count error_write accepted) 1))
              (expect two_error_cycles
                (value_eq (event_count error_write error) 2))
              (expect response_returns_ok (same (sample response) #b0))
              (expect read_zero
                (same (sample read_data) #b00000000000000000000000000000000))
              (expect storage_unchanged
                (same (sample stored_data) #b00000000000000000000000000000000)))))))))
```

The exact checked-in bytes and hash are selected only when `.3` creates the
source. Bridge references are intentionally opaque and unresolved. The source
must parse and type-check into semantic intent, but it cannot compile, bind,
emit, or run until later leaves implement those phases.

## VIALSemanticIR Required IR Record

### Name, phase, owner, producer, consumer

| Required field | Selected contract |
| --- | --- |
| Name | `VIALSemanticIR`, Perl class `FSM::VIAL::SemanticIR`, file `perl/FSM/VIAL/SemanticIR.pm` |
| Phase | semantic intent after span-aware parsing/import resolution/type checking and before HIAL binding |
| Owner | `FSM::VIAL::SemanticBuilder` alone constructs normalized data and calls private `_new_validated` |
| Producers | `FSM::VIAL::Parser->parse_source` through `SemanticBuilder`; no backend or HIAL producer |
| Consumers in `.3` | `FSM::VIAL::SemanticReport`; focused t1550 |
| Future consumers | HIAL/VIAL binder under `.7`; no direct backend consumer |
| Mutation | immutable object; scalar accessors return scalars; every structured accessor and projection returns a deep defensive clone |
| Status | raw object private; never serialized or exposed as a public schema |
| Retirement | retained as the selected unbound semantic phase; replacement requires a superseding decision and migrated parser/report/binder/tests/docs |

The parser owns only short-lived token and form nodes. They are not durable IR,
are not returned, and are discarded after the semantic builder succeeds or
diagnostics are constructed.

### Closed top-level record

```text
schema_version: 1
language: "vial"
language_version: 1
profile: "core_directed_single_clock_v1"
root_source: source identity record
sources: ordered source identity records (root, then depth-first imports)
packages: ordered normalized package records
required_capabilities: sorted unique feature-id strings
provenance: semantic-path -> source-location table
```

A source identity record contains exactly `source_name`, `content_sha256`,
`byte_length`, and `line_ending` (`lf`, `crlf`, or `mixed`). Imported packages
are ordered by root traversal and authored import order; duplicate canonical
sources are represented once.

Each package record contains exact identity, ordered imports, and ordered type,
transaction, model, scoreboard, and fixture arrays. Every declaration and
fixture-local entity has:

```text
semantic_id: stable package-qualified ID
name: authored identifier
semantic_path: RFC-6901-style structural path
source_span: exact source location record
```

Stable IDs use
`<package>::<kind>::<name>` and extend with `::<child-kind>::<child-name>` for
fixture-local entities. They contain names, never list ordinals. Semantic paths
contain normalized array indices and are the provenance lookup keys. Reordering
declarations changes paths/order but not named IDs.

Normalized type records are closed discriminated hashes for scalar, enum,
record, and list. References carry both authored qualified spelling and
resolved semantic ID. Expression/property records contain `kind`, `op` when
applicable, result type ID/inline scalar type, ordered typed operands,
semantic path, and span. They never retain token arrays or target-language
text.

Transaction, model, scoreboard, DUT, binding, instance, coverage, fault,
randomness, scenario, fiber, and action records preserve the source semantics
defined above as closed hashes and authored-order arrays. Cross-references
store resolved semantic IDs; opaque bridge references remain distinct scalar
fields named `bridge_ref` and are never misclassified as resolved IDs.

### Invariants

After construction:

1. all local/imported names, types, declaration references, instance bindings,
   expressions, properties, actions, handles, events, endpoints, domains,
   coverage, faults, choices, and scenario references are resolved and typed;
2. every aggregate/scalar literal is normalized without truncation or unknown
   coercion;
3. every container is closed and every authored-order array is deterministic;
4. every semantic node has a stable ID where named, a recognized semantic
   path, and exact or ancestor-resolvable provenance;
5. import/source identities are repository-relative and content-hashed;
6. bridge references remain explicitly unresolved and typed as binding
   assertions, never treated as verified HIAL facts;
7. all loops, fibers, waits, scoreboards, crosses, faults, widths, lists,
   source sizes, and declaration counts satisfy bounded limits;
8. the raw object contains no filehandle, callback, blessed foreign object,
   regex, code reference, host path, parser token/form, target HDL, or backend
   object; and
9. identical source catalogs yield deeply equal `as_hashref` data regardless
   of Perl hash insertion order.

## Parser, Builder, Object, And Report Surfaces

Implementation `.3` owns exactly:

```text
perl/FSM/VIAL/Parser.pm
perl/FSM/VIAL/SemanticBuilder.pm
perl/FSM/VIAL/SemanticIR.pm
perl/FSM/VIAL/SemanticReport.pm
vial/ahb_subordinate_base_output_arbitration.vial
t/1550-vial-semantic-ir.t
```

These parser/builder calls remain private compiler seams:

```perl
my $checked = FSM::VIAL::Parser->check_source({
    text => $bytes,
    source_name => 'vial/example.vial',
    source_catalog => { 'vial/common.vial' => $import_bytes },
});

my $semantic_ir = FSM::VIAL::Parser->parse_source({ ... });
my $report = FSM::VIAL::SemanticReport->build($semantic_ir);
```

Completed `.10.1` instead exposes `fsmgen vial capabilities|check|format` and
the closed `fsmgen.vial_tool_request.v1` / `fsmgen.vial_tool_result.v1` API.
`FSM::VIAL::SourceProjection` owns only private form normalization/rendering
and public-result meaning digests; neither raw parse forms nor SemanticIR
objects cross that boundary.

- Each method accepts exactly one closed hash. `text` and `source_name` are
  required; `source_catalog` defaults to an empty hash. Unknown keys fail.
- The parser never reads the filesystem, environment, user cache, current
  directory, network, or global registry. Imported bytes come only from the
  supplied source catalog.
- `check_source` never throws for well-shaped invocation input. It returns a
  fresh closed hash `{ ok, diagnostics, semantic_report }`; the report is
  `undef` on failure.
- `parse_source` returns immutable `FSM::VIAL::SemanticIR` or throws the
  formatted first diagnostic. It never returns partial IR.
- `SemanticIR` has private `_new_validated`, scalar accessors for version and
  profile, defensive `sources`, `packages`, `provenance`,
  `source_location_for`, and `as_hashref`; it has no mutator or raw reference.
- `SemanticReport->build` accepts only the exact IR class and returns a fresh
  defensive projection. Mutation of any caller input/result cannot change the
  IR, a later report, or another caller's result.

## Diagnostic Contract

Diagnostics are closed hashes:

```text
schema_version: 1
severity: "error"
code: VIAL_LEX_ERROR | VIAL_PARSE_ERROR | VIAL_IMPORT_ERROR |
      VIAL_REFERENCE_ERROR | VIAL_TYPE_ERROR | VIAL_LIMIT_ERROR |
      VIAL_PROFILE_UNSUPPORTED | VIAL_SEMANTIC_ERROR
phase: lex | parse | import | resolve | type | limit | profile | semantic
message: one-line target-independent text
semantic_path: recognized path or nearest valid container
source_location:
  source_name
  start_byte, end_byte_exclusive
  start_line, start_column, end_line, end_column
notes: ordered array of closed { message, source_location } records
```

Each note always contains `source_location`; it is explicit `null` only when
no secondary token or import edge exists.

Lex/parse/import errors stop the affected source deterministically at the first
error. Semantic validation collects independent errors in authored depth-first
order, with unknown keys sorted lexically within one closed form, and avoids
cascades below an invalid container. Cross-reference/type errors follow the
referencing source position. Import-cycle notes list the ordered edge chain.

The thrown form is exactly:

```text
Error [CODE] source:line:column semantic_path: message\n
```

No Perl stack, absolute path, target-language text, or nondeterministic object
address enters a diagnostic or report.

## Sanitized Semantic Report

`SemanticReport->build` returns exactly:

```text
schema_version: 1
language: "vial"
language_version: 1
profile: "core_directed_single_clock_v1"
root_source: { source_name, content_sha256 }
sources: [{ source_name, content_sha256 }]
packages:
  - semantic_id, name, source_name
  - imports: [{ alias, source_name, package_id }]
  - types, transactions, models, scoreboards: [{ semantic_id, name }]
  - fixtures:
      - semantic_id, name, dut_name, unit_bridge_ref
      - domains/endpoints/transaction_bindings/model_instances/
        scoreboard_instances/coverpoints/crosses/faults/choices/scenarios:
        [{ semantic_id, name, selected bounded summary fields }]
required_capabilities: sorted feature IDs
unresolved_bridge_refs:
  - fixture_id, kind, alias, bridge_ref, expected_type, access
diagnostics: []
```

`expected_type` and `access` are explicit `null` for unit/domain records;
transaction records carry their declared transaction semantic ID and null
access; endpoint records carry both normalized expected type and access. No
key is conditionally absent.

The selected bounded summary fields are counts, type IDs, policy/capacity,
domain ID, access class, transaction ID, decision ID/distribution bounds,
scenario timeout/action/fiber counts, and coverage max-bin bounds. The report
does not expose expression/action bodies, state initial values, random seeds,
private provenance tables, parser nodes, or mutable IR branches.

Implementation `.3` may advertise only these exact capabilities:

```text
vial.source.v1
vial.semantic_ir.v1
vial.profile.core_directed_single_clock_v1
```

The support entry for the first source must say parse/typecheck/semantic-report
only and explicitly deny bridge binding, plan, artifact generation, compile,
simulation, result, parity, UVM, VHDL, mixed-language, and scale claims.

## Bounded Resource Limits

Before IR construction, version 1 enforces:

| Resource | Limit |
| --- | ---: |
| one source file | 1,048,576 bytes |
| combined root/import bytes | 16,777,216 bytes |
| imported sources | 64 |
| tokens across catalog | 1,000,000 |
| list nesting | 128 |
| declarations per package section | 4,096 |
| fixtures per package | 1,024 |
| actions per scenario after literal repeat accounting | 65,536 |
| parallel nesting / fibers per parallel | 16 / 256 |
| scalar width / list length | 65,536 / 65,536 |
| record fields | 256 |
| scoreboard capacity / coverage max bins | 1,000,000 / 1,000,000 |

Exceeding a limit yields `VIAL_LIMIT_ERROR`; the implementation must not rely
on Perl recursion failure, memory exhaustion, or a backend to reject it. These
are v1 safety limits, not `.17` performance qualifications or whole-product
capacity claims.

## Negative And Deferred Boundaries

Focused t1550 must prove at least:

- invalid encoding/newline/string/literal/comment/list/token grammar;
- wrong/duplicate/misordered/unknown root or package sections;
- unsafe/missing/duplicate/cyclic imports and package/alias conflicts;
- duplicate/unresolved declarations, qualified names, bridge aliases,
  instances, handles, events, model inputs/state, bins, crosses, faults,
  choices, scenarios, expectations, and fibers;
- enum overflow, recursive aliases, record/list/width limits, type mismatch,
  signedness mismatch, X/Z-to-two-state coercion, incomplete transaction
  fields, unknown arithmetic, and invalid equality/property operands;
- any future attempt to treat a later carrier relation as source-level width/
  sign coercion, enum erasure, or four-state-to-two-state conversion;
- model nondeterminism, missing input/rule/state assignment targets;
- unbounded/zero timeout, repeat, scoreboard, cross, fault, or window; invalid
  parallel shape and profile-multiple-domain use;
- raw target-language/native-hierarchy/absolute-time/host-callback/recursion/
  dynamic-loop/unknown-extension rejection;
- input/report/IR defensive-copy independence, deterministic order and stable
  diagnostic paths/spans; and
- explicit no-binding/no-plan/no-output/no-runtime/non-claim accounting.

Implemented by separate exact owners without widening this source contract:

- bridge-reference existence and type equivalence (selected bridge schema
  `0035`, private implementation `.5`, and private binding `.7.3`); and
- selected logical-phase scheduling, random/replay, native-extension
  negotiation, and defensive in-process plan construction (`.7.3`).

Deferred to later exact owners:

- public plan/artifact layout and schema migration (active `.10.2`); source-only
  capabilities/check/format shipped in `.10.1`;
- plain-SystemVerilog output/runtime/results (`.10.3`/`.10.4`), parity (`.11`),
  and UVM, VHDL, and mixed-language output/runtime;
- broader property operators, multi-domain fixtures, aggregate model state,
  bounded unordered scoreboards, additional fault kinds, constrained solving,
  reusable coverage templates, and exact scale budgets.

## Validation And Rollback

Implementation signoff requires the focused parser/SemanticIR/report suite,
support-accounting and capability-manifest tests, all four Perl syntax checks,
task-tree integrity, task/roadmap/book/fact consistency, docs audits, every
mdBook chapter and the repository-local HTML build, Knowledge Map generation/
check, bounded Memory, diff, staged acceptance, all doctrines, and exact
repository-local output cleanup. Broader failures not caused by this slice
must be root-caused and routed to their own inactive task trees rather than
silently attributed to VIAL.

Rollback removes the four `FSM::VIAL` packages, the checked `.vial` source,
t1550, and the `.vial` support/capability/language-surface entries, then
restores this contract and its book/fact/task continuity to selected-only
state. It must not alter HIAL parsing/lowering, existing HDL or verification
artifacts, or the separately tracked regression-oracle repairs.
