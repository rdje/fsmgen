# HIAL/VIAL Verification Architecture

FSMGen has selected the architecture for its verification-intent language and
future generated executable fixtures. This chapter explains the shipped
semantic frontend and public source tooling, the shipped private HIAL bridge
producer, the executable destination, and the compatibility boundary. It does
**not** mean generated or runnable VIAL backend output ships today.

The current shipped verification-output targets remain deliberately narrow:

- `uvm-passive-monitor` emits inert UVM 1.2 snapshot and passive-monitor class
  declarations;
- `vhdl-observation-package` emits an inert VHDL metadata package; and
- neither target drives a DUT, samples a transaction stream, runs a scenario,
  compares expected outcomes, scoreboards, covers behavior, or injects faults.

The selected architecture closes that gap in exact later slices while keeping
the current IAL routes stable.

## Two peer intent systems

**Hardware IAL (HIAL)** is the collective architecture name for FSMGen's
existing synthesizable stack:

```text
IAL2 (.ppif) -> generated IAL1 (.isf) -> generated IAL0 (.fsm) -> HDL
```

IAL0, IAL1, IAL2, their suffixes, commands, diagnostics, and review artifacts
do not change names. HIAL continues to describe hardware behavior and lowers
to synthesizable targets.

**Verification IAL (VIAL)** is the peer system for non-synthesizable fixture
intent. Its job is to describe stimulus, scenarios, observations, expected
outcomes, models, scoreboards, coverage, faults, and deterministic execution
around a HIAL-generated DUT.

The selected topology is:

```text
public .vial source
        |
        v
private immutable VIALSemanticIR
        |
        +---- versioned HIALVIALBridgeManifest <---- HIAL review route
        |
        v
private immutable VIALExecutionIR
        |
        +---- sanitized vial-plan.json
        |
        +---- backend artifacts
        |
        v
normalized verification-result-manifest.json
```

There are not three public VIAL0/VIAL1/VIAL2 languages. HIAL's three layers
are useful hardware authoring levels, whereas verification declarations, DUT
binding, scenarios, concurrency, checking, models, coverage, and methodology
are orthogonal. One `.vial` language keeps those concerns composable; private
compiler phases preserve strict boundaries without forcing users to choose an
artificial source level.

## Shipped bounded VIAL version-1 semantic frontend

The source/semantic-IR contract, parser, and first checked source now ship as a
semantic-only frontend. VIAL version 1 uses closed S-expressions and a
dedicated source-span-aware parser. It deliberately does not expose the
repository's legacy raw Lispish arrays: exact byte/line/column provenance,
stable semantic IDs, deterministic diagnostics, and later replay/source maps
are language requirements.

Every file contains one versioned package with explicit sections:

```lisp
(vial
  (version 1)
  (package example
    (imports)
    (types
      (enum state_t (logic 2)
        (idle #b00)
        (busy #b01)))
    (transactions)
    (models)
    (scoreboards)
    (fixtures ...)))
```

Imports are repository-relative and explicitly qualified. The parser receives
their bytes from an in-memory source catalog; it does not search the current
directory, home caches, temporary directories, or the network.

The first profile, `core_directed_single_clock_v1`, selects enough meaning for
one bounded AHB arbitration source:

- `bool`, unsigned/signed two-state vectors, unsigned/signed four-state
  vectors, enums, records, and bounded lists;
- typed transactions and opaque unbound HIAL bridge references with expected
  types and `public_port`/`verification_probe` access assertions;
- deterministic event-driven models and bounded in-order/keyed scoreboards;
- explicit coverpoints/cross caps, bounded transaction-field substitution
  faults, seed plus stable random decision IDs;
- timeout-bounded scenarios, literal-bounded repeats, and deterministic
  `parallel all`/`parallel any` fibers; and
- typed observations, event counts, expectations, and waits.

Four-state `#b` literals normalize to value bits, a known mask, and a Z mask;
target syntax is not semantic truth. There is no implicit truncation,
signedness conversion, overflow wrap, or X/Z-to-two-state coercion. `same`
means exact four-state equality, while `value_eq` requires known numeric or
Boolean operands.

VIAL does not create another property language. Its expectations and waits
reuse the canonical `=>`, `next`, and one-/two-bound `within` operators already
selected for verification properties. New temporal operators must extend the
shared property contract rather than appear only in VIAL.

The first checked source is
`vial/ahb_subordinate_base_output_arbitration.vial`. It represents success
and unsupported-size scenarios, a transaction, event counters, a bounded
scoreboard, stall coverage, one bounded size-substitution fault, and stable
wait-cycle decision identity. The public tool can check either source
projection, produce a sanitized semantic report, format normal or terse
source, and bind it to reviewed HIAL through `plan`. Generated target fixtures,
simulation, and results remain later phases. See
the exact [VIAL source and SemanticIR v1 contract](../../VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md).

The public source-only commands are:

```console
$ ./bin/fsmgen vial capabilities
$ ./bin/fsmgen vial check vial/ahb_subordinate_base_output_arbitration.vial
$ ./bin/fsmgen vial check --json vial/ahb_subordinate_base_output_arbitration.vial
$ ./bin/fsmgen vial format --style terse vial/ahb_subordinate_base_output_arbitration.vial
```

