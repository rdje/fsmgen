# VIALExecutionIR, Logical-Time, Native-Extension, Plan, Result, And Parity Version-1 Contract

Date: 2026-07-31
Owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.6`
Status: selected; implementation is blocked at `.7.2` by the confirmed transaction type-relation mismatch recorded in `docs/VIAL_HIAL_TYPE_BINDING_MISMATCH_AUDIT.md`

## Outcome

VIAL execution version 1 is a target-neutral, fully DUT-bound operational
contract above SystemVerilog, UVM, and VHDL methodology machinery. Private
immutable `VIALExecutionIR` binds one checked `VIALSemanticIR` fixture through
one checked `HIALVIALBridgeManifest`, classifies every capability, resolves
stable random choices, and builds a deterministic logical-time operation graph.

The first profile is `core_directed_single_clock_execution_v1`. It covers the
complete shipped `core_directed_single_clock_v1` semantic profile against the
shipped `core_single_unit_v1` bridge profile, while retaining explicit target-
profile requirements. It does not select or emit a SystemVerilog, UVM, VHDL,
or mixed-language backend.

The contract also selects three sanitized JSON-safe data schemas:

```text
fsmgen.vial_plan.v1
fsmgen.verification_result_manifest.v1
fsmgen.vial_parity_report.v1
```

No file is written in `.6` or `.7`. Public CLI/API, repository-local output
layout, filenames, artifact discovery, and migration remain owned by `.8`.
The schema names make those later surfaces possible without promoting the raw
IR.

Decision `0036` records the governing rule: VIAL describes verification
meaning; SV/UVM/VHDL are compiler targets analogous to assembly beneath
C/C++ or Rust. Backend clocking regions, UVM phases/objections, factories,
callbacks, TLM plumbing, VHDL processes, delta cycles, and host threads may
implement this contract but never define or leak into authored VIAL meaning.

## Phase And Ownership Boundary

```text
.vial bytes
  -> VIALSemanticIR                       shipped by .3
  + HIALVIALBridgeManifest               shipped by .5
  + optional replay/native catalogs      selected here; empty in first fixture
  -> bind + elaborate + classify
  -> private immutable VIALExecutionIR   selected here; implementation .7
  -> sanitized vial-plan projection      selected here; public placement .8
  -> target backend                      .9 and later
  -> normalized result manifest          selected here; first runtime .10
  -> parity comparison                    selected here; runtime parity .11+