`check --style normal|terse` additionally asserts the input projection;
`auto` is the default. `format --style normal|terse` always writes canonical
UTF-8/LF source to stdout and never writes a repository artifact. The closed
in-memory API uses `fsmgen.vial_tool_request.v1` and
`fsmgen.vial_tool_result.v1`; it accepts only JSON-safe source catalogs and an
empty source-tooling artifact sink, never callbacks, filehandles, raw parser
forms, or private IR objects.

Success returns stable source identity, package/fixture/declaration summaries,
unresolved typed bridge references, and exactly these capabilities:
`vial.source.v1`, `vial.semantic_ir.v1`, and
`vial.profile.core_directed_single_clock_v1` from the semantic report, plus
the separately discovered public source-tooling capabilities. Diagnostics retain Unicode-aware
source spans and stable semantic paths. Independent invalid declaration or
fixture containers are reported in authored order; validation suppresses
dependent cascades and never exposes partial IR. The source is 4,986 bytes / 123
lines with SHA-256
`2205b3b4f073a61374b19cb72f06afe31d75fc4d88f903c414b9b28a744ca4cd`.

The CLI resolves repository-relative imports into the same closed source
catalog used by the API. Absolute/traversing/symlink source paths fail before
access. Source tooling emits no bridge, plan, target code, simulation, or
result artifact.

## The two private IR boundaries

`VIALSemanticIR` owns parsed, typed, validated verification meaning before it
is attached to a concrete DUT. It contains reusable types, transactions,
scenarios, models, expectations, coverage definitions, fault definitions, and
source identity. It is not HIAL source, SourceHIR, scheduled hardware, or a
public serialization contract.

`VIALExecutionIR` owns the fully bound and capability-checked execution plan.
Every DUT reference has resolved through the bridge; logical clock phases,
scenario fibers, timeouts, checks, models, scoreboards, coverage state, native
extension hooks, and backend requirements are explicit. It is also private.

Public reports are bounded sanitized projections. Raw IR object structure is
not an API, and callers do not receive mutable compiler-owned data.

### Current type-binding decision boundary

Implementation audit found one unresolved semantic seam before the private
execution binder can ship. The checked VIAL transaction uses an enum for
`transfer`, Boolean for `write`, and unsigned `u(4)` for `wait_cycles`; the
HIAL bridge correctly describes all three hardware carriers as four-state
logic. The former execution-contract wording demanded exact type identity, so
those three fields could not bind honestly.

Decision `0037` resolves this deliberately fail-closed boundary with three
proof-carrying directional relations. `bit_domain_identity_v1` covers equal
state domain/width/signedness for drive or sample.
`known_value_injection_v1` lets a known two-state value drive a same-width/
signed four-state carrier with all known bits and no Z.
`enum_encoding_injection_v1` preserves an enum's exact authored base-bit
encodings. The latter two are drive-only; four-state-to-two-state sampling,
X/Z collapse, width/sign conversion, and implicit expression casts remain
forbidden.

That keeps Boolean/numeric/enum intent in VIAL and hardware representation in
HIAL—the same “simpler language above backend assembly” boundary described in
this chapter. Clean selection commit `2a1b3cefc` permitted `.7.3` to own the
first private binder after separate continuity activation. `.7.3` now ships
that private binder and defensive in-process plan; it does not expose a public
tool or write a plan file.

## The HIAL/VIAL bridge

`HIALVIALBridgeManifest` is the portable DUT-binding authority. Its versioned
schema must publish stable logical identities and source maps for:

| Family | Bridge facts |
| --- | --- |
| Identity | HIAL source kind, repository-relative source identity, generated `.isf`/`.fsm` review identities, content identities |
| Units | logical unit IDs, module/entity bindings, hierarchy/composition identity |
| Configuration | parameters/generics, resolved values, types, provenance |
| Types | widths/ranges, signedness, enums/records, two-state/four-state value policy |
| Endpoints | direction, type, unit/interface owner, semantic role, target port names |
| Time domains | clocks, edges, resets, polarity, synchronization policy |
| Transactions/events | fields, request/accept/complete/sample events, ordering and correlation |
| Protocol facts | profile/version, channel roles, timing/value facts, retained unsupported residue |
| Observations/probes | IAL1 observations, public-port sets, declared verification probes |
| Bindings/capabilities | SystemVerilog and VHDL target bindings, required profile capabilities |
| Source map | every published fact back to HIAL source and review artifacts |

The bridge has three access classes:

1. `public_port` is the mandatory portable baseline.
2. `verification_probe` is declared by HIAL and carries explicit profile
   support. It is portable only where claimed backends provide equivalent
   semantics.
3. `native_hierarchy` is backend-specific and usable only through a typed
   native extension. It cannot establish a portable parity claim.

For IAL2, protocol facts may enter the bridge only after they are present in
or deliberately annotated onto generated IAL1 review artifacts. VIAL does not
add a direct PPIF-to-verification backend or a second protocol truth source.

### Selected bridge version 1

Decision `0035` selects schema
`fsmgen.hial_vial_bridge_manifest.v1` and initial profile
`core_single_unit_v1`. The bridge accepts three reviewable routes:

| Authored source | Required route |
| --- | --- |
| IAL0 `.fsm` | authored IAL0 review source |
| IAL1 `.isf` | authored IAL1 then generated IAL0 review source |
| IAL2 `.ppif` | authored IAL2, generated and reparsed IAL1, then generated IAL0 |

The IAL2 route cannot pass its parser object or report directly to the bridge.
Protocol meaning that is not already ordinary IAL1 is rendered into an
additive actor metadata form:

```lisp
(verification-bridge
  (domain ahb_bus)
  (protocol ahb_lite_subordinate
    (profile ahb)
    (revision ARM-AMBA-AHB-IHI0033-C-2021-09)
    (role subordinate)
    (facts
      (fact supported_transfer 2'b10)
      (fact error_completion two-cycle)))
  (transaction ahb_write
    (fields
      (field address HADDR drive address_phase)
      (field data HWDATA drive data_phase))
    (events
      (event requested scenario_start drive)
      (event accepted predicate sample
        (& HSEL HREADY (== HTRANS 2'b10)))
      (event completed predicate sample HREADYOUT)
      (event error predicate sample (== HRESP 1'b1))))
  (probe reg_data_q read_only))
```

The generated IAL1 is parsed and validated normally; this metadata produces a
schedule-report projection but no hardware state or HDL behavior. Direct IAL0
publishes structural unit, configuration, type, endpoint, and domain facts
only. Direct IAL1 can additionally publish its transactions and existing
`(observe ...)` declarations. Protocol roles, events, probes, and residue are
never guessed from signal names.

The checked AHB route publishes the IDs already named by the checked VIAL
source: `unit/ahb_lite_subordinate`, `domain/ahb_bus`, the
`endpoint/HREADYOUT`, `endpoint/HRESP`, and `endpoint/HRDATA` public ports,
`transaction/ahb_write`, six named lifecycle events, and
`probe/reg_data_q`. The probe is an adapter-required declaration, not a raw
SystemVerilog/VHDL hierarchy path or an added public DUT port.

Manifest records include content-addressed sources/review artifacts, stable
semantic IDs, normalized four-state types/values, target module/entity/port
names, capabilities, unsupported residue, and an RFC-6901 source map for every
semantic field. Source spans are exact only when the owning parser supplies
them; otherwise the bridge says `semantic_path` with null span fields instead
of inventing precision.

The first implementation leaf `.5` is deliberately private and in-process.
It now returns immutable defensive manifest/report data and writes no bridge
file. Public CLI/API and `hial-vial-bridge.json` discovery remain owned by
`.8`; VIAL binding, execution plans, generated verification code, compilation,
simulation, and parity remain later leaves. See the complete
[bridge v1 contract](../../HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md).

### Using the shipped private producer

The implementation has three closed entrypoints, one for each canonical HIAL
review route:

```perl
use FSM::HIAL::VIALBridge::Builder;

my $result = FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1({
    profile => 'core_single_unit_v1',
    authored_source => $exact_ppif_identity,
    generated_ial1 => {
        source => $exact_generated_isf_identity,
        actor => $reparsed_actor,
        schedule_report => $decoded_schedule_report,
    },
    generated_ial0 => $exact_generated_fsm_identity,
    backend_names => $validated_sv_and_vhdl_names,
});

die $result->{diagnostics}[0]{message} unless $result->{ok};
my $manifest = $result->{manifest}; # private immutable object
my $report   = $result->{report};   # full defensive JSON-safe copy
```

Each source identity contains exact bytes, a repository-relative path or null
for a virtual generated artifact, its basename, SHA-256, byte length, and line
count. The builder verifies those values instead of trusting caller labels.
It accepts no PPIF AST/report shortcut and no absolute, home-relative,
temporary, network, or raw-hierarchy identity.

The checked AHB report contains, among its other mandatory families:

```json
{
  "schema": "fsmgen.hial_vial_bridge_manifest.v1",
  "profile": "core_single_unit_v1",
  "entry_source_id": "source/authored",
  "review_route": {
    "authored_layer": "IAL2",
    "direct_ial2_to_verification": false,
    "stages": [
      { "layer": "IAL2", "source_id": "source/authored" },
      { "layer": "IAL1", "source_id": "source/generated_ial1" },
      { "layer": "IAL0", "source_id": "source/generated_ial0" }
    ]
  },
  "transactions": [
    {
      "transaction_id": "transaction/ahb_write",
      "type_id": null,
      "protocol_id": "protocol/ahb_lite_subordinate"
    }
  ],
  "probes": [
    {
      "probe_id": "probe/reg_data_q",
      "access": "verification_probe",
      "adapter_requirement": "equivalent_adapter_required"
    }
  ]
}
```

The excerpt omits mandatory keys only for readability; the actual report is a
closed 27-key manifest projection. Transaction `type_id` is null because this
first profile admits scalar fields but no aggregate transaction record; each
field carries its exact logical type. Event predicates use recursive,
backend-neutral `kind`, `operator`, `operands`, `value`, `reference_kind`, and
`semantic_id` records—not rendered SV/VHDL expressions.