```

Only the future `FSM::VIAL::ExecutionBuilder` constructs
`FSM::VIAL::ExecutionIR`. A target backend consumes ExecutionIR and never binds
raw SemanticIR or bridge records independently. The future
`FSM::VIAL::ExecutionReport` produces the plan projection. Structured inputs
are cloned before validation; every object accessor and report returns a deep
defensive copy.

The first private entrypoint selected for `.7` is:

```perl
my $result = FSM::VIAL::ExecutionBuilder->build({
    semantic_ir             => $semantic_ir,
    bridge_manifest         => $bridge_manifest,
    fixture_id              => $fixture_id,
    scenario_ids            => \@scenario_ids,
    execution_profile       => 'core_directed_single_clock_execution_v1',
    replay_manifest         => undef,
    native_extension_catalog => [],
});
```

The argument is one exact closed hash. `semantic_ir` and `bridge_manifest`
must be the exact private classes produced by the shipped owners, not lookalike
hashes. `scenario_ids` is a non-empty authored-order subset with no duplicate;
the first fixture supplies both scenarios. The replay value is null or the
closed replay record below. The native catalog is empty for the first profile.
Unknown keys, subclass stand-ins, raw AST/form arrays, report hashes, backend
objects, callbacks, filehandles, or target artifacts fail before binding.

Success returns exactly:

```text
ok: true
execution_ir: exact FSM::VIAL::ExecutionIR object
plan: fresh fsmgen.vial_plan.v1 hash
diagnostics: []
```

Failure returns `ok: false`, null `execution_ir` and `plan`, and ordered
diagnostics. No partial object is returned.

## Initial Execution Profile

`core_directed_single_clock_execution_v1` requires:

- SemanticIR schema 1, language version 1, and profile
  `core_directed_single_clock_v1`;
- bridge schema `fsmgen.hial_vial_bridge_manifest.v1` and profile
  `core_single_unit_v1`;
- exactly one selected fixture, one bound unit, and one bound time domain;
- only the closed source actions, expressions, properties, model, scoreboard,
  coverage, fault, and randomness forms selected by decision `0033`;
- scalar model state and bounded in-order/keyed scoreboards;
- no native hierarchy, native extension, aggregate model state, multiple
  domains, dynamic name/allocation, recursion, unbounded loop/queue/cross,
  absolute time, real/analog value, or host callback; and
- every backend requirement classified before plan construction.

The execution profile provides exactly these semantic capabilities:

```text
vial.execution_ir.v1
vial.execution_profile.core_directed_single_clock_execution_v1
vial.logical_time.drive_sample_react_check_v1
vial.random.sha256_counter_rejection_v1
vial.replay.v1
vial.plan.v1
vial.result_manifest.v1
vial.parity_projection.v1
```

Capabilities from SemanticIR and the bridge remain recorded with their
origin. A capability ledger entry contains exactly:

```text
capability_id
origins[]
classification
portable_class
evidence_ids[]
```

`classification` is `satisfied_by_execution_profile` or
`required_from_backend`. `portable_class` is `portable`,
`portable_with_equivalent_adapter`, `paired_native`, or `native_only`.
Origins and evidence IDs are sorted unique stable IDs.

An unknown capability, contradictory classifications, or an unsatisfied
semantic-execution requirement fails binding. A recognized target requirement
may remain `required_from_backend` in a target-neutral plan. Every backend must
supply it before any target file is emitted. This is capability-complete plan
construction, not a false backend-support claim.

For the checked AHB fixture, `probe/reg_data_q` produces the known requirement
`hial_vial.bridge_probe.equivalent_adapter_required` with portable class
`portable_with_equivalent_adapter`. The plan is valid and target-neutral, but
no backend may emit or run it until the profile supplies the exact probe
adapter. Retained bridge residue stays visible; a residue whose
`required_capability` is non-null joins the capability ledger, while null
residue is an honest deferred fact rather than an invented blocker or support
claim.

## Exact Binding Contract

Binding uses semantic IDs and normalized types, never target names or name
spelling heuristics.

### Unit, domain, endpoint, and probe binding

1. The fixture DUT `unit` bridge reference resolves to exactly one bridge
   `unit_id`.
2. Every domain bridge reference resolves to one domain owned by that unit.
   The active edge, reset endpoint, reset kind, and polarity become explicit
   ExecutionIR facts.
3. Every endpoint bridge reference resolves to one bridge endpoint with
   structurally equivalent normalized type and exact `public_port` access.
4. Every verification-probe reference resolves to one bridge probe with
   structurally equivalent type, `verification_probe` access, and explicit
   adapter requirement.
5. A sampled endpoint must be an output/inout public port or a read-only probe.
   A driven endpoint must be an input/inout public port. Probes cannot be
   driven. Clock/reset ownership cannot be repurposed as ordinary data drive.
6. Raw backend binding names are not copied into executable expressions. The
   backend later resolves a logical ID through the bridge binding table.

Type equivalence is recursive and exact: state domain, signedness, width, enum
member order/value, record field name/order/type, and list length/element type
must agree. No width-only coercion, two-/four-state collapse, signedness
reinterpretation, truncation, extension, or target-language cast is allowed.

### Transaction and event binding

Every VIAL transaction binding resolves to exactly one bridge transaction.
Its declared fields must match the bridge field set by name and structurally
equivalent type. Bridge transaction `type_id: null` is valid for the shipped
scalar-only profile; each field's bridge `type_id` is authoritative.

Every event referenced by VIAL resolves through the bound transaction and has
one bridge event record. The event's declared phase is preserved. Its closed
bridge canonical expression is rebound from logical endpoint/probe references
to execution binding IDs; backend text is never introduced. A `scenario_start`
event has no expression. An event expression that reaches unbound actor
storage, an access-incompatible endpoint, an unavailable probe, or an unknown
operator fails.

The first profile uses the bridge's `single_active` correlation rule. Starting
a second live handle for the same transaction binding before the first
completes is an execution error. `declaration_order` remains valid for the
bounded direct-IAL1 shape. Wider outstanding/correlation policies require a
later explicit execution profile.

### Stable execution identities

Execution IDs are semantic, not runtime-created names:

```text
execution/<semantic-id>
binding/<fixture-id>/<bridge-semantic-id>
operation/<scenario-id>/<semantic-path>/<repeat-index-path>
fiber/<scenario-id>/<parallel-semantic-path>/<fiber-name>/<repeat-index-path>
decision/<fixture-id>/<scenario-id>/<authored-decision-id>/0
run/<plan-id>/<scenario-id>
```

RFC-6901 semantic paths are escaped before inclusion. Literal repeat indices
are zero-based decimal components. The final `/0` is the only version-1
decision occurrence because choices are scenario-scoped. No process ID,
address, callback order, target path, simulator time, hash insertion order, or
dynamic allocation enters an identity.

## Normalized Execution Values

Execution values use one recursive target-neutral shape. Scalar values contain
exactly:

```text
kind: scalar
type_id
state_domain: two_state | four_state
signed: Boolean
width: positive integer
value_hex
known_hex
z_hex
```

Hex fields are lowercase and zero-padded to `ceil(width/4)`. Bits above width
are zero, `known_hex & z_hex` is zero, and two-state values are fully known
with no Z bits. Boolean is two-state unsigned width one. Signed values retain
their declared two's-complement bit pattern; arithmetic is checked at the
declared mathematical range and never silently wraps.

Aggregate values contain exactly `kind`, `type_id`, `fields`, and `items`.
Records use authored-order `{name, value}` fields and an empty `items` array;
lists use ordered `items` and an empty `fields` array. Unused keys are present
as empty arrays. The first execution profile uses aggregate transaction
records for VIAL model/scoreboard bookkeeping even though the bridge's scalar-
only transaction `type_id` is null; the record type comes from SemanticIR and
each bound field proves its bridge equivalence.

`same` compares complete normalized shape and masks. `value_eq` requires fully
known equal-shape scalar operands and compares mathematical values. Unknown
`value_eq`, unknown arithmetic, overflow, or an invalid ordered comparison is
a typed execution failure, never target X behavior.

## Logical Time

Every portable runtime occurrence has exactly:

```text
domain_id
cycle
phase
ordinal
```

`cycle` and `ordinal` are zero-based non-negative integers. Phase order is
fixed:

1. `drive` — verification-controlled values and transaction starts become
   visible before the active DUT edge;
2. `sample` — the backend captures one stable post-edge DUT snapshot and
   bridge-defined event predicates;
3. `react` — event counts, deterministic models, scoreboards, faults, and
   scenario-control state consume the snapshot; and
4. `check` — waits/expectations, coverage, joins/cancellation, diagnostics,
   timeout, and completion commit.

Within one phase, deterministic order is the tuple:

```text
(domain_rank, static_operation_rank, local_emission_index, semantic_id)
```

Domain rank is bridge semantic-ID order; version 1 has one domain. Static
operation rank is depth-first authored scenario/action/fiber order after
literal-repeat expansion. Local emission index is fixed by each operation's
closed effect list. The recorded `ordinal` is the resulting zero-based rank
within the phase.

Backends may use SystemVerilog clocking/program regions, UVM callbacks and
phases, VHDL processes and delta cycles, or other scheduler facilities only if
the observed result is equivalent to this order. Host threads, coroutine wake
order, simulator region names, delta count, and UVM objections are never
portable time.

The scenario begins immediately before cycle 0 `drive`. Its timeout of `N`
cycles admits checks at cycles `0` through `N-1`; if completion has not
committed by the end of cycle `N-1` check, timeout commits there and cancels
remaining fibers. A backend cannot add a grace cycle.

`(reset DOMAIN N)` asserts reset at cycle 0 drive relative to that action,
keeps it active for exactly N active-edge samples, deasserts it at the next
drive phase, and completes at that cycle's check. The next DUT-affecting action
cannot execute before the following drive phase. Active level and async/sync
meaning come from the bound domain; VIAL source does not spell target reset
code.

One phase may execute a finite chain of newly ready zero-duration control
operations in increasing static rank. Every execution consumes a distinct
ordinal and the chain is bounded by the statically expanded operation count.
If a phase cannot reach quiescence within that count, execution fails with a
schedule diagnostic. Zero-time unbounded looping is impossible.

## Operation Graph And Action Semantics

ExecutionIR is a deterministic operational graph, not a table of target HDL
statements and not a promise that dynamic completion cycles are known at
compile time. Every operation record has exactly:

```text
operation_id
kind
scenario_id
fiber_id
static_rank
eligible_phase
typed_inputs[]
effects[]
successor_ids[]
failure_successor_id
cancel_scope_id
deadline
source_location
```

The root scenario is a fiber. Nested fibers have stable IDs and a parent
cancel scope. `deadline` is null except for temporal evaluators and scenario
roots. Expressions/properties are closed typed execution records; parser forms,
raw SemanticIR branches, bridge AST, and target text are absent.

Action phase eligibility and effects are:

| Action | Eligible phase | Selected effect |
| --- | --- | --- |
| `reset` | `drive` plus completion at `check` | exact reset interval described above |
| `drive` | `drive` | update one driver slot; value persists until replaced or finalization |
| `start` | `drive` | resolve fields, apply active faults, create handle, emit `requested`, and start the bound transaction contract |
| `await` | `check` | block until its property passes; temporal impossibility fails the action |
| `parallel` | `react` | activate ordered child fibers and join/cancel by the policy below |
| `repeat` | `react` | enter the next statically expanded literal iteration |
| `expect` | `check` | evaluate/track the property and record one named pass/fail outcome |
| `scoreboard_expect` | `react` | enqueue one complete typed expected transaction |
| `scoreboard_check` | `check` | require no mismatch, unmatched actual, or pending expected entry |
| `inject` | `react` | arm one fault for the next eligible drive interval |

Driver slots are logical endpoint IDs. A value driven at one drive phase
remains in the slot until another VIAL action changes it, reset/finalization
applies the later backend's selected safe-value policy, or the bound
transaction driver owns that slot. Two same-phase writes to one slot from live
fibers are a deterministic conflict error even when values match; source order
does not silently choose a winner.

A transaction start evaluates every field once from the plan's fixed choices
and current model/sample values permitted by the typed expression. Active
substitution faults are applied afterward. The resulting effective field
record is immutable for that handle. The bridge/backend transaction adapter
owns protocol waveforms, but it must report the same requested, accepted,
captured/held/completed/error events and cannot change the effective field
record.

The first profile publishes an actual transaction to bound scoreboards during
`react` when its `completed` event is sampled. Its actual value is the
effective immutable field record plus request/accept/complete logical stamps.
If the bridge profile does not select a unique completion event, binding
fails. Future streaming or multi-beat actual records require a wider explicit
transaction profile.

### Fibers, joins, cancellation, and failure

Child fibers of one `parallel` become ready in authored order. `parallel all`
completes only after every child completes. `parallel any` chooses the first
child completion by logical-time tuple and static fiber rank, then marks every
other live child cancelled before any later action in that cancel scope can
run. A tie never depends on host scheduling.

Cancellation propagates through nested fibers and pending temporal evaluators.
It does not roll back values already driven, transactions already requested,
model/scoreboard state already committed, coverage already hit, or native
effects already recorded. Cancel-safe cleanup is a later lifecycle/backend
responsibility and must be declared if a future semantic family requires it.

An action/type/event/native/runtime error fails its owning scenario, cancels
all live fibers, proceeds through deterministic finalization, and records the
diagnostic. `parallel any` cannot hide a failure that occurs at or before the
winning completion tuple. Scenario timeout is a failure status, not an ordinary
cancelled success.

## Event, Sample, And Property Semantics

The backend captures one immutable sample snapshot per domain cycle. Every
`(sample ENDPOINT)` read at react/check uses that cycle's sample snapshot.
Bridge event expressions evaluate in their declared phase against the
corresponding drive state or sample snapshot. One true evaluation creates one
event occurrence with handle ID, event ID, logical time, and local emission
index.

Event counts are per handle/event pair and increment in react after the event
occurrence. A model input bound to an event sees the same occurrence in react.
Checks at the current cycle's check phase see the updated count/model/
scoreboard state.

Temporal evaluators activate at a check phase:

- a Boolean property evaluates at that check;
- `(=> A B)` is overlapping implication: false A passes vacuously; true A
  activates/evaluates B from the same check stamp;
- `(next P)` evaluates P exactly one domain check later;
- `(within P MAX)` evaluates P at offsets 1 through MAX inclusive;
- `(within P MIN MAX)` evaluates P at offsets MIN through MAX inclusive; and
- the first true eligible sample passes; reaching the final eligible sample
  without truth fails.

An `await` with a plain Boolean reevaluates at each check until true or the
scenario deadline. An `await` with a temporal property creates one evaluator;
it does not restart the window each cycle. A named `expect` creates exactly one
outcome record and blocks its fiber until its immediate/temporal evaluator
passes or fails. Unknown known-only equality or arithmetic is an execution
error, not false.

At check, commit order is exact:

1. finish pending property/scoreboard evaluations;
2. record named expectation outcomes and diagnostics;
3. sample coverpoints and crosses;
4. resolve fiber completion, joins, and cancellation;
5. apply scenario timeout; and
6. commit scenario completion/final status.

An illegal coverage bin or check failure wins over completion at the same
logical stamp.

## Models, Scoreboards, Coverage, And Faults

### Deterministic models

Each event occurrence triggers its bound model rule during react. Occurrences
use logical-time/event order. Assignments inside one rule read one pre-rule
state snapshot and commit simultaneously; the next ordered occurrence sees
the committed state. Undeclared state, hidden I/O, randomness, time access,
host calls, or backend callbacks are impossible. Model outcome records contain
instance/state IDs, old/new normalized values, triggering event occurrence,
and logical time.

### Bounded scoreboards

Expected and actual queues are bounded by the declared capacity. `in_order`
compares queue heads as soon as both exist. `keyed` partitions by the declared
fully known scalar key and compares FIFO order within one key. Fields use
`same` semantics. Queue overflow, unknown key, duplicate impossible state, or
mismatch records a stable failure immediately. `scoreboard_check` also fails
if either queue has pending entries; there is no implicit end-of-scenario
drain or backend comparator callback.

### Coverage

Coverpoints sample at the declared domain's check phase after expectation
evaluation and before completion. One value may hit every explicitly matching
normal/illegal/ignore bin; no implicit bin exists. Normal and illegal hit
counts are recorded, ignore hits are recorded separately and excluded from
goals, and an illegal hit fails the scenario. A cross increments the exact
tuple of participating point-bin IDs observed at the same check. Only
statically materialized tuples within `max_bins` exist; no backend may expand
an implicit cross.

### Faults

`inject` arms a substitution fault in react. It becomes active at the next
drive, applies before the target transaction field is committed, remains
active for exactly its declared number of domain drive intervals, and then
expires. Injection while the same fault is active or already armed fails.
Only declared transaction-field substitution is supported. Raw HDL force,
hierarchy mutation, omission, delay, corruption policy, and protocol-event
faults remain outside the first execution profile.

## Deterministic Randomness And Replay

Version 1 resolves each referenced choice once per selected scenario during
elaboration. The occurrence ID is:

```text
decision/<fixture-id>/<scenario-id>/<authored-decision-id>/0
```

All references in the scenario, including nested fibers and repeats, reuse
that value. Reference fiber/action IDs are recorded for traceability but do not
change the value. This honors the source contract's scenario scope and removes
schedule order from randomization. Future per-call/dynamic decisions must use
a new profile whose occurrence identity includes fiber and call index.

The selected algorithm ID is
`sha256_counter_rejection_v1`. For a choice of declared width `W`, seed `S`,
occurrence UTF-8 bytes `O`, and zero-based attempt `A`:

1. Encode `S` as unsigned 64-bit big-endian, `len(O)` as unsigned 32-bit big-
   endian, `A` as unsigned 64-bit big-endian, and block index `B` as unsigned
   32-bit big-endian.
2. For `B = 0 .. ceil(W/256)-1`, compute:

   ```text
   SHA-256(
     "fsmgen.vial.random.sha256_counter_rejection.v1\0" ||
     S_u64be || len_O_u32be || O || A_u64be || B_u32be
   )
   ```

3. Concatenate digest bits in block order, retain the leftmost W bits, and
   interpret them as unsigned integer `X`.
4. Let `R = high - low + 1` and
   `L = 2^W - (2^W mod R)`. Reject when `X >= L`; otherwise propose
   `low + (X mod R)`.
5. Evaluate every authored constraint against the proposal. Accept only when
   all are true; otherwise increment `A` and repeat.

Attempt zero is the first attempt. More than 1,000,000 attempts fails with
`VIAL_RANDOM_EXHAUSTED`; it never falls back to modulo bias or a host PRNG.
The algorithm is defined over arbitrary-width integers, so it does not inherit
Perl, SystemVerilog, or VHDL machine-integer width. Backends receive only the
accepted normalized value and never rerun this algorithm.

Each decision record contains exactly:

```text
occurrence_id
declaration_semantic_id
decision_id
scenario_id
algorithm
seed
type_id
distribution
value
attempt
origin: generated | replayed
reference_operation_ids[]
source_location
```

`distribution` is the closed `{kind: uniform, low, high}` normalized record.
Reference operation IDs preserve static rank.

A replay manifest has exactly:

```text
schema: fsmgen.vial_replay.v1
schema_version: 1
replay_id
semantic_ir_id
bridge_manifest_id
fixture_id
scenario_ids[]
algorithm
decisions[]
```

`replay_id` is `replay/<sha256>` over the canonical record excluding
`replay_id`. Replay decisions use the exact decision record identity/type/
distribution/value fields; `origin` is not supplied. Binding rejects missing,
extra, duplicate, wrong-plan, wrong-algorithm, out-of-range, constraint-
violating, unknown, or non-normalized values. A replayed plan records origin
`replayed` and the supplied attempt for audit, but only value validity is
semantic.

## Typed Native-Extension Manifest

VIAL native extensions are not the current Perl extension objects and are not
anonymous raw target blocks. A descriptor is JSON-safe declarative data with
exactly:

```text
schema: fsmgen.vial_native_extension.v1
schema_version: 1
extension_id
semantic_family
semantic_node_ids[]
backend_profile_ids[]
lifecycle_hook
typed_inputs[]
typed_outputs[]
required_capabilities[]
effects[]
policy
fallback_semantic_id
shared_outcome_oracle_id
artifacts[]
source_location
```

`lifecycle_hook` is one of `elaborate`, `configure`, `drive`, `sample`,
`react`, `check`, or `finalize`. These are compiler logical seams. They do not
mean `build_phase`, `run_phase`, an objection, a VHDL process, or a simulator
callback. The backend chooses those mechanisms.

Each typed input/output record has exactly `name`, `type_id`, `source_kind`,
and `source_id`. `source_kind` is `configuration`, `endpoint`, `probe`,
`transaction`, `event`, `model_state`, or `extension_value`; access and type
must be valid at the selected hook.

Each effect is one of these closed records:

```text
emit_typed_output
notify_event
transform_declared_value
append_diagnostic
record_coverage
```

It carries `kind`, `target_id`, `phase`, `ordering`, and
`deterministic_contract`. An extension cannot mutate SemanticIR/ExecutionIR,
invent a DUT target, access undeclared hierarchy, alter scheduler state,
change another extension's output, perform undeclared I/O, or suppress a
diagnostic.

`policy` is:

- `required`: only listed backend profiles may run; behavior is native-only;
- `paired_portable`: every claimed backend supplies an implementation and the
  non-null shared outcome oracle enters parity; or
- `fallback`: a non-null portable `fallback_semantic_id` is used when the
  target profile lacks the native implementation.

`shared_outcome_oracle_id` is non-null only for `paired_portable`.
`fallback_semantic_id` is non-null only for `fallback`. Required capability
and profile lists are sorted unique and non-empty where policy requires them.

Each artifact record has exactly `artifact_id`, `target_language`,
`media_type`, `source_relpath`, `content_sha256`, and `byte_length`.
`source_relpath` is repository-relative and project data remains on the
repository volume. Contents are never embedded in the plan or result. Absolute
paths, home/cache discovery, environment lookup, network retrieval, code
references, blessed objects, and live host callbacks are forbidden.

The shipped VIAL source profile has no native-extension syntax/node, so the
first AHB plan's catalog and `native_extensions` array are exactly empty. This
contract supplies a safe carrier for later `.19` semantic-family work; it does
not widen `.3` or recreate SV/UVM/VHDL vocabulary.

## Private VIALExecutionIR Record

The private object contains exactly these top-level data keys:

```text
schema
schema_version
profile
plan_id
semantic_identity
bridge_identity
fixture
type_table
bindings
domains
transactions
events
models
scoreboards
coverage
faults
randomness
scenarios
operation_graph
capability_ledger
native_extensions
source_map
resource_summary
diagnostics
```

Values are closed normalized hashes/arrays. Success has `diagnostics: []`.
`schema` is `fsmgen.vial_execution_ir.v1`; versions are integers.

`semantic_identity` contains exactly `semantic_ir_id`, `schema_version`,
`profile`, `root_source_name`, `root_content_sha256`, and `selected_fixture_id`.
`semantic_ir_id` is `semantic/<sha256>` over canonical JSON of the complete
defensive SemanticIR data.

`bridge_identity` contains exactly `manifest_id`, `schema`, `schema_version`,
`profile`, `entry_source_id`, and ordered `review_artifact_ids`.

`fixture` contains the bound fixture/scenario selection and its stable source
location. `type_table` contains execution type IDs plus semantic/bridge type
links. `bindings` is divided into exact `unit`, `domains`, `endpoints`,
`probes`, `transactions`, and `events` arrays. Every executable semantic
reference has exactly one binding record.

The model, scoreboard, coverage, fault, randomness, scenario, and operation
families contain the executable normalized records selected above. Source map
records map each ExecutionIR field path to one or more SemanticIR source
locations and, when HIAL-derived, bridge source-map paths. No target artifact
location appears.

`plan_id` is `plan/<sha256>`. The digest input is canonical JSON of all
top-level data except `plan_id` and `diagnostics`, with `diagnostics` required
empty. Canonical JSON for every VIAL schema is UTF-8, recursively lexical key
order by Unicode code point, preserved array order, lowercase `true`/`false`/
`null`, base-10 integers without leading zeros, JSON escaping, and no
insignificant whitespace. Floating-point numbers do not occur.

The object is immutable. Scalar accessors return scalars; every structured
accessor and `as_hashref` returns a fresh deep clone. No object exposes its
backing hash, mutator, parser forms, SemanticIR/bridge internal object, target
backend object, code reference, filehandle, regex, absolute path, or blessed
foreign value.

## Sanitized `fsmgen.vial_plan.v1`

The plan projection has exactly these top-level keys:

```text
schema
schema_version
profile
plan_id
status
semantic_identity
bridge_identity
fixture
bindings
logical_time
scenarios
random_decisions
capability_ledger
native_extensions
resource_summary
source_map
diagnostics
```

`status` is `bound_target_neutral`. Success has empty diagnostics. The identity
records equal the private IR identity slices. The plan includes only logical
binding IDs and access/type summaries; it omits raw bridge target names,
private expressions, model implementation state, scoreboard queue contents,
native artifact contents, and backend paths.

`logical_time` contains exactly:

```text
domains[]
phase_order: [drive, sample, react, check]
tie_break_order: [domain_rank, static_operation_rank,
                  local_emission_index, semantic_id]