Discoverability does not promote the producer to a supported embedding API.
`./bin/fsmgen --capability-manifest` reports
`language_surface.hial_vial_bridge.status` as
`shipped_private_in_process`, `writes_files: false`, and
`public_embedding_api: false`. The support-accounted AHB fixture lists only
its five exercised bridge capabilities and repeats the no-bind/no-plan/no-
runtime/no-methodology claims.

## Portable verification meaning

The portable language must cover these semantic families:

| Family | Required meaning |
| --- | --- |
| Values/types | booleans, bounded integers, two-/four-state scalars and vectors, enums, records, lists, transactions |
| Binding | bridge unit, endpoint, domain, transaction, configuration, and capability references |
| Stimulus | typed drives and transactions, reset actions, waits, bounded faults |
| Scenarios | reusable procedures, ordered steps, bounded loops, timeouts, setup/teardown |
| Concurrency | deterministic logical fibers, join policies, cancellation, stable tie-breaking |
| Observation/checking | explicit samples, predicates, temporal windows, counts, stable/changed checks, expected streams |
| Models/scoreboards | pure functions, declared deterministic state, in-order/keyed/bounded-unordered matching |
| Coverage | points, bins, transitions, crosses, illegal/ignore bins, goals, exact counts |
| Randomization | explicit seeds, domains/distributions/constraints, stable decision IDs, replay records |
| Diagnostics | source span, scenario/fiber/event, logical time, expected/actual, profile, stable code |

Coverage crosses and scoreboard queues must be explicitly bounded. Portable
logic distinguishes two-state and four-state values; a backend may not
silently coerce unknowns or target-specific logic states.

## Logical time and reproducibility

Decision `0036` now selects private `fsmgen.vial_execution_ir.v1` and initial
profile `core_directed_single_clock_execution_v1`. It is a target-neutral
operation graph: one checked fixture is bound by exact semantic ID and
structural type to one checked bridge. A backend receives that graph; it cannot
reinterpret raw SemanticIR or bridge data independently.

Portable time is the tuple `(domain, cycle, phase, ordinal)`. Cycles and
ordinals start at zero, and phase order is exact:

1. `drive`: apply verification-controlled values before the active edge;
2. `sample`: capture one stable post-edge DUT snapshot and bridge events;
3. `react`: update event counts, models, scoreboards, faults, and scenario
   control; and
4. `check`: resolve properties, coverage, joins/cancellation, timeout, and
   completion.

Stable operation/fiber ranks and local emission indices decide same-time ties.
SystemVerilog scheduling regions, UVM callbacks/phases, VHDL processes/delta
cycles, and host threads may implement the phases, but none has portable
semantic authority.

For example, this VIAL sequence:

```lisp
(reset bus 3)
(scoreboard_expect writes (fields ...))
(start request write (fields ...))
(parallel any
  (fiber completed
    (await (within (event request completed) 1 256)))
  (fiber failed
    (await (within (event request error) 1 256))))
```

becomes ordered reset drive/sample intervals, one react-phase expected enqueue,
one drive-phase transaction start, and two statically ranked property fibers.
If both fibers resolve at one check stamp, the lower authored fiber rank wins;
the loser is cancelled before another action, without undoing effects already
committed.

Random choices are resolved once during plan elaboration, not independently by
each simulator. `sha256_counter_rejection_v1` hashes the source-defined seed
and scenario-scoped occurrence ID into arbitrary-width unbiased candidates,
rejects out-of-range or constraint-failing values, and stores the accepted
normalized value in the plan. Every backend consumes that value. A strict
`fsmgen.vial_replay.v1` record must match every occurrence exactly—no missing,
extra, wrong-type, or constraint-breaking replay entry is accepted.

A capability ledger distinguishes semantics already satisfied by this target-
neutral profile from requirements a backend must supply. The checked AHB
storage probe therefore yields a valid bound plan with an explicit equivalent-
adapter requirement, not a false runtime-support claim. A backend without that
adapter cannot emit a runnable artifact. The selected result-manifest and
parity-report schema names are likewise future contracts, not `.7.3`
capabilities: their first implementation owners remain `.10` and `.11`.

## Shipped private execution elaboration

Implementation `.7.3` now realizes that contract in-process. The private
`FSM::VIAL::ExecutionBuilder` consumes exactly one checked `VIALSemanticIR`,
one defensive `HIALVIALBridgeManifest`, one fixture ID, authored-order scenario
IDs, the exact execution profile, an optional strict replay record, and a
closed native-extension catalog. Success returns an immutable defensive
`VIALExecutionIR` plus a sanitized `fsmgen.vial_plan.v1` hash. It writes no
file and is not yet a supported public embedding API or CLI.

For the checked AHB source, elaboration proves all ten directional relations,
expands both scenarios to 21 static operations in four total fibers, and finds
three as the maximum simultaneously live fibers. The bound resources include
two scalar model-state cells, one scoreboard with declared capacity four, two
materialized coverage bins, and one plan-time random occurrence. The success
choice is resolved once and both authored uses point to the same occurrence:

```text
schema: fsmgen.vial_plan.v1
status: bound_target_neutral
profile: core_directed_single_clock_execution_v1
logical phases: drive, sample, react, check
random algorithm: sha256_counter_rejection_v1
native extensions: []
diagnostics: []
```

Event expressions are rebound to logical execution bindings. Bridge-only AHB
event inputs become explicit transaction-adapter inputs, and the internal
capture predicate becomes an opaque adapter-state binding; neither the actor's
storage spelling nor an HDL literal survives in ExecutionIR. Scenario-handle
event references, sampled endpoints, enum members, and random choices are all
resolved before execution. The sanitized plan omits private event expressions
and all target/methodology spelling.

The private implementation fails atomically—no partial IR or plan—on unresolved or
wrong-access references, disallowed type direction, missing event, unknown
capability, non-empty first-profile native catalog, bad scenario selection,
invalid replay identity/value/constraint, random exhaustion, or a safety-limit
violation. Completed `.10.2` now invokes this compiler elaboration behind a
closed public planner and serializes only sanitized projections. There is still
no result file, generated SV/UVM/VHDL fixture, compile, simulation, runtime,
parity pass, mixed-language claim, or scale qualification. The public API does
not expose this private elaborator or its IR objects.

## Shipped public source and planning tooling

Decision `0039` selects one intent-oriented command family without exposing
private compiler objects:

```text
fsmgen vial capabilities
fsmgen vial check source.vial
fsmgen vial format --style normal|terse source.vial
fsmgen vial plan --dut dut.ppif source.vial
fsmgen vial run --dut dut.ppif --backend PROFILE source.vial
```

The first three commands ship through `.10.1`, and `plan` ships through
`.10.2`. `run` remains unavailable until `.10.3`/`.10.4` implement the backend,
trace, tool execution, and result owners; asking for it returns
`VIAL_BACKEND_UNAVAILABLE` without writing an artifact. The CLI is an adapter
over the same closed, JSON-safe request/result contract available to embedding
hosts.

The source and DUT are deliberately separate. The VIAL file says how to verify
meaning; `--dut` names the HIAL source that supplies ports, transactions,
events, domains, and probes. A `.ppif` DUT is not handed directly to a
verification backend: FSMGen first generates and reparses IAL1, then generates
IAL0, and only the review-routed HIAL bridge may bind the VIAL plan.

All three canonical HIAL entry routes are supported. Direct IAL0 has structural
unit/domain/endpoint truth but no transaction contract, so it can plan a
transaction-free reset/sample/check fixture. A transaction-bearing fixture
must bind direct IAL1 metadata or IAL2 protocol facts that have first become
reviewable generated IAL1. This is capability honesty, not name inference.

Normal and terse VIAL are reversible views of the same semantics. Normal form
is fully explicit:

```text
(vial
  (version 1)
  (package demo
    (imports)
    (types (type data_t (logic 32)))
    (transactions)
    (models)
    (scoreboards)
    (fixtures ...)))
```

Terse form removes only closed structural wrappers:

```text
(vial 1
  (package demo
    (type data_t (logic 32))
    (fixture ...)))
```

It does not infer types, values, clocks, timeouts, seeds, DUT bindings, or
target behavior. Formatting either view and reparsing it must produce the same
semantic meaning digest; source hashes and spans remain different and honest.
This is what “terse or normal” means in VIAL: less ceremony, never less
meaning. Both forms enter the same existing typed `SemanticBuilder`; there is
no second terse semantic pipeline.

Check a normal source without generating a DUT, plan, or HDL:

```console
$ ./bin/fsmgen vial check vial/ahb_subordinate_base_output_arbitration.vial
VIAL check passed (normal_v1)
```

Format that source into terse form on standard output:

```bash
./bin/fsmgen vial format --style terse \
  vial/ahb_subordinate_base_output_arbitration.vial
```

`check --style normal|terse` can require an exact authored style; a mismatch
is `VIAL_SOURCE_STYLE_ERROR`. `capabilities --json` and `check --json` return
the closed public result envelope. Formatting intentionally returns source
text rather than mixing JSON with authored VIAL. These source operations read only
repository-root-relative, non-symlink `.vial` files and write nothing.

Plan the checked AHB fixture against its canonical IAL2 source:

```console
$ ./bin/fsmgen vial plan \
    --dut ppif/ahb_lite_subordinate.ppif \
    vial/ahb_subordinate_base_output_arbitration.vial
VIAL plan planned (.artifacts/vial/base-output-arbitration/<full-plan-digest>)
```

The action publishes only reviewable projections:

```text
.artifacts/vial/<fixture>/<full-plan-digest>/
  vial-tool-manifest.json
  source/vial-normal.vial
  review/...
  hial-vial-bridge.json
  vial-plan.json
```