scenario_cycle_origin: 0
timeout_last_cycle_inclusive: true
```

Each scenario plan summary contains exactly `scenario_id`, `timeout_domain_id`,
`timeout_cycles`, `root_fiber_id`, `operation_count`, `fiber_count`,
`expectation_ids`, `scoreboard_instance_ids`, `coverpoint_ids`, `fault_ids`,
and `decision_occurrence_ids`. Arrays use authored/static order.

Plan random-decision records expose the exact algorithm, occurrence/declaration/
scenario IDs, seed, distribution, normalized chosen value, attempt, origin,
reference operation IDs, and source location. This is intentional replay data,
not a secret-bearing target randomizer. The target backend cannot change it.

Plan source-map records contain exactly `plan_path`, `semantic_path`,
`bridge_fact_paths`, and `source_locations`. All collections are non-null;
unused bridge paths are empty arrays. Locations are repository-relative and
use the SemanticIR span record. No private IR object or target-language span is
serialized.

The plan is fully defensive and JSON-safe as a whole. `.7` may return it in
process. `.8` alone decides whether and where `vial-plan.json` is written and
how it is discovered beside other verification artifacts.

## Normalized Verification Result Manifest

Every executable backend must produce one closed
`fsmgen.verification_result_manifest.v1` record for one plan execution. It has
exactly:

```text
schema
schema_version
result_id
plan_id
fixture_id
execution_profile
backend_profile
status
portable_parity_eligible
capability_evidence
scenario_results
random_decisions
events
drives
samples
transactions
expectations
models
scoreboards
coverage
faults
fibers
native_extensions
diagnostics
metrics
exclusions
parity_projection
parity_digest
backend_evidence
```

`status` is `pass`, `fail`, `timeout`, `cancelled`, `unsupported`, or `error`.
An aggregate pass requires every selected scenario to pass. A top-level
cancelled status is reserved for caller-requested cancellation; `parallel any`
losers are recorded in `fibers` and do not cancel a passing run.

`backend_profile` has exactly `id`, `target_language`, `methodology`,
`tool_name`, `tool_version`, `uvm_revision`, `vhdl_standard`, and
`capabilities`. Inapplicable scalar fields are null; capability IDs sort
lexically. A profile is a factual executed tool/profile identity, never the
string the caller hoped to run.

`capability_evidence` contains exact `required`, `satisfied`, `unsatisfied`,
and `native_only` arrays. An unsatisfied entry forces `unsupported` before
target emission; a backend must still be able to produce a diagnostic result
envelope for public tooling. It cannot produce `pass`.

Each scenario result contains exactly:

```text
run_id
scenario_id
status
start_time
end_time
completion_reason
expectation_ids[]
diagnostic_ids[]
cancelled_fiber_ids[]
logical_cycle_count
```

Logical times use the four-field record above. `completion_reason` is
`completed`, `expectation_failed`, `scoreboard_failed`, `illegal_bin`,
`timeout`, `cancelled`, `runtime_error`, or `unsupported`.

### Normalized result streams

All stream records contain `run_id`, a stable record ID, logical time, stable
semantic IDs, and closed kind-specific fields:

- `events`: handle/event ID and occurrence index;
- `drives`: endpoint/transaction-field ID, effective normalized value, and
  owning operation;
- `samples`: endpoint/probe ID and normalized value, but only samples consumed
  by an event/check/model/coverage/result oracle rather than every unreferenced
  DUT bit every cycle;
- `transactions`: handle/binding ID, immutable effective fields,
  request/accept/complete stamps, status, and correlation;
- `expectations`: expectation ID/name, property outcome, expected/actual values
  when applicable, activation/resolution stamps, and diagnostic ID;
- `models`: instance/state IDs, trigger occurrence, and old/new values;
- `scoreboards`: instance ID, operation `enqueue_expected`, `enqueue_actual`,
  `match`, `mismatch`, or `check`, key/value, queue depths, and outcome;
- `coverage`: point/bin/cross IDs, sampled value/tuple, hit kind, delta, and
  cumulative count;
- `faults`: fault/target IDs, `armed`, `applied`, or `expired`, original and
  substituted values when applicable;
- `fibers`: fiber ID, parent/cancel-scope ID, `started`, `completed`, `failed`,
  or `cancelled`, and cause/winner IDs; and
- `native_extensions`: extension/semantic-node/oracle IDs, declared typed
  outputs/effects, outcome, and profile identity.

Array order is logical-time tuple, then the selected tie-break tuple and stable
record ID. Per-family occurrence indices start at zero within one run. No
simulator timestamp or host sequence number replaces logical time.

`random_decisions` is copied from the plan and must match exactly. A target
runtime that chooses a different value is invalid even when its checks pass.

Diagnostics are closed records described below. Metrics contain only semantic
counts: logical cycles; event/drive/sample/transaction/check/model/scoreboard/
coverage/fault/fiber/native record counts; maximum live fibers; maximum
scoreboard depths; and result bytes. CPU time, wall time, RSS, simulator time,
license state, and host information belong in backend qualification evidence,
not portable metrics.

`backend_evidence` contains exactly `artifact_manifest_id`, `compile_id`,
`simulation_id`, `generated_artifact_sha256s`, `transcript_sha256`, and
`waveform_sha256`. Null is explicit when an artifact class is not produced.
Repository paths and raw tool chatter are absent. These hashes are diagnostic
evidence and are excluded from parity.

`result_id` is `result/<sha256>` over canonical JSON of the entire result
excluding `result_id`. Because backend evidence participates, two backends
normally have different result IDs even when their portable meaning agrees.
No wall-clock timestamp or nondeterministic host fact may enter the manifest.

## Portable Parity Projection And Report

`parity_projection` contains exactly:

```text
schema: fsmgen.vial_parity_projection.v1
schema_version: 1
plan_id
fixture_id
status
scenario_results
random_decisions
events
drives
samples
transactions
expectations
models
scoreboards
coverage
faults
fibers
native_extensions
exclusions
```

Only portable records and `paired_native` outputs with one shared outcome
oracle appear. Backend profile/tool/artifact identity, target names/paths,
native-only effects, transcripts, waveforms, CPU/wall time, RSS, simulator
time, and methodology plumbing do not appear. `parity_digest` is the lowercase
SHA-256 of canonical JSON for this exact projection.

`portable_parity_eligible` is true only when:

- plan IDs match the executed plan;
- every portable capability is satisfied;
- every equivalent-adapter requirement is satisfied;
- no required semantic outcome is native-only or excluded;
- every paired-native effect supplies the selected shared oracle; and
- the result schema/order/value validation succeeds.

An exclusion record contains exactly `semantic_id`, `reason`,
`portable_class`, and `capability_id`. Exclusions are honest explanation, not
permission to omit a required portable expectation. If an omitted record
affects scenario status, the result is `unsupported` or `error`, never pass.

Parity comparison produces `fsmgen.vial_parity_report.v1` with exactly:

```text
schema
schema_version
plan_id
baseline_result_id
candidate_result_id
eligible
equivalent
compared_paths[]
exclusions[]
mismatches[]
diagnostics[]
```

Both results must have the same plan ID and be parity-eligible. Comparison is
deep normalized field comparison in canonical order; matching digests are a
fast path, not permission to skip shape validation. Each mismatch contains
exactly `path`, `baseline`, `candidate`, `semantic_id`, and `logical_time`.
Generated text and waveform equivalence cannot override a semantic mismatch.

## Diagnostics

Binding/elaboration diagnostics contain exactly:

```text
schema_version: 1
severity: error
code
phase
message
semantic_path
source_location
bridge_fact_paths[]
related[]
```

Runtime/result diagnostics add `diagnostic_id`, `run_id`, `logical_time`, and
`backend_profile_id`; binding-only fields remain present as null/empty where
inapplicable. Messages are one-line target-independent text. Locations are
repository-relative. Related records are ordered closed hashes with message,
semantic path, bridge paths, and source location.

Selected codes are:

```text
VIAL_EXECUTION_INVOCATION_ERROR
VIAL_BIND_REFERENCE_ERROR
VIAL_BIND_TYPE_ERROR
VIAL_BIND_ACCESS_ERROR
VIAL_BIND_EVENT_ERROR
VIAL_CAPABILITY_ERROR
VIAL_SCHEDULE_CONFLICT
VIAL_TEMPORAL_FAILURE
VIAL_RANDOM_ERROR
VIAL_RANDOM_EXHAUSTED
VIAL_REPLAY_ERROR
VIAL_NATIVE_EXTENSION_ERROR
VIAL_EXECUTION_LIMIT_ERROR
VIAL_RUNTIME_ERROR
VIAL_RESULT_ERROR
VIAL_PARITY_ERROR
VIAL_EXECUTION_INTERNAL_ERROR
```

Diagnostics sort by source order, semantic path, bridge route/fact path,
logical time, and code. Independent binding errors may aggregate; dependent
cascades are suppressed. No Perl stack, object address, absolute path, target
source text, raw simulator diagnostic, host callback name, or methodology
plumbing leaks into the normalized message.

## Bounded Limits

Version 1 enforces limits before allocation/materialization where possible:

| Resource | Limit |
| --- | ---: |
| selected fixtures / units / domains | 1 / 1 / 1 |
| selected scenarios | 4,096 |
| expanded operations per scenario / total | 65,536 / 1,000,000 |
| total fibers / simultaneous live fibers | 65,536 / 16,384 |
| bindings / execution types | 65,536 / 65,536 |
| model instances / scalar state cells | 4,096 / 65,536 |
| scoreboard instances / total declared capacity | 4,096 / 1,000,000 |
| coverpoints / materialized bins and cross tuples | 65,536 / 1,000,000 |
| faults / random occurrences | 4,096 / 65,536 |
| native extension descriptors / artifacts | 256 / 1,024 |
| combined native descriptor/artifact identity bytes | 16,777,216 |
| source-map records | 1,000,000 |
| random attempts per occurrence | 1,000,000 |
| runtime stream records per family / total | 1,000,000 / 8,000,000 |
| serialized plan / result manifest | 16,777,216 / 67,108,864 bytes |

The semantic scenario timeout remains its explicit positive 32-bit cycle
bound. Result-stream caps can therefore fail a long execution before timeout;
that produces `VIAL_EXECUTION_LIMIT_ERROR` and an error result rather than
truncating parity data. These are safety limits, not `.17` scale
qualification or whole-product capacity claims.

## First AHB Binding And Plan Oracle

The checked source fixture must bind only to the implemented AHB bridge route:

```text
fixture:
  ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration
unit: unit/ahb_lite_subordinate
domain: domain/ahb_bus
public samples:
  endpoint/HREADYOUT endpoint/HRESP endpoint/HRDATA
probe sample:
  probe/reg_data_q
transaction:
  transaction/ahb_write
events:
  requested accepted captured held completed error
scenarios:
  success unsupported_size
```

The exact VIAL endpoint types/access, transaction field names/types, event IDs,
domain/reset facts, and probe access must match. The plan carries the probe's
equivalent-adapter requirement and cannot claim any backend eligible before
that adapter is supplied.

The success scenario has a fixed plan-time `success.wait_cycles` decision,
reset, expected transaction, one start, join-all over two ordered fibers,
five named expectations, and one explicit scoreboard check. The unsupported-
size scenario has reset, one armed substitution fault, one start, one temporal
await, and five named expectations. The effective error transaction has size
`#b111`; SemanticIR's authored start field remains `#b010` and is not mutated.

The event-counter models react to accepted/completed events, the in-order
scoreboard receives actual data only on completion, the stall coverpoint
samples at check, and the fault is active for exactly one drive interval. The
plan contains no native extension, target artifact, UVM/VHDL term, simulator
profile, runtime result, or parity claim.

Focused `.7` oracles must prove at least:

- every checked source bridge reference resolves exactly and all type/access/
  direction/event constraints hold;