The selected tree is repository-local, same-volume, content-addressed, and
committed atomically. Failed planning leaves no partial tree; a non-identical
existing tree is never overwritten. Repeating the same plan against the exact
tree returns `unchanged`; it does not rewrite files. Generated IAL1 and IAL0
sources appear below `review/`, while a direct IAL0 source is referenced by
identity/digest and is not copied as a generated artifact. The first bounded
direct-IAL0 route accepts one root `.fsm`; package imports fail closed until a
later slice defines their complete review graph.

Embedding callers choose an exact `artifact_policy`: `virtual` returns the
same ordered graph in an initially empty caller-owned sink, while `repository`
delegates atomic publication to a filesystem adapter such as the CLI. The
optional artifact root is always repository-relative; null selects the default
content-addressed root. Every artifact has exact content metadata. The tool
manifest inventories every artifact except itself, because a self-hash would
be recursively undefined; exact-tree validation still includes the manifest
file. Neither mode exposes Perl objects or absolute host paths.

Existing `.isf` UVM/VHDL skeleton commands and their
`verification-output-manifest.json` version 1 stay unchanged. A future VIAL
`run` uses explicit manifest schema
`fsmgen.verification_output_manifest.v2`; consumers select by schema rather
than guessing from the shared filename. The full normative field, diagnostic,
compatibility, and rollback contract is
[VIAL Public Tooling Version 1](../../VIAL_PUBLIC_TOOLING_V1_CONTRACT.md).

## Expressive ceiling: verification intent, not synthesis

The governing rule is **full power underneath, simpler intent above**. VIAL
covers expressive verification use cases enabled by qualified targets; it does
not expose every target-language or methodology concept.

For VIAL, **abstraction means simplification**. You do not need to know
SystemVerilog, UVM, or VHDL to learn the language and obtain an efficient
implementation for a qualified target. VIAL teaches verification intent; the
compiler owns target syntax, methodology plumbing, scheduling conventions, and
artifact construction. Generated target code stays readable for diagnosis,
but it is output—not prerequisite knowledge for authoring the input.

The useful analogy is C/C++ or Rust compiling to assembly: SV/UVM/VHDL are
VIAL's backend target languages. You can inspect the generated artifacts when
integrating or debugging them, aided by stable names and source maps, without
writing or mentally executing VIAL in target-language terms. No one backend's
idioms define VIAL semantics.

HIAL is intentionally limited to intent that can become synthesizable HDL.
VIAL is not. Its portable core is an initial interoperable profile, not the
language definition or its permanent ceiling. Native profiles may express the
full selected verification semantics of SystemVerilog/UVM or VHDL when an
exact methodology/tool capability is qualified.

That does not mean recreating SV/UVM/VHDL with parentheses. A VIAL construct
must expose, compose, or compress verification intent; a one-to-one catalog of
renamed target classes, methods, statements, or syntax is rejected. For
example, VIAL event-callback intent describes interception, filtering,
ordering, lifecycle, reentrancy/cancellation, transformation, and observation.
The UVM backend may realize that intent with `uvm_event` and
`uvm_event_callback`, but those target classes are mappings rather than VIAL's
semantic definition.

Lifecycle follows the same rule. VIAL states construction/configuration/
readiness dependencies, stimulus start, background-service lifetime,
completion and drain conditions, shutdown, finalization order, deadlines, and
failure policy. The UVM backend owns phase selection, raise/drop objections,
and phase-transition plumbing; authored VIAL does not expose `run_phase`,
`raise_objection`, `drop_objection`, or `phase.jump()`.

The same principle permits typed intent for stimulus orchestration,
producer/observer communication, implementation selection/substitution,
scoped configuration, register behavior, constrained decisions, coverage,
properties, and timed interface interaction. Sequences/sequencers,
drivers/monitors, TLM, factories/config DB, RAL, randomization/coverage/
assertion facilities, and virtual interfaces/clocking remain possible backend
mechanisms rather than automatic VIAL vocabulary. Terse authored forms and a
verbose normal form must lower to the same typed SemanticIR; terseness removes
ceremony, never meaning. A backend without an exact native mapping rejects the
required capability before output instead of silently weakening it. Decision
`0034` owns this long-term boundary; the bounded v1 profile remains unchanged.

## Native extensions

Portable `.vial` does not embed anonymous raw SystemVerilog/UVM or VHDL
blocks. Decision `0036` selects declarative
`fsmgen.vial_native_extension.v1`; it is deliberately unrelated to FSMGen's
current Perl extension objects and live mutable hook contexts. A native
implementation is an external repository-relative, content-addressed artifact
with a typed contract containing:

```text
extension identity
backend profile identities
lifecycle hook
typed inputs and outputs
required capabilities
source path, span, and content identity
declared deterministic effects
required, paired-portable, or fallback policy
shared outcome oracle where parity is claimed
```

Hooks are the closed logical family `elaborate`, `configure`, `drive`,
`sample`, `react`, `check`, and `finalize`. They are compiler seams—not UVM
phase names, objections, VHDL processes, or host callbacks. Effects are limited
to typed output, event notification, declared-value transformation, diagnostic,
and coverage records. Extensions cannot mutate private IR, invent hierarchy,
perform undeclared I/O, or suppress failures.

The first checked source declares no native semantic node, so its plan contains
no extension. Later native-family work can attach efficient target-specific
implementations without turning VIAL into a catalog of renamed SV/UVM/VHDL
mechanisms.

## Backend profiles and honest claims

| Profile | Intended target | Qualification boundary |
| --- | --- | --- |
| `sv_portable_verilator` | plain SystemVerilog fixture without UVM | exact Verilator version; compile, elaborate, and run with `--binary --timing`; only exercised supported capabilities |
| `sv_uvm_qualified` | native UVM components, sequences, monitors, scoreboards, coverage | named simulator/version and selected UVM revision; full compile/elaborate/run evidence |
| `vhdl_portable_ghdl` | VHDL-2008 packages, processes, and testbench | installed GHDL/version with `--std=08`; explicit language/PSL limits |
| `vhdl_methodology_qualified` | VHDL plus a selected methodology provider | exact provider/revision and compatible simulator; OSVVM/UVVM mapping selected later |
| `mixed_language_qualified` | HIAL and VIAL in different HDLs | named mixed-language tool/version and binding adapter; never inferred from single-language success |

Plain SystemVerilog/Verilator is first because the existing AHB fixture proves
the relevant timed behavioral substrate locally without requiring UVM.
Verilator with `--timing` is an event-capable compiled simulator for the
features it supports; it is not evidence of complete SystemVerilog or UVM
support.

Decision `0043` selects the exact version-1 profile. The compiler partially
evaluates the bound plan into a small runtime package plus one fixture module;
it does not emit a general interpreter or make the author write target code.
One scheduler uses the clock's inactive edge as a stable barrier:

```text
inactive edge:
  sample the state produced by the preceding active edge
  run react and check in the plan's exact rank order
  apply the next logical cycle's drive values
active edge:
  the DUT consumes those values and settles before the next sample
```

That arrangement preserves VIAL's logical `drive → sample → react → check`
meaning without asking an author to understand SystemVerilog event regions,
clocking blocks, or race-avoidance idioms. Declared HIAL verification probes
are reached through generated, source-mapped adapters; raw hierarchy still
cannot appear in VIAL source.

The first factual tool gate is Verilator 5.046 (2026-02-28). Its core command
profile is:

```text
verilator --binary --timing --assert -j 1 --threads 1 \
  --x-initial 0 --x-assign 0 --timescale 1ns/1ps \
  --top-module GENERATED_TOP --Mdir REPOSITORY_LOCAL_OBJDIR SOURCES...
```

Compilation, executable creation, runtime exit, trace closure, result-schema
validation, and semantic scenario status are separate gates. Build objects
stay in an exact repository-local staging tree and are removed after the
atomic public result graph validates.

The profile has an important, explicit boundary: it is a **known-value
runtime**, not complete four-state verification. Authored X/Z-sensitive
values or checks fail backend negotiation. Sample results retain VIAL's
normalized value shape, but this profile reports all sampled bits as known and
cannot prove that a DUT never produced X/Z. A later full four-state backend may
disagree, and parity must report that mismatch. A Verilator pass can never
override it or imply full-SystemVerilog/UVM support.

The simulator emits a closed, prefixed line-delimited JSON trace. The host
validates its plan/run identities, sequence, logical ordering, counts, and
footer, then projects it into `fsmgen.verification_result_manifest.v1`. It
does not rerun VIAL scheduling, models, scoreboards, coverage, faults, or
random decisions. See the
[portable SystemVerilog backend contract](../../VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md)
for exact artifacts, mappings, source maps, limits, diagnostics, non-claims,
and implementation gates.

The current UVM 1.2 output does not silently choose the future UVM revision.
The VHDL lane does not claim analysis, simulation, complete VHDL-2019, PSL, or
methodology support until its exact profiles run. Mixed-language support is a
separate qualification.

## Cross-backend result parity

Every executable backend must build the selected closed
`fsmgen.verification_result_manifest.v1`. Equivalent portable intent agrees on:

- source, bridge, plan, scenario, and profile identities;
- seeds and stable random-decision identities and values;
- logical domain-cycle/phase and event identities;
- driven, sampled, and transaction values;
- check, temporal, model, and scoreboard outcomes;
- coverage hit counts and goals; and
- timeout, cancellation, completion, unsupported exclusions, and final state.

The manifest includes backend/tool/artifact evidence, but parity compares only
its canonical `fsmgen.vial_parity_projection.v1`: portable or paired-native
logical outcomes in deterministic order. The projection has a SHA-256 digest;
`fsmgen.vial_parity_report.v1` still validates and deeply compares both shapes
rather than trusting a digest alone. Native-only exclusions are explicit and
cannot hide an omitted required portable check.

Generated source text can differ across languages. Simulator timestamps,
waveforms, host timing, target paths, UVM/VHDL plumbing, and transcripts remain
diagnostic evidence; none is the portable semantic oracle. The complete record
shapes, random byte encoding, action/property timing, diagnostics, limits, and
AHB oracle are in the
[VIAL execution v1 contract](../../VIAL_EXECUTION_IR_V1_CONTRACT.md).

## Mapping the AHB arbitration fixture