- wrong route/profile/unit/domain/endpoint/probe/transaction/field/event/type/
  access/correlation/capability/residue input fails with stable diagnostics;
- logical phase/action/fiber/join-any/tie/cancel/reset/timeout/property/model/
  scoreboard/coverage/fault records are deterministic and source-mapped;
- random generation and replay match exact known vectors for multiple widths,
  rejection attempts, constraints, order permutations, and scenario subsets;
- caller input, ExecutionIR accessors, plan report, result-schema builders, and
  nested arrays/hashes are mutually defensive;
- canonical IDs/hashes are stable under Perl hash insertion order and change
  when a semantic input changes;
- every limit and malformed native descriptor/replay/result/parity record
  fails closed; and
- no public file/API, backend artifact, compile, simulation, UVM, VHDL,
  mixed-language, runtime pass, parity pass, or scale claim is emitted.

## Implementation Ownership And Non-Claims

Active `.7` owns private, no-backend implementation of:

```text
perl/FSM/VIAL/ExecutionBuilder.pm
perl/FSM/VIAL/ExecutionIR.pm
perl/FSM/VIAL/ExecutionReport.pm
private random/replay and schema-validation support
focused execution-contract regression
bounded private capability/support accounting
```

Exact file/package decomposition may be refined within `.7` without changing
the schemas or public/non-public boundary. `.7` must not write a plan/result
file, modify `.vial` syntax, change SemanticIR or bridge schema, emit target
verification code, compile/simulate, or claim runtime/parity. `.8` owns public
tooling and file placement; `.9` onward own backend contracts and execution.