The architecture audit uses
`t/data/ahb_generated_subordinate_base_output_arbitration_tb.svt` as its
worked input. The mapping below is conceptual, not accepted `.vial` syntax:

| Handwritten construct | Portable meaning | Boundary |
| --- | --- | --- |
| clock toggle and reset task | bridge-bound clock plus reusable reset procedure | generated backend process |
| public AHB signals | typed endpoints and an AHB write transaction | protocol facts remain reviewable through IAL1 |
| edge-triggered counters | sample-phase events and counters | portable |
| drive IDLE after acceptance | drive-phase reaction to sampled acceptance | portable |
| bounded wait loops | scenario waits with explicit timeout and termination | portable unless raw hierarchy is used |
| HREADYOUT/HRESP/HRDATA checks | public-port expectations | portable |
| `$fatal` and `$display` | typed diagnostics and normalized metrics | backend text is not parity |
| internal capture/hold/completion state | named HIAL verification probes | qualified only where equivalent adapters exist |
| raw pending/storage hierarchy | native hierarchy | prefer public completion/readback or declared architectural-state probes |

The portable oracle uses bus behavior: one acceptance, a visible stall,
response timing, data behavior, completion/ready return, and a follow-up read
or declared state probe. Raw internal counters remain useful diagnostics, but
cannot be called cross-backend portable.

## Migration and current boundary

The migration order is additive:

1. keep all current HIAL names and synthesized behavior unchanged;
2. keep IAL1 checks/properties on the existing HIAL property route;
3. treat `(observe ...)` as an initial bridge observation source, not a VIAL
   scenario language;
4. preserve the current UVM/VHDL target IDs, paths, manifest contract, and
   explicit non-claims until their migration owners act;
5. add versioned bridge, plan, artifact, and result reports without exposing
   raw IR;
6. keep `.ppif` verification output unsupported; and
7. keep native extensions typed, external, capability-qualified, and reported.

The selected implementation order is source/semantic-IR contract and
implementation, bridge contract and implementation, execution/result/parity
contract and implementation, public tooling, plain-SystemVerilog backend, AHB
runtime parity, then separately qualified UVM, VHDL, mixed-language, scale,
and closeout work. Each leaf requires its own clean activation and acceptance
evidence. The canonical architecture record is
[HIAL/VIAL Verification Fixture Architecture Audit](../../HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md),
and the owning [task tree](../../tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md)
tracks the exact frontier.

The bounded source/SemanticIR, private bridge, and private execution-
elaboration implementations are complete. Public tooling contract `.8` is
also complete as selection only.
Bridge leaf `.5` ships the 27-key defensive in-process manifest through
canonical HIAL review routes without writing a file or binding VIAL. Completed
`.6` accepts decision `0036` and the exact target-neutral execution contract:
binding, logical phases, actions/fibers, plan-time random/replay, declarative
native implementations, plan/result/parity records, diagnostics, limits, and
the AHB oracle. Proposed `.7` is selected next for separate clean activation of
private no-backend implementation. Clean selection commit `eaf3f95dc` permits
that continuity-only activation, which committed cleanly at `3ec8eab93`.
Audit `.7.1` then confirmed that the exact type-identity rule could not bind
the checked enum/Boolean/unsigned transaction fields to three HIAL four-state
logic carriers. Director-approved decision `0037` and `.7.2` select the
directional proof rule described above. Clean selection commit `2a1b3cefc`
activated `.7.3`, which now ships the private binder, immutable ExecutionIR,
deterministic random/replay elaboration, defensive in-process plan, exact
resource accounting, and fail-closed contract oracles. Clean `.7.3`
implementation commit `44dbecd1a` activates `.8` continuity-only for public
tooling-contract selection. Decision `0039` now freezes `fsmgen vial`, exact
normal/terse equivalence, separate VIAL/HIAL inputs, the portable API,
repository-local atomic artifacts, manifests, discovery, diagnostics, and
compatibility. Clean `.8` selection commit `d34da3254` activates `.9` alone
for the separate plain-SystemVerilog/Verilator backend-contract selection.
Decision `0043` and completed `.9` now select the exact deterministic known-
value contract described above. Clean `.9` commit `ab3e73b72` activates `.10`
alone for implementation. Clean activation commit `5fd766600` then decomposes
that parent into `.10.1` public capabilities/check/normal-terse formatting,
`.10.2` canonical planning and artifact transactions, `.10.3` portable backend
emission and trace projection, and `.10.4` exact Verilator run/results. `.10.1`
now ships the first three source commands, equivalent normal and terse
projections, the defensive source-only API, and exact discovery and support
accounting. Clean `.10.1` commit `50a0d7d39` activates `.10.2` alone for
planning/artifacts. Completed `.10.2` now ships all three canonical review
routes, defensive bridge/plan/tool-manifest projections, transaction-free
direct-IAL0 endpoint fixtures, and virtual or atomic repository-local artifact
graphs. `.10.3` is the next backend/trace owner; `.11` retains runtime parity.
No target backend artifact, result file, compile/run path, runtime result,
parity pass, or backend behavior ships in `.10.2`.