This contract does not choose a UVM revision, simulator, VHDL methodology,
GHDL profile, mixed-language tool, clocking-block/process implementation, UVM
phase/objection mapping, factory/configuration mechanism, event/callback
implementation, or broader native semantic taxonomy. Those remain exact later
owners. In particular, a selected logical `finalize` hook is not an authored
UVM final phase, and a `required_from_backend` capability is not support.

Clean selection commit `eaf3f95dc` permits a separate continuity-only
activation of `.7`. Activation changes no binding, ExecutionIR, random/replay,
plan/result object or file, backend, runtime, or product behavior; exact
implementation remains unperformed until the activation commits cleanly.

Implementation audit `.7.1` then proved that the exact-equivalence rule above
cannot bind three fields of the checked fixture: VIAL `transfer` is an enum
while the bridge exposes its hardware carrier as logic, and VIAL `write` and
`wait_cycles` are two-state while their HIAL carriers are four-state logic.
The source and bridge contracts are each internally correct; this contract
omitted the semantic representation relation between them. Blocked `.7.2`
must resolve exact identity versus a closed proof-carrying directional
adapter before any binder is implemented. The current rule remains normative
and fail-closed until that decision commits.

## Validation And Rollback

Contract selection must pass current VIAL parser/SemanticIR and bridge evidence,
task-tree integrity, task/roadmap/audit/book/fact consistency, relative-path and
documentation audits, every mdBook chapter and the repository-local HTML
build, Knowledge Map generation/check, bounded Memory, diff, staged docs-only
acceptance, all doctrines, and exact repository-local output cleanup.

Rollback removes decision `0036`, this contract and its fact/book/roadmap/task
continuity, returns `.6` to active, and removes the `.7` selection. It changes
no VIAL source/parser/SemanticIR, HIAL bridge/parser/annotation/report,
generated HIAL artifact, public CLI/API/file, backend, compile, simulation,
runtime, parity, UVM/VHDL/mixed-language, or product behavior.
