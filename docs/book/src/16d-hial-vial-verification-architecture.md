# HIAL/VIAL Verification Architecture

FSMGen has selected the architecture for its verification-intent language and
future generated executable fixtures. This chapter explains the shipped
semantic frontend and public tooling, the shipped private HIAL bridge producer,
the shipped portable-SystemVerilog/Verilator execution path, and the
compatibility boundary. Public `run`, exact external compilation, simulation,
closed runtime traces, and normalized results now ship for the bounded
`sv_portable_verilator` profile. The selected AHB fixture now has bounded
runtime parity with its handwritten oracle; general cross-backend parity does
**not** ship yet. Native UVM now has an exact open-source-first architecture
and deterministic emission of the selected topology, lifecycle,
notification/interception, stimulus, TLM, factory/configuration, RAL,
constrained-decision, coverage, property, model, scoreboard, fault,
diagnostic, and result-collection structures; its parse, compile, elaboration,
runtime, and produced-result profiles do not ship yet. A separately identified
Verilator/UVM experiment now supplies partial feasibility evidence without
changing that product-support boundary.

Completed native-UVM emission slice `.13.1.5` closes the selected mapping
matrix, examples, deterministic review workflow, and deferred-runtime defect
boundary without waiting for a simulator. Visual review and every parser-
through-runtime qualification state remain independent and honestly pending.

Completed experimental slice `.13.2` now ships a reusable exact open-source
probe and checked evidence. Its isolated UVM control compiles, elaborates, and
runs; the generated fixture remains tool-limited before runtime. This is
explicitly experimental evidence, not a supported native-UVM execution
profile.

Completed slice `.14` now selects the VHDL-2008 verification contract. The
portable core is provider-free, OSVVM 2026.05 is the exact advanced-methodology
provider, and GHDL 6.0.0 is the first exact qualification tool. UVVM was
audited but is not selected. Completed `.15.5` now qualifies the exact official
macOS ARM64 GHDL 6.0.0 LLVM-JIT package through analysis, elaboration, bounded
execution, normalized results, and applicable portable-SV parity. OSVVM remains
separately isolated from that provider-free qualification; completed `.15.6`
now installs its exact recursive 2026.05 graph and emits the advanced adapter.
Completed `.15.7` qualifies their bounded combination through provider
compilation, adapter/fixture analysis, execution, unchanged result/parity,
supplementary reports, deterministic rerun, and cleanup.

Implementation parent `.15` is active and decomposed. Completed `.15.1` now
ships the provider-free emitter substrate and first deterministic review
gallery. Completed `.15.2` adds typed drivers and samplers, the single
inactive-edge scheduler, bounded scenarios and fibers, deterministic models,
and a declared-probe adapter. Completed `.15.3` adds bounded scoreboards,
coverage counters, substitution faults, procedural checks, diagnostics,
closed trace framing, and normalized-result projection. Completed `.15.4`
closes the portable review matrix. Completed `.15.5` qualifies the available
exact official macOS ARM64 GHDL 6.0.0 LLVM-JIT package. Completed `.15.6`
installs exact recursive OSVVM 2026.05 and emits its isolated advanced adapter;
completed `.15.7` qualifies the combined exact tuple. NEXSIM-dependent
runtime qualification is director-deferred until capability-ready releases
provide exact evidence.

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

Semantic IDs follow the language's uniqueness scopes. Package, declaration,
fixture, and scenario IDs remain readable named identities. Handles and
expectations add their scenario ID because their names may be reused in another
scenario. Fibers add their scenario plus canonical structural path because a
parallel action has no authored name and fiber names are local to one parallel.
This prevents two legal local declarations from collapsing into one trace,
result, or replay key.

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
source, bind it to reviewed HIAL through `plan`, and execute the bounded
portable profile through `run`. The run path publishes generated target
fixtures, runtime evidence, and normalized results as described below. See
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
closed public planner and serializes only sanitized projections. Completed
`.10.3` passes the exact immutable ExecutionIR, reviewed bridge, and normalized
generated HIAL SystemVerilog to the private portable emitter. Completed
`.10.4` composes those private seams behind public `run`, executes the exact
qualified Verilator profile, and publishes the normalized result. There is
still no parity pass, complete four-state, mixed-language, or scale
qualification. The public API does not expose either private elaborator or its
IR objects.

## Shipped public source, planning, and execution tooling

Decision `0039` selects one intent-oriented command family without exposing
private compiler objects:

```text
fsmgen vial capabilities
fsmgen vial check source.vial
fsmgen vial format --style normal|terse source.vial
fsmgen vial plan --dut dut.ppif source.vial
fsmgen vial run --dut dut.ppif --backend PROFILE source.vial
```

The first three commands ship through `.10.1`, `plan` ships through `.10.2`,
private backend emission/trace validation ships through `.10.3`, and `run`
ships through `.10.4`. The CLI is an adapter over the same closed, JSON-safe
request/result contract available to embedding hosts. Only
`sv_portable_verilator` is currently accepted by `run`; any other backend ID
fails atomically before compilation.

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

A failure after staging begins removes the exact operation-owned staging tree
before returning its diagnostic, so the same operation can retry without
residue blocking atomic publication.

Embedding callers choose an exact `artifact_policy`: `virtual` returns the
same ordered graph in an initially empty caller-owned sink, while `repository`
delegates atomic publication to a filesystem adapter such as the CLI. The
optional artifact root is always repository-relative; null selects the default
content-addressed root. Every artifact has exact content metadata. The tool
manifest inventories every artifact except itself, because a self-hash would
be recursively undefined; exact-tree validation still includes the manifest
file. Neither mode exposes Perl objects or absolute host paths.

Existing `.isf` UVM/VHDL skeleton commands and their
`verification-output-manifest.json` version 1 stay unchanged. A VIAL
`run` uses explicit manifest schema
`fsmgen.verification_output_manifest.v2`; consumers select by schema rather
than guessing from the shared filename. The full normative field, diagnostic,
compatibility, and rollback contract is
[VIAL Public Tooling Version 1](../../VIAL_PUBLIC_TOOLING_V1_CONTRACT.md).

Run the checked AHB fixture with the exact qualified backend:

```console
$ ./bin/fsmgen vial run \
    --dut ppif/ahb_lite_subordinate.ppif \
    --backend sv_portable_verilator \
    vial/ahb_subordinate_base_output_arbitration.vial
VIAL run executed (.artifacts/vial/base-output-arbitration/<full-plan-digest>)
```

The run tree contains the plan graph plus generated SystemVerilog, exact
compile/run command records, the executed tool profile, normalized compile and
run transcripts, validated JSONL, backend/output manifests, and one
content-addressed `verification-result-manifest.json`. Both the `success` and
`unsupported_size` scenarios must pass. Repeating the same run produces the
same bytes and returns `unchanged`; a failed tool, trace, schema, scenario, or
publication gate leaves no partial output tree.

## Shipped portable-SystemVerilog emission and execution

Completed `.10.3` adds the first target-producing compiler seam without making
that seam a public authoring API. The planner privately retains three exact,
defensive inputs after successful binding:

```text
immutable VIALExecutionIR
reviewed HIALVIALBridgeManifest
normalized generated HIAL SystemVerilog source
```

`FSM::VIAL::Backend::SVPortableVerilator->emit(...)` accepts only those inputs,
the exact `sv_portable_verilator` profile, and a repository-relative artifact
root. It negotiates the bounded one-unit/one-domain known-value profile before
producing anything. Unsupported capabilities, native extensions, unsafe paths,
missing DUT source, unknown values, or backend-limit overflow return one
sanitized diagnostic and no partial graph.

Successful emission returns one deterministic virtual graph, sorted by path:

```text
backends/sv_portable_verilator/
  backend-manifest.json
  backend-source-map.json
  commands/compile-command.json
  commands/run-command.json
  evidence/tool-profile.json
  src/<fixture>_tb.sv
  src/dut/<generated-hial-dut>.sv
  src/fsmgen_vial_runtime_pkg.sv
```

The emitter remains a private virtual seam: calling it alone does not publish
or execute either command record. Its emission-only manifest therefore says
exactly
`emission: passed`, `compile: not_run`, `runtime: not_run`,
`result: not_produced`, and `parity: not_evaluated`. The selected Verilator
5.046 profile and repository-local object path are reviewable data, not
execution evidence until the runner qualifies them.

The fixture source is static partial evaluation of the immutable plan rather
than a general VIAL interpreter. It contains meaningful generated identifiers,
one declared-probe alias, operation-local comments, statically folded known
values and selected faults, and a source map covering every operation and
stateful semantic family. The HIAL generator's date comment is normalized at
the private handoff so identical source meaning yields byte-identical backend
artifacts across days.

One generated scheduler remains the execution authority. It waits at the
domain's inactive edge, samples, performs react/check work in plan order, and
prepares the next drive. `parallel all` and `parallel any` children are
materialized as condition bits whose satisfaction is latched in that same
scheduler loop. A target-language `fork` cannot introduce a second ordering
authority or make simulator process scheduling part of VIAL meaning.
For `parallel any`, authored child order breaks a same-barrier tie: exactly one
child is the completed winner and every non-winner is recorded as cancelled.

The emitted runtime package defines the closed prefixed JSONL representation.
The pure
`FSM::VIAL::Backend::TraceValidator` accepts only caller-supplied trace bytes,
the exact ExecutionIR, and a simulator exit code. It requires canonical JSON,
contiguous sequence numbers, exact plan/run/scenario identities, closed record
kinds, ordered scenario boundaries, monotonic logical time, matching footer
counts, and clean termination within the selected record/byte limits. Success
returns `fsmgen.vial_sv_trace_projection.v1`. The validator checks a trace
envelope and projects it—it never replays scheduling, models, scoreboards,
coverage, faults, or random decisions.

`FSM::VIAL::Backend::Runner` verifies the complete command-record digests and
exact qualified argv, stages generated inputs only below the repository,
checks the exact Verilator 5.046 identity, and enforces independent version,
compile, executable, runtime, trace, result, and cleanup gates. Compile and run
output are capped; both processes are timed; timeout or overflow receives a
bounded process-group termination before cleanup. Operation staging must not
pre-exist and is removed before the runner returns.

`FSM::VIAL::Backend::ResultProducer` consumes only the validated trace and
immutable execution authority. It publishes scenario outcomes and normalized
events, drives, samples, transactions, expectations, models, scoreboards,
coverage, faults, and fibers, plus metrics and a canonical parity projection.
The projection makes a later comparison possible; `.10.4` does not perform or
claim that comparison.

Backend-only caps remain in the backend capability contract rather than
ExecutionIR's `limits`. This preserves the target-neutral plan identity:
selecting a SystemVerilog emission limit cannot silently change the semantic
plan that a future VHDL or UVM backend consumes.

## Native Intent Abstraction simulation direction (proposed)

`IASIM-EXECUTABLE-REFERENCE-SEMANTICS` parks a future Intent Abstraction
Simulator; it is not active or shipped. IASIM would execute HIAL design intent
and VIAL verification intent directly through one canonical native execution
model, with semantic adapters for IAL2, IAL1, and IAL0. HDL generation and
external simulation would remain separately comparable deployment and backend-
qualification routes, not the definition of native Intent Abstraction meaning.

The proposed definition-oriented IASIM reference kernel is Perl 5 first. That
choice favors direct correspondence with the semantic contract and the current
FSMGen implementation while remaining fast enough until representative xIAL
profiling proves a concrete bottleneck.

IASIM does not need a wholesale Rust rewrite. A measured bounded hotspot may
later move behind a stable versioned C ABI into a Rust-built shared library
called by Perl. Perl remains the semantic orchestrator and reference route;
ownership plus error and panic boundaries must be explicit, and every
accelerated route must reproduce the pure-Perl normalized result
deterministically.

Native IASIM signoff would require a precise versioned semantics, independent
definition-oriented oracles, manually derived vectors, property/metamorphic and
bounded exhaustive tests, cross-level direct-versus-lowered equivalence,
deterministic replay, semantic coverage, and seeded-defect detection. Passing
IASIM would not by itself prove generated HDL syntax, standards conformance,
elaboration, runtime behavior, or external-simulator parity.

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
| `sv_uvm_emit.accellera_2020_3_1` | deterministic native UVM packages, interfaces, selected topology/lifecycle/notification structures, and source maps | exact Accellera source identity and artifact/static-structure gates; compile/elaborate/run/result explicitly not run |
| `sv_uvm_experimental.<tool-and-version>` | optional open-source feasibility probe | exact tool/version and measured deviations; never product runtime support |
| `sv_uvm_qualified` | executable native UVM components, sequences, monitors, scoreboards, coverage | future exact PGEN parser + NEXSIM simulator tuple; parse/compile/elaborate/run/result gates |
| `vhdl_portable_ghdl` | provider-free VHDL-2008 packages, scheduler, adapters, testbench, trace/result | exact GHDL 6.0.0 with `--std=08`; analyze/elaborate/run/result/parity and explicit language/PSL limits |
| `vhdl_osvvm_qualified` | same VIAL semantics plus negotiated advanced OSVVM services | exact OSVVM 2026.05 plus GHDL 6.0.0 LLVM-JIT; 61-source provider compile, bounded fixture/probe runtime, unchanged result/parity, four supplementary reports |
| `vhdl_*_qualified.<tool-id>` | portable or OSVVM graph under another VHDL simulator | exact tool/version/build, standard/options, provider where applicable, result/parity gates |
| `mixed_language_qualified` | HIAL and VIAL in different HDLs | named mixed-language tool/version and binding adapter; never inferred from single-language success |

Plain SystemVerilog/Verilator is first because the existing AHB fixture proves
the relevant timed behavioral substrate locally without requiring UVM.
Verilator with `--timing` is an event-capable compiled simulator for the
features it supports; it is not evidence of complete SystemVerilog or UVM
support.

## Selected VHDL-2008 architecture

The VHDL backend has two tiers because portability and methodology breadth are
different claims.

`vhdl_portable_ghdl` is ordinary IEEE VHDL-2008. It uses
`std_logic_1164`, `numeric_std`, and `textio`, plus FSMGen-generated packages,
adapters, and a testbench. It does not require OSVVM or UVVM. This small core
owns the portable drivers, samplers, deterministic scenario scheduler, models,
bounded scoreboards, coverage counters, faults, procedural checks, trace, and
normalized result.

`vhdl_osvvm_qualified` adds OSVVM only for negotiated advanced needs such as
provider-native randomization, coverage, scoreboards, reporting,
synchronization, data structures, and verification components. OSVVM cannot
rerandomize the portable plan's pre-resolved decisions, move a logical phase
barrier, change comparison or coverage meaning, or replace the normalized
FSMGen result.

The exact selected identities are:

```text
GHDL 6.0.0
  tag: v6.0.0
  commit: e589c698c351369ac5bcfe7abe1f1152ac5d4727

OSVVM 2026.05
  commit: 2f7c391051dfb11890fa4bdbda9918d1db492250

UVVM 2026.03.20 (audited, not selected)
  commit: 4f1e13bf96dca5571597ca7416b9340e9de94efd
```

Selecting one provider avoids two overlapping generated adapter systems and
two qualification matrices. It does not declare UVVM inferior or permanently
unsupported; a future UVVM profile needs its own explicit identity and
evidence.

The checked OSVVM materialization is not a shallow source snapshot. It contains
the superproject and all 13 recursive gitlinks under the repository-derived
`.artifacts/cache/providers/osvvm/2026.05/source` root. Each repository is
verified by commit, tree, origin, tracked-entry count, and clean worktree. The
inventory locks 14 Apache-2.0 licence files and finds no notice file. The
pinned `Documentation` repository itself has no tracked licence or notice
file; FSMGen preserves that upstream absence and does not infer coverage.

The advanced gallery is additive:

```text
backends/vhdl_osvvm_qualified/
  backend-manifest.json
  backend-source-map.json
  evidence/{provider-materialization,advanced-mapping-matrix}.json
  evidence/{semantic-preservation,source-order,static-validation}.json
  evidence/{tool-profile,qualification-reference}.json
  src/fsmgen_vial_osvvm_adapter_pkg.vhd
  src/portable/<six byte-identical portable VHDL sources>
```

Seven mappings cover `RandomPkg`, `CoveragePkg`, `ScoreboardGenericPkg`,
`AlertLogPkg`, `TbUtilPkg`, `MemoryPkg`, and
`osvvm_common.AddressBusTransactionPkg`. Seven adapter entries precede all 59 detailed
portable entries translated to wrapper paths and identities. This 66-entry closure
preserves replay, phase order, comparison/coverage meaning, trace, and normalized results through twelve structural checks and six guards; a malformed map leaves no graph in
authority. Check the exact 16-artifact graph with:

```text
perl scripts/refresh_vial_vhdl_osvvm_gallery.pl --check
```

This command verifies materialization and emitted bytes without fetching the
network or rerunning a simulator. The graph references the separate checked
combined report; structure alone is still not execution evidence.

Completed `.15.7` resolves the exact provider order to 44 OSVVM core and 17
VHDL-2008-compatible Common sources. It analyzes the adapter and generated
fixture, elaborates and runs the fixture and provider probe twice, validates
the unchanged closed 42-record trace, passing normalized result, and nineteen
portable parity paths, then compares four OSVVM YAML reports byte-for-byte.
The probe runtime-exercises randomization, coverage, scoreboard, reporting,
memory, and barrier mappings. The Common address-bus type is analysis-only;
no provider verification-component transaction is claimed. Rerun the exact
proof from the repository root:

```text
scripts/run_with_ram_guard.sh --process-max-rss-mb 4096 -- \
  perl scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl --check
```

### Logical time without delta-cycle folklore

For the first rising-edge profile, one generated scheduler uses the falling
edge as the stable barrier:

```text
falling edge N:
  sample the state produced by rising edge N
  react and check in exact plan-rank order
  prepare drives for rising edge N+1

rising edge N+1:
  the DUT consumes the prepared drives
```

VHDL process wake-up order, delta order, protected-type arbitration, and
OSVVM component scheduling are implementation details. They do not decide
which fiber wins, when a timeout occurs, or which value a scoreboard sees.
Multi-clock and asynchronous profiles require later exact contracts.

### Four-state values over `std_logic`

VIAL drives strong `0`, `1`, `X`, and `Z` values. Sampling normalizes the nine
`std_logic` symbols explicitly:

| `std_logic` sample | VIAL value | Additional evidence |
| --- | --- | --- |
| `0`, `1`, `Z` | same value | strong value |
| `L`, `H` | `0`, `1` | original weak symbol retained |
| `U`, `X`, `W`, `-` | `X` | original symbol retained |

This preserves the VIAL four-state oracle without pretending that version 1
has nine distinct authored values. A fixture that must distinguish all nine
symbols fails capability negotiation.

### Drivers, checking, coverage, and results

A VIAL author still writes verification intent, not VHDL. FSMGen statically
partially evaluates that intent into readable named procedures, records,
state tables, and one scheduler. Public DUT ports bind directly. A declared
internal probe requires an explicit generated and source-mapped adapter or a
verification-only instrumented HIAL variant; authored external names and raw
hierarchy are not the portable mechanism.

The provider-free tier implements bounded queues and comparisons for portable
scoreboards and explicit counters for portable coverage. The OSVVM tier may
map an exact advanced scoreboard to `ScoreboardGenericPkg`, coverage to
`CoveragePkg`, and a native random requirement to `RandomPkg`. Provider HTML,
JUnit, or transcript reports are useful supplementary evidence. Parity still
uses `fsmgen.verification_result_manifest.v1`.

Portable VIAL properties lower to procedural checks. PSL is not required or
emitted by version 1 because GHDL documents only a subset. A future PSL
profile must name the exact tool, flags, directives, operators, and restrictions
it exercised.

### Artifact and migration boundary

The selected portable graph is separate from synthesizable HIAL VHDL:

```text
backends/vhdl_portable_ghdl/
  backend-manifest.json
  backend-source-map.json
  commands/{analyze,elaborate,run}-command.json
  evidence/{tool-profile,transcripts,runtime-trace}
  src/dut/<unit>.vhd
  src/fsmgen_vial_{types,runtime}_pkg.vhd
  src/<fixture>_metadata_pkg.vhd
  src/<fixture>_probe_adapter.vhd        # only when required
  src/<fixture>_tb.vhd
results/<result-id>/verification-result-manifest.json
```

Every non-boilerplate generated region maps back to VIAL source, semantic
identity, execution operation/rank, and bridge binding where applicable.
Repeated helpers live in shared packages; the backend does not emit one opaque
interpreter or duplicate a complete helper library per scenario.

The old `vhdl-observation-package` command remains an unchanged inert
compatibility surface. Its package still has no entity, process, assertion,
PSL, analyzer, simulator, scoreboard, or coverage claim. Native VIAL emits a
different metadata package under a different profile and manifest; the old
package is neither rewritten nor consumed.

### Exact qualification boundary

The selected command shape uses GHDL `-a`, `-e`, and `-r` with `--std=08`, an
explicit work library, and a repository-local work directory. The installed
tool must report exactly version 6.0.0; its build backend and complete version
output become evidence. Analyze, elaborate, bounded run, closed trace,
normalized result, semantic outcomes, rerun, parity, and cleanup are separate
gates.

Completed `.15.5` materializes the exact 37,155,806-byte macOS ARM64 LLVM-JIT
archive (SHA-256
`c21312d5a0cc5833e6d8690d8c4343e67f4fc32f070c07343816cd11a31c7769`)
under the repository-derived provider cache. Its selected binary is SHA-256
`38a99c1cc18b04dfae128b118c7344910e08b8ba6eeb9c1e67f950a84bca3c3d` and
reports GHDL 6.0.0, commit `e589c698c351369ac5bcfe7abe1f1152ac5d4727`,
with the LLVM JIT backend. The combined qualifier independently re-verifies
the recursive OSVVM release, every submodule identity, licences, and notices
under its repository-derived dependency root before provider compilation.

The checked qualification runner analyzes all six gallery sources plus a
standalone timed four-state probe, elaborates both tops, runs the fixture and
probe twice, and removes its exact same-volume work library. The fixture emits
one closed 42-record trace and a passing normalized result. Its success and
unsupported-size scenarios match nineteen applicable paths in the already
qualified portable-SV AHB oracle; the `0/1/X/Z` probe also repeats
byte-identically. Run the checked proof from the repository root:

```text
scripts/run_with_ram_guard.sh --process-max-rss-mb 4096 -- \
  perl scripts/run_vial_vhdl_portable_ghdl_qualification.pl --check
```

The profile names its backend deliberately. The exact GHDL 6.0.0 LLVM AOT
package analyzes and elaborates this fixture but dereferences null when the
VHDL-2008 external-name adapter runs. Only LLVM-JIT is qualified.

### Shipped provider-free VHDL semantics

The private backend handoff now carries deterministic generated HIAL VHDL
beside its existing SystemVerilog source. The VHDL record fixes the semantic
unit, entity, `.vhd` filename, source identity, exact bytes, byte count, and
SHA-256 digest; public plan artifacts remain target-neutral and unchanged.

The emitter now produces this exact fourteen-artifact graph:

```text
backends/vhdl_portable_ghdl/
  backend-manifest.json
  backend-source-map.json
  commands/{analyze,elaborate,run}-command.json
  evidence/{source-order,static-validation,tool-profile}.json
  src/dut/ahb_lite_subordinate.vhd
  src/fsmgen_vial_{types,runtime}_pkg.vhd
  src/base_output_arbitration_metadata_pkg.vhd
  src/base_output_arbitration_tb.vhd
  src/base_output_arbitration_probe_adapter.vhd
```

The types package defines VIAL `0/1/X/Z`, execution phases, and an observation
record that retains the original `std_logic` symbol. Its normalization maps
strong `0/1/Z` directly, weak `L/H` to `0/1`, and every remaining symbol to
`X`. The runtime package defines logical cycle/phase/rank/index and lifecycle
types. The metadata package freezes plan, fixture, bridge, unit, domain,
active/inactive-edge, and reset identities.

The testbench declares every bridge-proved endpoint and binds the generated
HIAL entity through a named port map. Its typed strong drivers use the same
four-state value type as expected data, while every sampler retains both the
normalized value and original `std_logic` symbol.

One clock process supplies physical time. One semantic scheduler owns logical
execution. Its nested barrier waits for the selected falling inactive edge,
then performs `sample`, `react`, `check`, and `drive` in that fixed order. A
delta count, zero-time wait, or process scheduling race is never semantic
authority.

The metadata package carries all 21 exact operation identities and static
ranks, both 256-cycle scenarios, four fibers, and two event-counter model
instances. The scenario process maintains bounded lifecycle state and updates
the models deterministically from transaction events.

Completed `.15.3` adds a capacity-four in-order scoreboard with explicit
overflow, comparison, mismatch, and empty-result invariants; the authored
`not_stalled` and `stalled` coverage counters; and the one-cycle
unsupported-size field-substitution seam without mutating the authored
transaction. Procedural checks record success, ERROR, timeout,
declared-probe, and unknown-value evidence in a bounded diagnostic family.
Provider-free `textio` emits closed header/body/footer framing and the
`fsmgen.verification_result_manifest.v1` projection. The projection carries
every normalized top-level family, per-scenario status/time, aggregate
scoreboard/coverage/fault metrics, and stored diagnostic codes, outcomes, and
logical times. It deliberately leaves produced identity and parity fields
empty. JSON strings use VHDL quote doubling; C-style escapes fail structural
validation. Trace non-closure and result inconsistency are generated failures.
PSL and methodology-provider requests remain unsupported.

The sixth source is a source-mapped VHDL-2008 external-name adapter for the one
bridge-declared `reg_data_q` probe. Generated hierarchy is forbidden anywhere
else; ordinary DUT access remains through public named ports.

Completed `.15.4` changes the manifest and machine-readable capability state
to `emitted_structurally_reviewed_unqualified`. Twenty static checks prove the
closed graph, deterministic provider-neutral source, typed value handling,
single inactive-edge authority, phase order, exact ranks, bounded scenario and
fiber metadata, deterministic model updates, and declared-probe-only
hierarchy—not VHDL syntax or execution. Negotiation also rejects nine-state,
multi-domain, and asynchronous semantic-event requests.

Three additional canonical JSON artifacts close review without changing the
six generated VHDL sources or 59 source-map entries. The 24-row selected
mapping matrix gives 20 portable responsibilities exact emitted role evidence
and gives four excluded boundaries one exact unsupported reason each: OSVVM-
native services, PSL, distinct nine-state VIAL meaning, and multi-clock or
asynchronous execution. Each row distinguishes public normal/terse source,
compiler-owned ExecutionIR or bridge data, and unavailable private previews.

| Matrix group | Exact selected responsibilities | Entry ownership |
| --- | --- | --- |
| values and binding | typed four-state values, original-symbol sampling, typed logical time, fixture metadata, HIAL DUT binding, public-port binding, declared probe adapter | compiler or bridge derived; no invented target-language authoring |
| execution | typed drivers, inactive-edge scheduler, scenario fibers, deterministic models, plan-time random replay, exact-rank execution | drivers/scenarios/models/decisions are public VIAL; scheduler/ranks are compiler-owned |
| checking and evidence | bounded scoreboard, coverage counters, substitution faults, procedural properties, structured diagnostics, closed trace projection, normalized-result projection | public intent with compiler-owned storage and evidence projection |

| Rejected boundary | Exact reason in the matrix |
| --- | --- |
| OSVVM-native services | separately owned by `vhdl_osvvm_qualified`; not a provider-free private preview |
| PSL properties | portable properties lower procedurally; PSL syntax and flags are not selected |
| distinct nine-state VIAL semantics | version 1 normalizes `std_logic` meta-values to VIAL's four states |
| multiple-clock/asynchronous semantics | the selected execution profile owns exactly one clock domain and rejects asynchronous semantic events |

The seven-stage workflow records repository-relative regeneration and byte
checking, structural review, pending director/delegated visual review, durable
defect capture, migration/separation proof, and later qualified runtime. A
review finding becomes durable only through a task-tree defect leaf containing
the artifact path, generated symbol, source-map ID, observation, severity,
reproduction, expected intent, and disposition. Seven closure invariants reject
incomplete role accounting, entry-point or unsupported-reason drift, workflow
drift, legacy/HIAL overlap, and accidental qualification claims.

The ordinary emission graph retains selected GHDL 6.0.0 `-a`, `-e`, and `-r`
command records using `--std=08`, the `fsmgen_vial` work library, and
repository-relative work paths. The separate `.15.5` qualifier has executed
those stages against this exact canonical source set.

Review the byte-locked output under
`vial/review_gallery/vhdl_portable_ghdl/ahb_base_output_portable_semantics`.
From the repository root, regenerate it with:

```text
perl scripts/refresh_vial_vhdl_portable_gallery.pl
```

Check it without writing with:

```text
perl scripts/refresh_vial_vhdl_portable_gallery.pl --check
```

The migration proof locks the checked inert legacy package at 976 bytes and
SHA-256 `8d587b8dde4b7659290af6720ed4812079f36479d577dd5a0cf787bef2a22d4f`.
Its canonical manifest projection excludes only the environment-resolved input
path and is locked at SHA-256
`29789c0b4b7400de45eec2ac1f62178d2e555f9c3d64ad871a1d87c5d39c5835`.
The emitted HIAL DUT is separately proven byte-identical to the private
handoff and isolated under the backend `src/dut` directory. The legacy
`vhdl-observation-package` therefore remains byte/schema-compatible,
unchanged, and unconsumed, while HIAL synthesis output remains outside VIAL
backend authority.

For this bounded canonical fixture, exact LLVM-JIT analysis, elaboration,
runtime, normalized-result validation, deterministic rerun, timed four-state
behavior, and nineteen-path applicable portable-SV parity are qualified.
Complete VHDL backend/language breadth, PSL, general OSVVM breadth, UVVM,
another simulator, mixed-language behavior, general cross-backend parity, and
scale remain explicit non-claims. The emitter remains private rather than a
public embedding API.

The complete contract is in the selected VHDL section of the
[HIAL/VIAL architecture audit](../../HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md#completed-vhdl-contract-selection).

Decision `0043` selects the exact version-1 profile. The compiler partially
evaluates the bound plan into a small runtime package plus one fixture module;
it does not emit a general interpreter or make the author write target code.
That deterministic emission ships through `.10.3`; exact tool version
qualification, compilation, execution, and result evidence now ship through
`.10.4`.
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

The generated runtime emits a closed, prefixed line-delimited JSON trace. The
shipped runner captures it, the pure validator checks its plan/run identities,
sequence, logical ordering, counts, and footer, and the result producer emits
`fsmgen.verification_result_manifest.v1`. The host does not rerun VIAL
scheduling, models, scoreboards, coverage, faults, or random decisions. See the
[portable SystemVerilog backend contract](../../VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md)
for exact artifacts, mappings, source maps, limits, diagnostics, non-claims,
and implementation gates.

The current UVM 1.2 output does not silently choose the future UVM revision.
The VHDL lane does not claim analysis, simulation, complete VHDL-2019, PSL, or
methodology support until its exact profiles run. Mixed-language support is a
separate qualification.

## Selected open-source native UVM architecture

Decision `0050` selects the methodology source precisely: IEEE 1800.2-2020
with Accellera UVM 2020-3.1, official tag `2020.3.1` and commit
`78c06547a2a0a29b3dc9dcafae62b75b2ff61544`. It does **not** make a commercial
simulator a project prerequisite. The native path instead has three separate
truth levels:

```text
sv_uvm_emit.accellera_2020_3_1
    deterministic generated UVM; no parser or runtime claim

sv_uvm_experimental.<tool-and-version>
    measured open-source feasibility; never promoted to product support

sv_uvm_qualified
    future exact PGEN parser + NEXSIM simulator runtime tuple
```

All five emission slices now ship. For the checked AHB base-output fixture they
produce sixteen deterministic virtual artifacts: the generated
HIAL DUT; typed-context, reusable-component, timed-interface,
notification/interception, stimulus/service, checking/result, bound-SVA,
fixture, and top SystemVerilog sources; a complete source map; the exact
methodology profile; a structural validation report; the selected mapping
matrix; the review workflow; and the backend manifest.

The private emitter and validator are discoverable through the capability manifest. Native emission admits only the selected review shape: 21 operations split 12/9 across two scenarios, four total and three simultaneously live fibers, and ten ordered expectation roles.
A T=22 or larger plan fails before graph construction as `{"code":"VIAL_UVM_BACKEND_UNSUPPORTED","message":"native UVM foundation negotiation rejected one or more requirements","path":"/negotiation"}` with the unsatisfied reason `native UVM selected review matrix requires the exact 21-operation reference shape`; a different same-count expectation set fails identically, preventing authored intent from disappearing behind fixed generated UVM.
This is an unsupported-shape boundary, not a capacity claim. Public `fsmgen vial run` deliberately remains the separately qualified portable-Verilator path.

The [checked review gallery](../../../vial/review_gallery/sv_uvm_emit.accellera_2020_3_1/ahb_base_output_foundation/README.md)
contains byte-identical copies of all nine UVM-facing sources. Its interface
shows the concrete logical-time mapping:

```systemverilog
clocking driver_cb @(negedge clk);
  default input #1step output #0;
  output HADDR, HSEL, HSIZE, HTRANS, HWDATA, HWRITE, wait_cycles;
  input HRDATA, HREADY, HREADYOUT, HRESP, rst_n;
endclocking

clocking monitor_cb @(posedge clk);
  default input #1step;
  input HADDR, HRDATA, HREADY, HREADYOUT, HRESP, HSEL, HSIZE, HTRANS, HWDATA, HWRITE, rst_n, wait_cycles;
endclocking
```

That code is intentionally reviewable before a UVM parser or simulator is
available. The selected active topology now contains a context-owning agent,
typed sequencer and driver, timed monitor, lifecycle controller,
result-collector structure, environment, and root test. Exactly one root-owned
objection encloses execution; explicit checked transitions move the shared
context from construction through finalization.

The notification package gives every public VIAL event a typed
`uvm_event#(T)` channel and one generated `uvm_event_callback#(T)` dispatcher.
Interceptors are compiled in strict rank/semantic-ID order, operate on an
effective payload clone, can filter, observe, cancel, or append a diagnostic,
and deterministically record skipped successors after cancellation. Nested
triggers use a finite queue or fail under the declared reject policy; channel
queues and total occurrences have exact bounds.

For example, the generated root test owns the complete objection interval:

```systemverilog
virtual task run_phase(uvm_phase phase);
  phase.raise_objection(this, "VIAL root lifecycle");
  env.controller.run_selected_lifecycle();
  env.result_collector.seal();
  env.controller.complete_lifecycle();
  phase.drop_objection(this, "VIAL root lifecycle complete");
endtask
```

The generated completed-event channel shows the compiled order explicitly:

```systemverilog
completed_notification.configure(
  "event/ahb_write/completed", fixture_scope,
  VIAL_REENTRANCY_QUEUE, 16, 4096
);
completed_notification.register_interceptor(observe_at_rank_10);
completed_notification.register_interceptor(cancel_error_at_rank_20);
completed_notification.register_interceptor(diagnostic_at_rank_30);
completed_notification.freeze_registration();
```

The names shortened in the second excerpt stand for the generated typed
interceptor objects; the checked gallery contains the complete emitted calls
with stable semantic IDs and registration scope.

The event identities are publicly authored VIAL v1. The concrete interceptor
table is a private typed preview until a later slice selects public authoring
syntax.

Revision 3 adds one typed write item and two generated scenario sequences for
the public `success` and `unsupported_size` scenarios. Portable decision
identity and the already-selected value cross the backend boundary intact: a
sequence replays that value and never rerandomizes VIAL meaning inside UVM.

```systemverilog
decision.configure("success.wait_cycles", 1);
decision.replay_selected(4'h2);
request.wait_cycles = decision.accepted_value;
```

An isolated, bounded native solver preview exists to exercise future native
constraint lowering, but generated scenario execution never calls it. This
keeps one portable decision authoritative while still making the intended UVM
shape reviewable.

The compiler-selected active driver receives a sequence item, drives it only
through the interface clocking block, and publishes the driven transaction.
The monitor publishes an independently sampled typed item. Exact, non-wildcard
configuration paths bind the environment, agent, driver, monitor, controller,
and result collector. An explicit factory override selects the concrete driver;
typed analysis FIFOs and a subscriber make the TLM topology visible.

The services package also contains a private typed RAL preview: one register,
one block and map, an adapter, and a predictor connected to the monitor's
analysis port. This demonstrates the backend mapping for the checked fixture;
it does not imply that public VIAL register or factory-override authoring syntax
has already been selected.

Revision 4 adds a checking package and a separately bound SVA checker. The
public `stall_seen` expression samples after the monitor's event work and
preserves its two explicit bins:

```systemverilog
covergroup stall_seen_cg with function sample(bit stalled);
  stall_seen: coverpoint stalled {
    bins not_stalled = {1'b0};
    bins stalled = {1'b1};
  }
endgroup

stall_seen_cg.sample(ready_out === 1'b0);
```

The generated event-counter component is instantiated twice, once for the
public accepted event and once for completed. Its 32-bit state checks overflow
before incrementing. A previous emitter helper recognized only whole
hexadecimal `f...f` known masks; revision 4 consolidates predicate literals on
the width-aware scalar validator, so exact one- and two-bit predicates such as
`HRESP == 1'b1` and `HTRANS == 2'b10` are executable generated expressions.

The `writes` scoreboard owns capacity-four expected and actual queues. The
public `scoreboard_expect` becomes an immutable typed item, the driver publishes
effective transaction data only after completion, and the public
`scoreboard_check` requires both queues to be empty with no mismatch.

The `unsupported_size` fault remains authored as a one-drive-interval field
substitution. Generated code arms it before the scenario and applies
`size = 3'b111` before the driver commits the transaction. The sequence item
still contains the immutable authored `3'b010`; fault application creates the
effective driven value rather than mutating the plan.

The separate checker binds to the exact generated HIAL module and carries the
selected 1-to-256-cycle completion window. This SVA is a reviewable generated
translation, not evidence that an HDL parser or simulator accepted it.

Diagnostics are typed objects with explicit defensive copying. Coverage,
models, the scoreboard, faults, and property checks publish diagnostics to one
result collector. Sealing creates a structured count snapshot for review, but
the manifest still says `runtime=not_run` and `result=not_produced`. A generated
collector is not a produced `verification-result-manifest.json`.

Verification-probe-backed expectations remain source-mapped but need a
qualified runtime adapter before they can be evaluated. Revision 4 does not
pretend that the private RAL preview supplies that observation.

Revision 5 adds no new generated SystemVerilog source. It closes the selected
emission scope with two canonical JSON evidence files. The 25-row mapping
matrix accounts exactly once for every foundation advertised by the backend
manifest and records, independently:

- normal public-source availability;
- terse public-source availability;
- public ExecutionIR, compiler-owned IR, or private-preview entry ownership;
- generated artifact roles and the selected UVM realization; and
- emission, structural review, visual review, and qualification state.

For example, public transactions are available through both VIAL source styles
and public ExecutionIR. Fixture-test topology is compiler-owned. RAL has no
selected public authoring syntax and is labelled `private_typed_preview` with
that exact reason. Notifications combine public event identities with a
private interceptor-table preview rather than blurring the two authorities.

The checked workflow makes review reproducible from the repository root:

```console
perl scripts/refresh_vial_native_uvm_gallery.pl
perl scripts/refresh_vial_native_uvm_gallery.pl --check
```

The first command regenerates nine source snapshots and two JSON evidence
files. The second writes nothing and rejects a missing, unexpected, or byte-
drifted snapshot. Review defects name the artifact, generated symbol,
source-map ID, observation, severity, reproduction, expected intent, and
disposition in the owning task-tree; conversation-only findings are not
durable evidence.

The workflow currently says `static_shape=passed_structural_only` and
`visual_review=pending`. Experimental compile and qualified runtime both say
`not_run`. This is complete selected emission accounting, not complete UVM
breadth, parser acceptance, compilation, elaboration, simulation, a produced
result, or parity.

PGEN and NEXSIM are separate developing projects. PGEN owns HDL parsing;
NEXSIM aims to provide open-source commercial-grade HDL simulation. When both
expose the needed capabilities, FSMGen will select exact versions, content
identities, commands, and their parser-to-simulator handoff before claiming
runtime support. Until then, no invented version appears in a manifest.

NEXSIM is also planned to expose deep semantic introspection through a clean
API operated via MCP. That changes the quality of evidence available to a
future qualification adapter: FSMGen can inspect structured simulator objects
instead of depending only on text logs and HDL waveforms.

Where NEXSIM declares support, the adapter can inspect hierarchy, types,
four-state values, processes, pending events and scheduler state, assertions,
coverage, and UVM topology, phases, objections, factory/configuration state,
TLM connections, sequences, and RAL objects. Explicitly selected control calls
can run, step, pause, stop at a semantic breakpoint, checkpoint, replay, or
cancel a bounded session.

The contract must still be exact. API and MCP schemas are versioned; queries
are bounded, deterministically ordered, snapshot-consistent, and side-effect
free; control authority is separate and explicit; semantic objects have stable
replay identities; permissions, capabilities, pagination, cancellation, and
errors are machine-readable. Provider paths never leak into canonical source
or portable result identities.

Complete source maps let FSMGen correlate one NEXSIM object with generated UVM
code, `VIALExecutionIR`, and HIAL/VIAL semantic IDs. At common checkpoints it
can compare NEXSIM with IASIM or another applicable normalized oracle and stop
at the first divergence. That makes it practical to distinguish an intent,
IAL lowering, UVM generation, PGEN handoff, elaboration, scheduler, or runtime
defect instead of reporting only that the final results differ.

NEXSIM introspection is exceptionally strong qualification evidence, but it
does not define VIAL meaning and does not by itself prove complete
SystemVerilog or UVM support. Canonical generated SystemVerilog/UVM therefore
remains simulator-neutral; MCP belongs to the provider control/evidence layer.

This separation lets full-shaped generation proceed now. Across bounded
slices, the emitter can produce reviewable tests, environments, agents,
interfaces, sequences, TLM/factory/configuration/RAL plumbing, coverage,
properties, models, scoreboards, faults, results, manifests, and complete
source maps. Typed-IR preview fixtures may exercise a mapping before public
VIAL syntax exists, but the capability matrix labels that boundary exactly.
A review gallery reports each independent maturity state, for example:

```text
emission: passed
static_validation: passed_structural_only
selected_mapping_matrix: passed_selected_scope
review_workflow: available_review_pending
manual_review: workflow_available_review_pending
preprocessing: not_run
parse: not_run
library_compile: not_run
fixture_compile: not_run
elaboration: not_run
runtime: not_run
result: not_produced
parity: not_evaluated
library_materialization: not_required_for_emission
```

Those source artifacts are simulator-neutral IEEE SystemVerilog using the
selected Accellera UVM API. They contain no Xcelium, VCS, Questa, Verilator,
NEXSIM, or other provider-specific conditional, package, pragma, hierarchy
API, option, or workaround. Provider integration is isolated in declared
adapters and command/evidence records and cannot change VIAL meaning or the
canonical generated source.

Verilator and other available open tools are probed from the first gallery,
not after generation is complete. They may catch preprocessing, parsing,
typing, package, class, compile, or elaboration defects for supported subsets;
every exact stage remains experimental because Verilator's UVM ecosystem says
support is still in development. Unsupported stages do not block emitting
broader neutral UVM, and a demonstrated generator defect is tracked separately
from a tool limitation.

Generated UVM is compiler output. Its neutral syntax, expressions, helpers,
macros, and class decomposition can iterate from visual review and tool
diagnostics while VIAL meaning stays fixed. Manifests pin the exact emitter
identity, making bytes deterministic for that version. Semantic, capability,
or public artifact-schema changes are versioned; a meaning-preserving source
rewrite is normal compiler evolution. Commercial tools may remain optional
comparison profiles, never roadmap prerequisites.

### Intent-to-UVM mapping

Authored VIAL describes verification intent. The compiler supplies UVM
expertise. The selected mappings are:

| VIAL meaning | Generated UVM mechanism |
| --- | --- |
| notification and interception | typed `uvm_event` plus a generated `uvm_event_callback` dispatcher |
| lifecycle, readiness, completion, and drain | phase methods and one root-test-owned objection |
| stimulus orchestration | sequence items, sequences, sequencers, and drivers |
| typed producer/observer communication | analysis ports/exports and TLM FIFOs/connections |
| implementation substitution | proved generated factory registration/overrides |
| scoped typed configuration | configuration objects and compiler-owned config-DB calls |
| register maps and access policy | RAL blocks, maps, adapters, predictors, and sequences |
| constrained decisions | controlled SystemVerilog randomization with stable decision/replay identity |
| coverage and properties | generated covergroups and bound SVA checkers |
| timed DUT interaction | generated interfaces, modports, virtual interfaces, and clocking blocks |
| models, scoreboards, faults, and results | generated subscribers/components plus a closed result collector |

These are compiler mappings, not VIAL vocabulary. A VIAL author does not write
`run_phase`, objections, `uvm_config_db`, factory overrides, TLM connections,
virtual-interface lookups, or target hierarchy. For example, the conceptual
intent:

```text
notification: response_completed
payload:       response transaction
lifetime:      scenario
interceptors:
  rank 10: observe every response
  rank 20: when response is ERROR, cancel this notification
reentrancy:    queue
```

maps to one typed event and one generated callback dispatcher. The dispatcher
applies VIAL's explicit ranks; it does not rely on callback registration or
object-allocation order. A nested trigger is queued and drained after the
current dispatch rather than recursing through the target stack. Cancellation
stops that notification's remaining effects—it does not silently stop a UVM
phase or the whole scenario.

The native result eventually records the original and effective typed payload,
each evaluated interceptor, filtering and transformation effects,
cancellation/skipped outcomes, nested queue depth, and VIAL logical time. UVM
object addresses, callback names, simulator timestamps, and phase folklore do
not enter portable meaning.

### Lifecycle and component topology

Only the generated root test owns the run-phase objection: one raise after
readiness, one drop after selected scenarios and background drain conditions
finish. Child components cannot make free-form objection counts or phase jumps
part of VIAL behavior. Logical
`drive -> sample -> react -> check` ordering remains authoritative; generated
driver/monitor clocking blocks implement its edge/skew contract.

The compiler emits only selected roles:

```text
test
  environment
    agent per timed interface role
      sequencer + driver only for stimulus
      monitor only for observation
    selected models / scoreboards / coverage subscribers
    result collector
```

A passive fixture does not acquire a driver. A fixture without RAL, coverage,
or a scoreboard does not acquire those components. The backend groups stable
operations into readable services/tables instead of generating a class per
operation.

### Artifacts, qualification, and UVM 1.2 compatibility

The selected emission graph is separate and content-addressed:

```text
backends/sv_uvm_emit.accellera_2020_3_1/
  backend-manifest.json
  backend-source-map.json
  evidence/methodology-profile.json
  evidence/static-validation.json
  evidence/selected-mapping-matrix.json
  evidence/review-workflow.json
  src/fsmgen_vial_uvm_types_pkg.sv
  src/fsmgen_vial_uvm_components_pkg.sv
  src/<fixture>_if.sv
  src/<fixture>_notifications_pkg.sv
  src/<fixture>_services_pkg.sv
  src/<fixture>_checking_pkg.sv
  src/<fixture>_sva_checker.sv
  src/<fixture>_pkg.sv
  src/<fixture>_tb.sv
  src/dut/<generated-hial-dut>.sv
```

This is the exact sixteen-artifact graph after `.13.1.5`. Its ten SystemVerilog
sources include the generated HIAL DUT and nine UVM-facing files. Revision 5
retains 75 complete source-map entries and 14 static structure checks, adds the
25-row selected mapping matrix, and records a seven-stage workflow guarded by
five internal closure invariants.

The older inert `uvm-passive-monitor` target remains a separate UVM 1.2
artifact contract. Native Accellera-2020.3.1 emission neither replaces it nor
borrows a compile or runtime claim from it.

A verified project-local UVM library manifest is added only by a later
library-dependent probe or qualification gate. Ordinary emission neither
downloads nor inspects those bytes.

### Exact Verilator 5.046 experimental probe

The first reusable open-source probe selects this immutable tuple:

| Field | Selected identity |
| --- | --- |
| tool | `Verilator 5.046 2026-02-28 rev vUNKNOWN-built20260228` |
| UVM provider | CHIPS Alliance `uvm-verilator` |
| source ref | `uvm-2020-3.1-vlt` |
| source commit | `656f20d087370a7c742e00188d20bbf30fa95339` |
| source tree | `882930bb7debe79b22234e4a8a53854549046778` |
| canonical methodology reference | Accellera tag `2020.3.1`, commit `78c06547a2a0a29b3dc9dcafae62b75b2ff61544` |

The library checkout lives in a repository-relative same-volume cache. The
probe validates its Git commit and tree before executing and never fetches the
network. Every command runs from the repository root with one Verilator
thread, one build job, bounded time and output, repository-local staging, and
exact cleanup. Generated C++ uses `-O0` because optimization speed is
irrelevant to this feasibility gate and the unoptimized translation unit stays
inside the repository RAM guard.

Run the complete observation or independently byte-check it:

```console
perl scripts/run_vial_native_uvm_experimental_probe.pl
perl scripts/run_vial_native_uvm_experimental_probe.pl --check
```

The canonical report is
[`probe-report.json`](../../../vial/experimental_probes/sv_uvm_experimental.verilator_5_046.uvm_verilator_2020_3_1_vlt_656f20d0/probe-report.json).
Its independently recorded stages currently say:

| Stage | Result | Ownership |
| --- | --- | --- |
| exact tool and UVM-source identity | passed | none |
| UVM library preprocessing | passed | none |
| UVM library parsing | passed | none |
| minimal UVM compile/elaboration | passed | none |
| minimal UVM `run_phase` smoke | passed, zero UVM errors/fatals | none |
| generated fixture preprocessing | passed | none |
| generated fixture strict parsing | unsupported | Verilator ranged-SVA limitation |
| generated fixture compile/elaboration with unsupported-feature blackboxing | failed with exit 139 | Verilator internal fault |
| generated fixture runtime | not run | compile/elaboration prerequisite |
| native result and parity | not exercised | later qualification |

The probe found one genuine FSMGen defect before producing the canonical
report: the generated packages used `context`, a SystemVerilog keyword, as a
field identifier. The emitter now uses `vial_context`, the nine-source gallery
was regenerated, and focused tests reject reintroduction of the reserved
identifier. After that correction, strict parsing reaches only Verilator's
unsupported `##[1:256]` SVA delay; the emitted covergroup also receives
Verilator `COVERIGN` warnings. These are tool observations, not reasons to put
provider conditionals into canonical simulator-neutral UVM.

All experimental stages define `UVM_NO_DPI`, so DPI-backed UVM facilities are
not exercised. Only the separate compile/elaboration attempt adds
`--bbox-unsup`; it still faults and could not have qualified semantics even if
it succeeded. The report therefore concludes `partial_tool_limited`, keeps
`product_support` false, and leaves generated-fixture runtime, normalized
results, parity, complete four-state behavior, and complete UVM breadth
unclaimed.

Every generated class, interface, method, field, connection, constraint,
coverage element, property, notification/interceptor table, and RAL element
maps to VIAL semantic IDs. Compiler plumbing receives a stable synthetic owner
and links to the semantic nodes it serves. Files remain deterministic,
repository-relative, and same-volume; no timestamp, home cache, `/tmp`, tool
license, host path, or random suffix enters them.

Future runtime qualification is a chain, not one green exit code:

```text
exact PGEN parse
  -> exact parser/simulator handoff
  -> NEXSIM UVM and fixture compile
  -> elaboration
  -> bounded four-state timed simulation
  -> snapshot-consistent semantic checkpoint correlation
  -> closed native result
  -> deterministic rerun
  -> cleanup and residue census
```

Each stage has its own capability evidence. Parser success is not simulation
success; simulation exit zero is not a passing UVM/result; one exercised
subset is not complete IEEE 1800.2 or VIAL breadth.

The old `uvm-passive-monitor` command remains exactly UVM 1.2 and inert. Its
manifest continues to say compile support is not claimed. Native emission uses
new packages and cannot overwrite, import by accident, or retroactively
qualify that legacy artifact. See the complete native contract in the
[HIAL/VIAL architecture audit](../../HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md).

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

### Bounded parity with the handwritten AHB oracle

The old handwritten harness does not emit VIAL events, models, scoreboards,
coverage, faults, or fiber records. Copying those records from the generated
result would be circular, not parity. FSMGen therefore executes both harnesses
against byte-identical generated DUT source and constructs one smaller shared
AHB outcome oracle.

For `success`, the comparison covers:

- passing scenario identity and one public bus acceptance;
- 15 sampled not-ready cycles;
- zero response-error and nonzero-read-data samples;
- final ready `1`, response `0`, and read data `00000000`; and
- declared storage probe `probe/reg_data_q = cafebabe`.

For `unsupported_size`, it covers the same observed final/public values, one
acceptance, exactly two response-error samples, and unchanged storage
`00000000`. The old harness's internal capture, hold, and completion counters
remain preserved as evidence but are explicitly excluded: those hierarchy
signals are not declared typed VIAL probes. Storage is compared because it is
a declared probe.

`FSM::VIAL::Parity::AHBBaseOutput` emits the closed
`fsmgen.vial_parity_report.v1` envelope. Nineteen exact paths are compared; a
changed value produces `equivalent: false` and a path/semantic-ID mismatch.
Malformed or duplicate oracle lines, nonzero baseline exit, unknown candidate
values, an ineligible result, or different DUT digests fail closed. This
qualifies only `vial.parity.ahb_base_output_arbitration.v1`; it adds no public
CLI action or ordinary-run artifact and cannot be generalized to UVM, VHDL,
four-state, or arbitrary cross-backend parity.

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

The canonical architecture record is
[HIAL/VIAL Verification Fixture Architecture Audit](../../HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md),
while the owning [task tree](../../tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md)
retains detailed validation evidence.

The current product boundary is:

- the typed `.vial` frontend, review-routed bridge, deterministic ExecutionIR,
  public planning/run tools, atomic artifacts, closed traces, and normalized
  results are shipped;
- portable SystemVerilog is qualified for the exact Verilator 5.046
  known-value profile, including the selected 19-path AHB parity oracle;
- simulator-neutral Accellera UVM 2020-3.1 emission is shipped, while its
  Verilator/UVM probe remains explicitly tool-limited rather than qualified;
- provider-free VHDL-2008 is qualified under repository-local GHDL 6.0.0
  LLVM-JIT, and the OSVVM 2026.05 advanced profile is independently qualified;
- general cross-backend parity, complete UVM runtime, and mixed-language
  execution remain unsupported.

No installed tool currently provides a qualified mixed-language HIAL/VIAL
runtime. Separate Verilator and GHDL successes cannot be combined into that
claim.

## How architecture-scale qualification works

Decisions `0055` and `0056` select the
[VIAL workload/correctness contract](../../decisions/0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md#selected-contract)
and its
[measurement/bounded-failure contract](../../decisions/0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md#selected-contract).
They do not yet qualify a capacity. Scale is
split into six orthogonal families so a result identifies what grew and where:

| Family | Primary question |
| --- | --- |
| `semantic_catalog_v1` | Can source parsing, validation, and SemanticIR preserve many valid declarations, fixtures, actions, fibers, and aggregates? |
| `bridge_fanout_v1` | Can the canonical HIAL route preserve many endpoints, types, transactions, events, probes, bindings, and maps? |
| `execution_graph_v1` | Can binding and planning preserve many scenarios, operations, fibers, types, and deterministic ranks? |
| `checking_state_v1` | Can models, scoreboards, coverage, faults, and replay decisions scale without implicit expansion or unbounded state? |
| `backend_emission_v1` | Can each applicable backend emit a complete, source-mapped, byte-deterministic artifact graph? |
| `runtime_stream_v1` | Can an exactly qualified tool compile, run, close the trace, and produce the expected normalized result? |

One primary axis changes per workload; the other axes stay at the smallest
valid anchor. A separately named balanced candidate checks conservative
interactions. This is more diagnostic than one combinatorial “huge” fixture,
which could hit an unrelated byte cap before exercising its advertised axis.

Each axis has `reference_v1`, `gate_candidate_v1`,
`qualification_candidate_v1`, `limit_v1`, and `over_limit_v1` levels.
“Candidate” is deliberate: no profile becomes supported until generation,
measurement, bounded failure, and stable-gate owners all complete. The current
single-unit/single-domain profiles test `1` as accepted and `2` as rejected;
repeating a one-unit result cannot claim multi-unit or multi-domain scale.

[Decision `0060`](../../decisions/0060-vial-bridge-scale-uses-a-qualification-only-direct-ial1-profile.md)
closes a bridge-fixture reachability gap before implementation. The shipped AHB
annotation stays exact; a separate `qualification_only` direct-IAL1 profile
must pass through normal parse, scheduler report, IAL0 lowering, and bridge
construction to exercise wider manifest arrays. It is private measurement
infrastructure, not a protocol, support, performance, or capacity claim. If a
source-map or manifest-byte cap dominates, that earlier limit is the result.

### Deterministic construction foundation

The provider-free construction foundation is now available through
`FSM::VIAL::ArchitectureScaleWorkload`. It is qualification infrastructure,
not a user capacity or support claim. Its versioned catalog contains the six
families above, every selected axis/level, the separate
`balanced_portable_v1` interaction profile, exact backend/tool selectors,
the checked AHB anchor, applicable stage oracles, and explicit nonclaims.

Each successful construction carries the exact
`fsmgen.vial_architecture_scale_workload.v1` specification fields selected by
decision `0055`:

```text
schema / schema_version
family / level / primary_axis / requested_counts
expected_stage / expected_outcome
generator_revision / seed / anchor_identity
source_route / backend_profile / tool_profile
applicable_oracles / explicit_nonclaims
```

[Decision `0057`](../../decisions/0057-vial-scale-byte-candidates-and-construction-envelopes-are-derived-and-bounded.md)
closes the byte-axis construction detail. A source-byte gate candidate is
`floor(cap / 16)` and a qualification candidate is `floor(cap / 4)`. Thus the
1-MiB per-source cap uses 64-KiB and 256-KiB candidates; the 16-MiB combined
cap uses 1-MiB and 4-MiB candidates. A byte over-limit workload appends the
first complete valid referenced record above the cap. It does not use comment,
blank-data, or exact-plus-one padding.

The boundary accepts only VIAL source, HIAL source, and optional replay-
manifest inputs. It cannot accept or forge SemanticIR, a bridge manifest, an
execution plan, backend artifacts, a trace, or a result. Those must come from
the canonical producers exercised by the later family-specific leaves. The
source envelope is bounded at 1,114,112 bytes per input and 17,825,792 bytes
combined so the exact source caps and one bounded whole-record excess fit
without creating an unbounded fixture builder.

This repository-root-relative example constructs an unmeasured semantic
candidate and prints its stable identity:

```perl
use FSM::VIAL::ArchitectureScaleWorkload;

my $workload = FSM::VIAL::ArchitectureScaleWorkload->construct({
    family => 'semantic_catalog_v1',
    level => 'gate_candidate_v1',
    primary_axis => 'imports',
    backend_profile => undef,
    tool_profile => undef,
    inputs => [{
        relative_path => 'source/workload.vial',
        role => 'vial_source',
        encoding => 'utf-8',
        content => "(vial\n  (version 1)\n)\n",
    }],
});
die $workload->{diagnostics}[0]{message} unless $workload->{ok};
print "$workload->{workload_identity}\n";
```

Input order is normalized by repository-relative path. The workload identity
is SHA-256 over canonical JSON containing the complete specification and those
ordered input identities, including their content digests. Host paths,
timestamps, process IDs, tool-discovery paths, run ordinals, and measurements
cannot enter it. Payloads use fixed seed `1701` and the shipped
`sha256_counter_rejection_v1` algorithm; structure, names, ordering, requested
counts, and expected outcomes never come from randomness. Stable names use the
family, axis, and an eight-digit ordinal.

`with_staging` materializes the source-only input graph below the derived
`.artifacts/tmp/vial-scale/<identity>` directory on the repository volume,
runs a caller-supplied canonical-producer callback, and removes the exact owned
tree on success or failure. A concurrent identity collision fails without
touching the existing tree. Its returned report contains only the repository-
relative staging identity, same-volume proof, cleanup state, and diagnostics;
runtime-derived absolute paths are never durable identity.

### Canonical semantic-catalog generation

`FSM::VIAL::ArchitectureScaleSemanticCatalog` now constructs all 14
`semantic_catalog_v1` axes at all five selected levels. It produces ordinary
`.vial` text, feeds only the public parser/validator, and exposes the resulting
private `VIALSemanticIR` only through that canonical parser. It cannot accept a
caller-created IR.

The generated sources use reachable, typed declarations rather than comments,
blank data, or unreachable padding. Imports are exercised through an in-memory
catalog; declared types are referenced by transaction fields and fixtures;
fixtures contain valid DUT/domain/endpoint/transaction/scenario anchors;
actions, parallel depth/fanout, aggregates, scoreboards, and coverage use their
real semantic forms. Byte workloads use referenced width-4,096 enum
declarations with seed-1701 payloads. A bounded semantic unit reference adjusts
only the final whole-source byte remainder, and an over-limit source appends a
complete referenced declaration.

This repository-root-relative example builds and checks the imports gate
candidate:

```perl
use FSM::VIAL::ArchitectureScaleSemanticCatalog;

my $workload = FSM::VIAL::ArchitectureScaleSemanticCatalog->construct({
    primary_axis => 'imports',
    level => 'gate_candidate_v1',
    reference_text => undef,
});
die $workload->{diagnostics}[0]{message} unless $workload->{ok};

my $evaluation = FSM::VIAL::ArchitectureScaleSemanticCatalog->evaluate({
    construction => $workload,
});
die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
print "$evaluation->{workload_identity}\n";
```

An accepted evaluation proves exact requested counts, globally unambiguous
named IDs, in-bounds source spans, closed internal references and resolved
types, authored ordering, equal reports from independent canonical parses,
semantic-projection identity, and deterministic normal formatting. An
over-limit evaluation succeeds as an oracle only when the parser rejects at
the exact earliest `VIAL_LIMIT_ERROR` family and semantic path. Qualification,
exact-boundary, and excess exercises are opt-in and run under the repository
RAM guard:

```text
FSMGEN_VIAL_SCALE_EXACT=1 scripts/run_with_ram_guard.sh -- \
  prove -Iperl t/1601-vial-architecture-scale-semantic-catalog.t
```

The exact proof covers all 70 axis/level constructions. The current repeat
gate of 4,096 is accepted, but a one-action literal repeat reaches the 65,536
expanded-action cap at repeat count 65,535. Therefore the selected 262,144
repeat qualification candidate and 1,000,000 repeat boundary are recorded as
honest earlier-cap rejections; decision `0059` routes any policy repair to
`.17.4`. No candidate or boundary is a capacity/support claim.

### Canonical bridge-fanout generation

`FSM::VIAL::ArchitectureScaleBridgeFanout` now constructs all 13
`bridge_fanout_v1` axes at all five selected levels. Candidate source is an
ordinary generated `.isf` actor plus one checked `.vial` fixture. The evaluator
parses the actor, obtains its scheduler report, lowers it to reviewable `.fsm`,
and calls the shipped direct-IAL1 bridge builder. It cannot accept a caller-
created actor, schedule report, manifest, or bridge report.

The private annotation is closed to this exact identity:

```lisp
(protocol architecture_scale_probe
  (profile qualification_only)
  (revision 1)
  (role verification)
  (facts (fact scale_evidence_only true)))
```

It publishes only
`hial_vial.bridge_qualification.architecture_scale_v1`. Attempting to carry
that annotation through the IAL2 route fails with
`HIAL_VIAL_BRIDGE_ANNOTATION_ERROR`; the checked AHB IAL2-via-IAL1 report stays
byte-identical. Every accepted candidate records exactly the `IAL1 -> IAL0`
review route, while the AHB reference records `IAL2 -> IAL1 -> IAL0`.

The generator uses reachable semantic structure for each axis: parameters for
configurations and distinct logical widths, public inputs for endpoints,
ordinary transactions, annotation events, passive observations, storage-
backed probes, retained residue, and exact target-name bindings. Source maps
are total and one-to-one, every backend binding resolves to a semantic ID, and
all checked VIAL unit/domain/endpoint/probe/transaction references resolve by
ID, access, and type. Independent construction and bridge passes must produce
byte-equal reports and immutable-manifest projections.

This repository-root-relative example evaluates the 256-event gate candidate:

```perl
use FSM::VIAL::ArchitectureScaleBridgeFanout;

my $workload = FSM::VIAL::ArchitectureScaleBridgeFanout->construct({
    primary_axis => 'events',
    level => 'gate_candidate_v1',
    reference_hial_text => undef,
    reference_vial_text => undef,
});
die $workload->{diagnostics}[0]{message} unless $workload->{ok};

my $evaluation = FSM::VIAL::ArchitectureScaleBridgeFanout->evaluate({
    construction => $workload,
});
die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
die "unexpected event count\n" unless $evaluation->{metrics}{events} == 256;
```

Representation-derived profiles are exact rather than padded. The serialized-
manifest axis produces canonical reports of exactly 1 MiB, 4 MiB, and 16 MiB;
the first complete valid wider type above 16 MiB is rejected. The source-map
gate produces exactly 8,192 mapped facts. Its 49,152-record qualification and
65,536-record limit shapes honestly stop at the earlier 16-MiB serialized-
manifest cap, while the 65,537-record excess stops at the source-map cap. These
are successful oracle outcomes, not successful product workloads.

The default test covers the frozen AHB reference and every gate axis. The full
qualification/boundary/excess matrix is explicit and RAM-guarded:

```text
prove -Iperl t/1602-vial-architecture-scale-bridge-fanout.t

FSMGEN_VIAL_SCALE_EXACT=1 scripts/run_with_ram_guard.sh -- \
  prove -Iperl t/1602-vial-architecture-scale-bridge-fanout.t
```

Both generated inputs use repository-relative identities and can be staged
only below the shared repository-derived VIAL-scale staging root. Success and
consumer failure remove the exact owned tree. None of this evidence promotes
a protocol, public embedding API, backend/runtime support state, performance
budget, or whole-product capacity.

Execution-graph reachability is now selected by
[decision `0061`](../../decisions/0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md).
The frozen AHB route owns topology, operations, fibers, maps, random/replay,
and plan bytes. An ordinary non-annotated direct-IAL1 actor owns the type axis.
The 2,048-binding gate alone needs the decision-`0060` event family, admitted
through a caller-sealed scale-generator path. Public
`ExecutionBuilder->build`, public planning, backends, and support accounting
must continue to reject that private bridge capability.

The first execution-generator slice implements that exceptional binding gate.
`ArchitectureScaleExecutionGraph` authors ordinary IAL1 and
VIAL sources containing 2,042 closed ordinal events. Canonical bridge and
semantic construction then add exactly six non-event bindings: unit, domain,
public endpoint, probe, transaction, and transaction field. The resulting
target-neutral plan therefore reports exactly 2,048 bindings, one execution
type, one scenario, one reset operation, one root fiber, and 2,047 source-map
records. Its current canonical serialization is 2,656,823 bytes, safely below
the independent 16-MiB plan cap.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
    primary_axis => 'bindings',
    level => 'gate_candidate_v1',
});
die $workload->{diagnostics}[0]{message} unless $workload->{ok};

my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
    construction => $workload,
});
die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
die "unexpected binding count\n"
    unless $evaluation->{metrics}{bindings} == 2_048;
```

The admission is doubly closed. Only the exact
`FSM::VIAL::ArchitectureScaleExecutionGraph` caller can enter it, and the
manifest must retain direct `IAL1 -> IAL0` review plus exact
`architecture_scale_probe` / `qualification_only` / revision `1` /
`verification` / `scale_evidence_only=true` metadata. The plan classifies the
private capability as `qualification_only` and `private_nonportable`. A direct
caller, the public builder, an AHB capability, altered metadata, or a forged
post-identity construction fails closed. This does not make the private path a
public planning or embedding API.

The next slice implements three topology gates through the unchanged public
builder and the frozen checked-AHB PPIF route:

| Primary axis | Canonical shape | Source maps | Plan bytes |
| --- | ---: | ---: | ---: |
| scenarios | 32 scenarios × 1 reset | 49 | 59,907 |
| operations in one scenario | 1 scenario × 256 resets | 273 | 121,163 |
| operations total | 32 scenarios × 32 resets | 1,041 | 409,363 |

Each shape retains 22 checked-AHB bindings, seven normalized execution types,
one root fiber per scenario, and one maximum simultaneously live fiber. Every
operation is a genuine parsed reset eligible in the `drive` phase. Scenario-
local static ranks still restart at zero, while source-map plan paths use the
operation's unique global index. This distinction repaired an older collision
where every scenario's first operation mapped to
`/operation_graph/operations/0`.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

open my $fh, '<:raw', 'ppif/ahb_lite_subordinate.ppif'
    or die "cannot read checked AHB source: $!";
local $/;
my $checked_ahb = <$fh>;
close $fh or die "cannot close checked AHB source: $!";

my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
    primary_axis => 'operations_total',
    level => 'gate_candidate_v1',
    reference_hial_text => $checked_ahb,
});
die $workload->{diagnostics}[0]{message} unless $workload->{ok};
my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
    construction => $workload,
});
die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
die "unexpected operation count\n"
    unless $evaluation->{metrics}{expanded_operations_total} == 1_024;
```

The constructor accepts only the exact 1,326-byte checked PPIF identity for
these three gates. Independent runs reproduce byte-equal plans and frozen
semantic, bridge, and plan hashes; post-identity source mutation fails closed.
The corrected multi-scenario plan identity was propagated through the native-
UVM, portable-VHDL, and OSVVM galleries and requalified with the repository-
local GHDL 6.0.0 and OSVVM 2026.05 tool/provider tuple. No backend or runtime
capability was added. The type and large-map gates below retain the same
boundary; random/replay, exact plan-byte boundaries, and higher levels remain
owned by later slices of the active generator task.

The scenario ladder now extends that same checked-AHB construction to its
selected qualification, limit, and adjacent rejection boundaries:

| Level | Scenarios / operations / root fibers | Source maps | Plan result |
| --- | ---: | ---: | --- |
| qualification | 512 | 529 | 496,709 bytes; accepted |
| exact limit | 4,096 | 4,113 | 3,779,103 bytes; accepted |
| first over limit | 4,097 | n/a | `VIAL_EXECUTION_LIMIT_ERROR` at `/scenario_ids` |

Each accepted scenario contains one real reset, has one root fiber and one
maximum live fiber, and preserves contiguous IDs from `scenario_00000000`.
The over-limit source parses normally; the unchanged public binder returns
only phase `limit`, message `selected_scenarios exceeds the limit 4096`, with
no partial ExecutionIR or plan. The helper admission remains caller-sealed and
qualification-only—it is evidence about a real boundary, not a public API or
a supported scale-capacity promise.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

open my $fh, '<:raw', 'ppif/ahb_lite_subordinate.ppif'
    or die "cannot read checked AHB source: $!";
local $/;
my $checked_ahb = <$fh>;
close $fh or die "cannot close checked AHB source: $!";

for my $case (
    [qualification_candidate_v1 => 512],
    [limit_v1                  => 4_096],
    [over_limit_v1             => undef],
) {
    my ($level, $accepted) = @{$case};
    my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
        primary_axis => 'scenarios', level => $level,
        reference_hial_text => $checked_ahb,
    });
    die $workload->{diagnostics}[0]{message} unless $workload->{ok};
    my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
        construction => $workload,
    });
    if (defined $accepted) {
        die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
        die "unexpected scenario count\n"
            unless $evaluation->{metrics}{selected_scenarios} == $accepted;
    } else {
        die "over-limit scenario unexpectedly accepted\n"
            unless $evaluation->{status} eq 'expected_rejection';
    }
}
```

The operation-depth ladder extends that same construction to a single scenario
carrying the selected qualification count:

| Level | Scenario × resets | Source maps | Plan result |
| --- | --- | ---: | --- |
| gate | 1 × 256 | 273 | 121,163 bytes; accepted |
| qualification | 1 × 8,192 | 8,209 | 2,955,783 bytes; accepted |
| limit | 1 × 65,536 | — | rejected by the 16-MiB plan cap |
| over limit | 1 × 65,537 | — | rejected by the 65,536 expanded-action cap |

The 115,716-byte qualification source authors one `scenario_00000000`
containing 8,192 genuine one-cycle bus resets. The unchanged public binder
concentrates every one of them in that scenario, so operation depth rises while
the root-fiber count and the maximum simultaneously live width both stay at
one. Each operation is a `drive`-phase reset that maps from its unique global
`/operation_graph/operations/<index>` plan path back to its own authored
`/packages/0/fixtures/0/scenarios/0/actions/<index>` action. The resulting
2,955,783-byte plan stays below the independent 16-MiB plan cap, and the
workload introduces no random decision.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

open my $fh, '<:raw', 'ppif/ahb_lite_subordinate.ppif'
    or die "cannot read checked AHB source: $!";
local $/;
my $checked_ahb = <$fh>;
close $fh or die "cannot close checked AHB source: $!";

my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
    primary_axis => 'operations_per_scenario',
    level => 'qualification_candidate_v1',
    reference_hial_text => $checked_ahb,
});
die $workload->{diagnostics}[0]{message} unless $workload->{ok};

my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
    construction => $workload,
});
die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
die "unexpected operation depth\n"
    unless $evaluation->{metrics}{expanded_operations_per_scenario} == 8_192
        && $evaluation->{metrics}{selected_scenarios} == 1
        && $evaluation->{metrics}{simultaneous_live_fibers} == 1;
```

The two higher operation levels are the first selected pair whose own nominal
execution cap is never the authority. Both generate normally, and both are
rejected — but by different earlier owners, so neither number describes an
exercised operation limit:

- the 918,533-byte limit source parses into a complete 65,536-action scenario
  and reaches the unchanged public binder, which returns only
  `VIAL_EXECUTION_LIMIT_ERROR`, phase `limit`, message `serialized_plan_bytes
  exceeds the limit 16777216`, at `/plan`; and
- the 918,547-byte over-limit source adds exactly one further 14-byte
  ` (reset bus 1)` record, so the ordinary VIAL parser rejects it first with
  `VIAL_LIMIT_ERROR`, phase `limit`, message `scenario exceeds 65536 expanded
  actions`, at `/packages/0/fixtures/0/scenarios/0`.

Neither rejection produces a partial `VIALExecutionIR` or plan. Because the
semantic stage owns the second rejection, no canonical HIAL bridge is built
behind it and the evaluation claims no SemanticIR or bridge identity. Each
evaluation classifies its outcome as `expected_rejection` and records one
`VIAL_SCALE_LIMIT_INTERACTION` contract discrepancy naming the earlier
authority, so the nominal 65,536-operation execution cap is never reported as
proved:

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

open my $fh, '<:raw', 'ppif/ahb_lite_subordinate.ppif'
    or die "cannot read checked AHB source: $!";
local $/;
my $checked_ahb = <$fh>;
close $fh or die "cannot close checked AHB source: $!";

for my $case (
    ['limit_v1', 'serialized_plan_bytes exceeds the limit 16777216'],
    ['over_limit_v1', 'scenario exceeds 65536 expanded actions'],
) {
    my ($level, $message) = @{$case};
    my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
        primary_axis => 'operations_per_scenario',
        level => $level,
        reference_hial_text => $checked_ahb,
    });
    die $workload->{diagnostics}[0]{message} unless $workload->{ok};

    my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
        construction => $workload,
    });
    die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
    die "unexpected operation outcome\n"
        unless $evaluation->{status} eq 'expected_rejection'
            && $evaluation->{diagnostics}[0]{message} eq $message
            && $evaluation->{contract_discrepancies}[0]{code}
                eq 'VIAL_SCALE_LIMIT_INTERACTION';
}
```

The total-operation axis spreads the same operations over a fixed fanout of 32
scenarios instead of concentrating them in one, and its qualification level is
the first selected level that no construction can reach:

| Level | Scenarios x resets | Total operations | Plan result |
| --- | --- | ---: | --- |
| gate | 32 x 32 | 1,024 | accepted |
| qualification | 32 x 2,048 | 65,536 | rejected by the 16-MiB plan cap |

The 920,547-byte qualification source authors 32 scenarios of 2,048 genuine
one-cycle bus resets each. Every ordinary stage before the plan accepts it: no
scenario approaches the 65,536 expanded-action semantic cap, the parser
produces a complete `SemanticIR` whose 32 scenarios each report exactly 2,048
expanded actions, and the checked-AHB bridge identity is the same one every
other execution workload uses. Only the serialized plan crosses a limit, so the
unchanged public binder returns exactly one `VIAL_EXECUTION_LIMIT_ERROR`, phase
`limit`, message `serialized_plan_bytes exceeds the limit 16777216`, at
`/plan`, with no partial `VIALExecutionIR` and no partial plan.

That result is reported, never rounded off. The evaluation classifies the
outcome as `expected_rejection` and records one `VIAL_SCALE_LIMIT_INTERACTION`
contract discrepancy at `/requested_counts/operations_total`, naming
`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4` as the repair owner. Read it
as a statement about the axis rather than about one level: with the plan cap
authoritative well below the selected qualification count, the total-operation
axis currently has **no nominal operating point above its 1,024-operation
gate**, and no total-operation capacity beyond that gate is claimed as proved.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

open my $fh, '<:raw', 'ppif/ahb_lite_subordinate.ppif'
    or die "cannot read checked AHB source: $!";
local $/;
my $checked_ahb = <$fh>;
close $fh or die "cannot close checked AHB source: $!";

my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
    primary_axis => 'operations_total',
    level => 'qualification_candidate_v1',
    reference_hial_text => $checked_ahb,
});
die $workload->{diagnostics}[0]{message} unless $workload->{ok};

my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
    construction => $workload,
});
die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
die "unexpected total-operation outcome\n"
    unless $evaluation->{status} eq 'expected_rejection'
        && $evaluation->{diagnostics}[0]{message}
            eq 'serialized_plan_bytes exceeds the limit 16777216'
        && $evaluation->{contract_discrepancies}[0]{path}
            eq '/requested_counts/operations_total';
```

The axis's two higher levels are covered further below; they are the first
pair on this leaf whose costs, not whose caps, decide how they are proved.

The following slice implements both gate-level fiber axes through the same
frozen checked-AHB route and unchanged public builder:

| Primary axis | Canonical parallel shape | Operations | Total fibers | Maximum live | Source maps | Plan bytes |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| fibers total | five sequential `all` groups with `31/31/31/31/3` children | 132 | 128 | 32 | 149 | 79,987 |
| simultaneously live fibers | one depth-two `all` tree with `2` outer and `29` nested children | 32 | 32 | 32 | 49 | 43,811 |

Every generated child is a real parsed fiber containing a one-cycle bus reset;
none is an allocated-but-unused count. Sequential groups let the total-fiber
gate reach 128 while holding its non-primary live count to the separate gate
value of 32. The live-width tree keeps parser nesting at two and every authored
parallel below the 256-child limit. Both plans prove exact `all` joins,
parent/child closure, stable operation and fiber IDs, static ranks, successor
chains, `drive` resets, `react` parallel activation, one source map per global
operation index, and byte-equal independent reruns.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

open my $fh, '<:raw', 'ppif/ahb_lite_subordinate.ppif'
    or die "cannot read checked AHB source: $!";
local $/;
my $checked_ahb = <$fh>;
close $fh or die "cannot close checked AHB source: $!";

for my $axis (qw(fibers_total simultaneously_live_fibers)) {
    my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
        primary_axis => $axis,
        level => 'gate_candidate_v1',
        reference_hial_text => $checked_ahb,
    });
    die $workload->{diagnostics}[0]{message} unless $workload->{ok};

    my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
        construction => $workload,
    });
    die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
    die "unexpected live width\n"
        unless $evaluation->{metrics}{simultaneous_live_fibers} == 32;
}
```

The fiber gates retain 22 checked-AHB bindings, seven normalized types, the
public portable AHB capability, and exact `IAL2 -> IAL1 -> IAL0` review
closure. They never admit the private binding-scale capability. Post-identity
source mutation and still-unowned higher levels fail closed.

Both fiber axes reach their qualification levels, and both stay orthogonal
there:

| Primary axis | Requested | Total fibers | Maximum live | Operations | Source maps | Plan bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| simultaneously live fibers | 1,024 | 1,024 | 1,024 | 1,024 | 1,041 | 432,528 |
| fibers total | 8,192 | 8,192 | 32 | 8,456 | 8,473 | 3,222,659 |

The live-width workload holds every one of its 1,024 fibers live at the same
instant, so its total and live counts coincide. The total-fiber workload runs
265 sequential `all` groups of at most 31 children, so it reaches 8,192 fibers
while its live width stays at the separate gate value of 32 — the same
orthogonality the gates prove, now two and six binary orders of magnitude
higher. Both plans stay well below the independent 16-MiB cap, so unlike the
total-operation axis these levels are genuinely reachable and are reported as
`accepted` with no contract discrepancy.

The oracle checks these levels exactly rather than loosely: it recomputes the
bounded parallel-tree recipe from the same helper the renderer used and then
requires the plan to match it — group sizes, reset count, operation count,
maximum live width, root successor chain, and parent/child closure. Nothing in
the check is a level's typed-in literal, so the next level is checked as
strictly as the gate.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

open my $fh, '<:raw', 'ppif/ahb_lite_subordinate.ppif'
    or die "cannot read checked AHB source: $!";
local $/;
my $checked_ahb = <$fh>;
close $fh or die "cannot close checked AHB source: $!";

my %expected_live = (fibers_total => 32, simultaneously_live_fibers => 1_024);
for my $axis (qw(fibers_total simultaneously_live_fibers)) {
    my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
        primary_axis => $axis,
        level => 'qualification_candidate_v1',
        reference_hial_text => $checked_ahb,
    });
    die $workload->{diagnostics}[0]{message} unless $workload->{ok};

    my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
        construction => $workload,
    });
    die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
    die "unexpected fiber qualification\n"
        unless $evaluation->{status} eq 'accepted'
            && $evaluation->{metrics}{simultaneous_live_fibers}
                == $expected_live{$axis};
}
```

The live-width axis then goes all the way to its own cap, and it is the first
axis on this leaf that does:

| Level | Live fibers | Plan result |
| --- | ---: | --- |
| limit | 16,384 | accepted; 6,553,464-byte plan |
| over limit | 16,385 | rejected by the 16,384 live-fiber execution limit |

This matters because the number reached is the axis's own. The 6,553,464-byte
limit plan is well inside the independent 16-MiB bound, so nothing pre-empts the
`simultaneous_live_fibers` cap of 16,384 declared in the execution contract — the
workload reaches it, and the plan reports exactly 16,384 total fibers, 16,384
simultaneously live fibers, 16,384 expanded operations, and 16,401 source maps.

The boundary is one fiber wide and nothing else moves. The over-limit source
adds exactly one 45-byte nested fiber record, 738,151 bytes become 738,196, and
the ordinary parser still accepts it: the `SemanticIR` carries all 16,385
expanded actions and the canonical checked-AHB bridge is built. Only the
execution stage rejects, with exactly one `VIAL_EXECUTION_LIMIT_ERROR`, phase
`limit`, message `simultaneous_live_fibers exceeds the limit 16384`, at
`/operation_graph/maximum_simultaneous_live_fibers`, leaving no partial
`VIALExecutionIR` and no partial plan. Because no earlier owner intervenes, this
evaluation records **no** `VIAL_SCALE_LIMIT_INTERACTION` — unlike the operation
and total-operation ladders, the reported cap needs no caveat.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

open my $fh, '<:raw', 'ppif/ahb_lite_subordinate.ppif'
    or die "cannot read checked AHB source: $!";
local $/;
my $checked_ahb = <$fh>;
close $fh or die "cannot close checked AHB source: $!";

my %expected = (
    limit_v1 => ['accepted', 16_384],
    over_limit_v1 => ['expected_rejection', undef],
);
for my $level (sort keys %expected) {
    my ($status, $live) = @{$expected{$level}};
    my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
        primary_axis => 'simultaneously_live_fibers',
        level => $level,
        reference_hial_text => $checked_ahb,
    });
    die $workload->{diagnostics}[0]{message} unless $workload->{ok};

    my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
        construction => $workload,
    });
    die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
    die "unexpected live-fiber outcome\n"
        unless $evaluation->{status} eq $status
            && (!defined($live)
                || $evaluation->{metrics}{simultaneous_live_fibers} == $live);
}
```

The total-fiber axis closes too, but it closes differently, and reaching it
required changing how the source is authored.

The literal one-record-per-fiber recipe used at the gate and qualification
levels cannot express these levels at all. A literal 65,536-fiber source needs
3,047,364 bytes while the parser caps one VIAL source at 1,048,576, so that form
saturates at 22,536 fibers — 22,537 already needs 1,048,590. `(repeat COUNT
action)` is the ordinary shipped form for exactly this situation, so the two
highest levels are authored compactly: two scenarios, each repeating one
`parallel all` group of 31 fibers, plus one trailing group when the count does
not divide evenly. Group width stays at the live-fiber gate value, so the two
fiber axes remain orthogonal here as they are at the gate, and the limit source
is 3,199 bytes rather than three megabytes.

| Level | Total fibers | Source bytes | Rejected by | Diagnostic path |
| --- | ---: | ---: | --- | --- |
| limit | 65,536 | 3,199 | 16-MiB serialized-plan cap | `/plan` |
| over limit | 65,537 | 4,270 | 65,536 total-fiber execution cap | `/operation_graph/fibers` |

The boundary is one fiber wide, and it separates two *different* authorities.
That follows from cap order rather than from the numbers: `ExecutionBuilder`
counts fibers while it builds the operation graph and measures plan bytes only
after serializing the plan. At 65,536 the structural check passes — the workload
genuinely reaches the axis's own nominal cap — and the run continues to a plan
that no longer fits in 16 MiB. At 65,537 the structural check fires first and no
plan is ever built, which also makes the over-limit level the cheaper of the two
to run. Neither leaves a partial `VIALExecutionIR` or plan, and the checked-AHB
bridge identity is unchanged in both.

Only the limit level records a `VIAL_SCALE_LIMIT_INTERACTION` routed to `.17.4`:
its own cap was reached, but a later cap decided the outcome. The over-limit
level records none, because the cap that rejected it is the axis's own.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

open my $fh, '<:raw', 'ppif/ahb_lite_subordinate.ppif'
    or die "cannot read checked AHB source: $!";
local $/;
my $checked_ahb = <$fh>;
close $fh or die "cannot close checked AHB source: $!";

my %expected_path = (
    limit_v1 => '/plan',
    over_limit_v1 => '/operation_graph/fibers',
);
for my $level (sort keys %expected_path) {
    my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
        primary_axis => 'fibers_total',
        level => $level,
        reference_hial_text => $checked_ahb,
    });
    die $workload->{diagnostics}[0]{message} unless $workload->{ok};

    my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
        construction => $workload,
    });
    die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
    die "unexpected total-fiber authority\n"
        unless $evaluation->{status} eq 'expected_rejection'
            && $evaluation->{diagnostics}[0]{semantic_path}
                eq $expected_path{$level};
}
```

The total-operation axis closes last, and it is the first whose two levels are
not proved the same way.

Its literal 32-scenario recipe cannot author either level. One record per
operation needs 14,003,075 source bytes at 1,000,000 operations against the
parser's 1,048,576-byte cap — that form saturates at 74,656 operations — and
1,000,001 is not divisible by the fixed 32-scenario fanout at all. Both levels
therefore use the same ordinary `(repeat COUNT action)` form the total-fiber
ladder uses: 32 scenarios, each one `(repeat 31249 (reset bus 1))`, expanding
to 31,250 operations apiece. That is 4,003 source bytes instead of fourteen
megabytes, and it parses in hundredths of a second. The over-limit level is the
same recipe with its single remainder operation on the trailing scenario, so
its 32 scenarios expand to 31,250 actions each except one at 31,251.

| Level | Total operations | Source bytes | Decided by | How |
| --- | ---: | ---: | --- | --- |
| limit | 1,000,000 | 4,003 | 16-MiB serialized-plan cap at `/plan` | preflight |
| over limit | 1,000,001 | 4,003 | 1,000,000 total-operation cap at `/operation_graph/operations` | measured run |

The difference is cost, and it is measured rather than assumed. Building the
operation graph costs about 5.0 KiB of resident state per operation, so a
million operation records need roughly 4.9 GiB before any cap is consulted, and
serializing a plan costs several times that again. Running the over-limit level
to its rejection was measured at 11 seconds and a 5,216-MiB peak descendant RSS
— above the 4,096-MiB default cutoff the scale contract selects, so it is
opt-in, RAM-guarded evidence:

```bash
FSMGEN_VIAL_SCALE_EXACT=1 scripts/run_with_ram_guard.sh \
  --process-max-rss-mb 6144 -- \
  prove -Iperl t/1626-vial-architecture-scale-execution-total-operation-limit.t
```

The limit level is not run at all, and that is a selected outcome rather than a
gap.
[Decision `0061`](../../decisions/0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md)
clause 8 says that once a smaller canonical witness proves monotonic 16-MiB
plan dominance, a larger nominal limit must not be materialized merely to
exhaust the host. The 65,536-operation qualification level is that witness: its
serialized plan is 21,511,563 bytes against the 16,777,216-byte cap, and a plan
gains bytes with every further operation record, so no larger total-operation
level can serialize smaller. Materializing 1,000,000 would spend roughly 32 GiB
of resident plan state to reach the same answer.

The generator therefore reports that level as `preflight_dominated` with
observed outcome `not_materialized`, claims no SemanticIR, bridge, or plan
identity for it, and records two separate facts: one
`VIAL_SCALE_LIMIT_INTERACTION` naming the plan cap that would decide, and one
`VIAL_SCALE_PREFLIGHT_DOMINANCE` naming the witness that already decided it.
Both are routed to `.17.4`. The raw builder refuses the level outright rather
than starting a run the selected resource envelope cannot finish.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

open my $fh, '<:raw', 'ppif/ahb_lite_subordinate.ppif'
    or die "cannot read checked AHB source: $!";
local $/;
my $checked_ahb = <$fh>;
close $fh or die "cannot close checked AHB source: $!";

my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
    primary_axis => 'operations_total',
    level => 'limit_v1',
    reference_hial_text => $checked_ahb,
});
die $workload->{diagnostics}[0]{message} unless $workload->{ok};

my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
    construction => $workload,
});
die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
die "unexpected total-operation limit outcome\n"
    unless $evaluation->{status} eq 'preflight_dominated'
        && $evaluation->{observed_outcome} eq 'not_materialized'
        && $evaluation->{contract_discrepancies}[1]{code}
            eq 'VIAL_SCALE_PREFLIGHT_DOMINANCE';
```

Everything cheap about both levels is still proved in the default test run: the
literal recipe's exact saturation point, the compact recipe's exact per-scenario
expansion, frozen source and workload identities, the unchanged checked-AHB
bridge identity, and each level's exact SemanticIR identity and per-scenario
action counts. Only the million-record execution graph is opt-in.

The execution-type qualification level closes next, and it is the first level
whose authority moved because the *stage order* was corrected rather than
because a count changed.

Decision `0061` clause 4 declares the evaluation order as ordinary VIAL source
and SemanticIR, then canonical HIAL bridge, then execution plan. The
checked-AHB route already followed it; the direct-IAL1 route used by the
binding and type axes built its bridge before parsing its VIAL source, so a
rejection could be reported from behind a later stage. Correcting that order
changed the answer for this level: the VIAL parser's own 4,096-declaration
package-section cap decides, ahead of every bridge cap.

| Level | Types | HIAL bytes | VIAL bytes | Decided by | Diagnostic path |
| --- | ---: | ---: | ---: | --- | --- |
| gate | 512 | 17,901 | 63,780 | accepted; 735,488-byte plan | — |
| qualification | 8,192 | 293,894 | 1,023,293 | 4,096-declaration VIAL package-section cap | `/packages/0/types` |

The 1,023,293-byte source is comfortably inside the 1,048,576-byte parser
source cap, so what rejects is a declaration cap and not a byte cap: the
ordinary parser returns exactly one `VIAL_LIMIT_ERROR`, phase `limit`, message
`package section 'types' exceeds 4096 declarations`, at `/packages/0/types`.
No bridge is built behind it, so the evaluation claims neither a SemanticIR nor
a bridge identity, and it records one `VIAL_SCALE_LIMIT_INTERACTION` at
`/requested_counts/execution_types` routed to `.17.4`.

The route's own boundary is lower still, and it is measured rather than
inferred. Building the canonical direct-IAL1 bridge over the same renderer
accepts exactly **1,043 types** — 1,043 manifest types, 1,045 endpoints, and a
manifest inside the 16,777,216-byte serialized bridge cap — while 1,044 returns
`HIAL_VIAL_BRIDGE_LIMIT_ERROR`, `serialized manifest exceeds 16777216 bytes`,
at `/`. So neither the 4,096-type nor the 4,096-endpoint bridge cap is what
bounds this axis; the serialized-manifest cap is, at roughly twice the
512-type gate. The execution-type axis therefore has **no nominal operating
point above its gate**, and no type capacity beyond it is claimed as proved.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
    primary_axis => 'execution_types',
    level => 'qualification_candidate_v1',
});
die $workload->{diagnostics}[0]{message} unless $workload->{ok};

my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
    construction => $workload,
});
die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
die "unexpected execution-type authority\n"
    unless $evaluation->{status} eq 'expected_rejection'
        && $evaluation->{diagnostics}[0]{semantic_path} eq '/packages/0/types'
        && $evaluation->{contract_discrepancies}[0]{code}
            eq 'VIAL_SCALE_LIMIT_INTERACTION';
```

The exact route boundary is opt-in evidence, because each probe builds a full
canonical bridge:

```bash
FSMGEN_VIAL_SCALE_EXACT=1 scripts/run_with_ram_guard.sh -- \
  prove -Iperl t/1627-vial-architecture-scale-execution-type-qualification.t
```

The high binding, execution-type, and source-map levels require a distinct
result shape, because this is the one place where the selected contract and the
measured stack disagree.

Those levels cannot be authored the way the fiber and operation ladders were
rescued. `(repeat COUNT action)` repeats *actions*; events, types, and endpoints
are *declarations*, and neither the public `.vial` nor the public `.isf` grammar
has a declaration-repetition form. One record per unit is the only shape, so the
generated source grows linearly and crosses the workload's own 1,114,112-byte
bounded-construction envelope before any product stage runs — 1,933,429 HIAL
bytes at 32,768 bindings, 2,413,815 at 65,536 execution types, 3,670,808 VIAL
bytes at 262,144 source-map records, and 14,000,792 at a million.

The deeper fact is that these caps are unreachable through any shipped route,
not merely through a bigger source. The execution contract declares `bindings`
65,536, `execution_types` 65,536, and `source_map_records` 1,000,000, while the
bridge contract declares `events` 2,048, `types` 4,096, `endpoints` 4,096, and a
16,777,216-byte serialized manifest, and the plan carries its own 16,777,216-byte
cap. A lower cap in the layer below always wins. Each axis's genuine boundary is
measured through the canonical route:

| Axis | Declared execution cap | Measured route boundary | Accepted plan | Cap that decides one past it |
| --- | ---: | ---: | ---: | --- |
| bindings | 65,536 | accepts 2,054 | 2,664,611 bytes | bridge `events` 2,048, at `/events` |
| execution types | 65,536 | accepts 1,043 | 1,493,527 bytes | 16-MiB serialized manifest, at `/` |
| source-map records | 1,000,000 | accepts 46,294 | 16,777,026 bytes | 16-MiB serialized plan, at `/plan` |

That is roughly 32x, 63x, and 22x below the declared caps. Each boundary is a
whole-route claim, not a stage one: the accepted count is carried through the
ordinary semantic stage, the canonical bridge, *and* the public binder to a real
plan, because a bridge that accepts is not yet a route that accepts.

[Decision `0072`](../../decisions/0072-an-unreachable-declared-cap-is-a-result-not-a-level-to-rewrite.md)
selects what to do about it, and the short version is: nothing is rewritten. The
selected levels stay as they are, because they are the execution contract's own
declared caps and "no shipped route reaches this cap" is a result worth keeping,
not a level worth editing. The construction envelope stays as it is, because it
is only the first obstacle — at 65,536 bindings the VIAL source is already
1,442,356 bytes against the product's own 1,048,576-byte parser cap — so raising
it would trade a fixture bound for a product bound and still not reach the
declared cap.

What changes is what a level *reports*. Every unreachable level must carry three
numbers rather than one: the declared cap it was selected from, the earliest cap
that actually decides with its exact diagnostic and path, and the axis's measured
route boundary. A level whose earliest decider is the construction envelope must
always carry the third, because the envelope is a property of the fixture and a
fixture bound must never be read as a product limit. Such a level evaluates to
`envelope_unconstructible` with observed outcome `not_constructed`, claims no
stage identity, and records both a `VIAL_SCALE_LIMIT_INTERACTION` and a
`VIAL_SCALE_ROUTE_BOUNDARY` routed to `.17.4` — the same shape
`preflight_dominated` already uses for a level that is deliberately not run.

The cap inconsistency itself belongs to `.17.4`, which owns explicit architecture
resource caps and graceful bounded failure, and which will decide whether the
execution caps come down to what the stack reaches, the lower layers go up, or
the layering is documented as deliberate.

The binding ladder is the first axis authored under that rule. Its three levels
above the gate generate 1,933,429, 3,866,741, and 3,866,800 direct-IAL1 bytes —
one genuine `(event bridge_event_XXXXXXXX …)` record per binding above the fixed
six — against a 1,114,112-byte envelope, and the generated source grows linearly
because an event is a declaration with no repetition form. All three are
therefore reported the same way:

| Level | Bindings | Direct-IAL1 bytes | Outcome |
| --- | ---: | ---: | --- |
| gate | 2,048 | 120,949 | accepted; 2,656,823-byte plan |
| qualification | 32,768 | 1,933,429 | `envelope_unconstructible` |
| limit | 65,536 | 3,866,741 | `envelope_unconstructible` |
| over limit | 65,537 | 3,866,800 | `envelope_unconstructible` |

An `envelope_unconstructible` level returns the workload constructor's own exact
`VIAL_SCALE_INPUT_ERROR`, `input 0 exceeds the bounded construction envelope`, at
`/inputs/0/content`; retains no oversized source in its record; claims no
workload, SemanticIR, bridge, or plan identity; and refuses to build. Its
evaluation carries both required records — a `VIAL_SCALE_LIMIT_INTERACTION`
saying in as many words that the decider is a fixture bound and not a product
limit, and a `VIAL_SCALE_ROUTE_BOUNDARY` giving the measured alternative: the
canonical route accepts 2,054 bindings and rejects 2,055 with
`events count 2049 exceeds limit 2048` at `/events`, against the declared
65,536-binding execution cap the level was selected from. Both route to `.17.4`.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
    primary_axis => 'bindings',
    level => 'limit_v1',
});
my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
    construction => $workload,
});
die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
die "unexpected binding outcome\n"
    unless $evaluation->{status} eq 'envelope_unconstructible'
        && $evaluation->{observed_outcome} eq 'not_constructed'
        && $evaluation->{contract_discrepancies}[1]{code}
            eq 'VIAL_SCALE_ROUTE_BOUNDARY';
```

The 2,054/2,055 boundary itself builds two real canonical bridges, so it is
opt-in evidence:

```bash
FSMGEN_VIAL_SCALE_EXACT=1 scripts/run_with_ram_guard.sh -- \
  prove -Iperl t/1628-vial-architecture-scale-execution-binding-limits.t
```

The execution-type gate uses a different canonical route because the frozen
AHB actor exposes only seven distinct normalized types. It generates one
ordinary, non-annotated direct-IAL1 public input for each width from 1 through
512 and binds each from one VIAL endpoint of the exact same unsigned
four-state logic shape. These are used representation proofs, not unreferenced
type declarations: the unchanged public binder materializes exactly 512 type-
table entries, each with one semantic identity, one carrier type, and one
`drive` relation.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
    primary_axis => 'execution_types',
    level => 'gate_candidate_v1',
});
die $workload->{diagnostics}[0]{message} unless $workload->{ok};

my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
    construction => $workload,
});
die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
die "unexpected type count\n"
    unless $evaluation->{metrics}{execution_types} == 512;
```

The resulting target-neutral plan has 514 bindings (unit, domain, and 512
endpoints), 514 source maps, one scenario/reset/root fiber, and 735,488
canonical bytes. Its direct-IAL1 bridge report is exactly 8,237,394 bytes,
reproducing the reachability selection. It retains the public
`hial_vial.bridge_source.ial1` capability and exact `IAL1 -> IAL0` review
route, with neither the AHB protocol capability nor the private scale
capability. Independent construction freezes the generated HIAL/VIAL,
SemanticIR, bridge, and plan identities. A mutated source, caller-injected
HIAL, or unfinished level fails closed.

The two highest execution-type levels now close under decision `0072` without
pretending that the fixture envelope is a product limit. Each type requires one
real direct-IAL1 input, one real VIAL type declaration, and one bound endpoint;
neither public grammar has a declaration-repetition form. The generated HIAL
therefore crosses the workload's 1,114,112-byte per-input envelope first:

| Level | Types | HIAL bytes | VIAL bytes | Outcome |
| --- | ---: | ---: | ---: | --- |
| limit | 65,536 | 2,413,815 | 8,246,830 | `envelope_unconstructible` |
| over limit | 65,537 | 2,413,852 | 8,246,956 | `envelope_unconstructible` |

Both constructions return only the exact `VIAL_SCALE_INPUT_ERROR`,
`input 0 exceeds the bounded construction envelope`, at `/inputs/0/content`.
They retain no oversized source, claim no workload, SemanticIR, bridge, or plan
identity, and the raw builder refuses them. Evaluation reports observed outcome
`not_constructed` and carries the two records decision `0072` requires: the
fixture-bound `VIAL_SCALE_LIMIT_INTERACTION` and the measured
`VIAL_SCALE_ROUTE_BOUNDARY`. The latter states that the whole canonical route
accepts 1,043 types and rejects 1,044 at the 16-MiB serialized bridge-manifest
cap, against the unchanged declared execution cap of 65,536.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
    primary_axis => 'execution_types',
    level => 'limit_v1',
});
my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
    construction => $workload,
});
die "unexpected execution-type limit outcome\n"
    unless $evaluation->{ok}
        && $evaluation->{status} eq 'envelope_unconstructible'
        && $evaluation->{observed_outcome} eq 'not_constructed'
        && $evaluation->{contract_discrepancies}[1]{code}
            eq 'VIAL_SCALE_ROUTE_BOUNDARY';
```

These are construction and reachability facts, not a supported capacity claim.

The source-map gate returns to the frozen checked-AHB route. That binding has
exactly 17 fixed maps: one domain, three public endpoint relations, one probe
relation, six transaction-field relations, and six event bindings. The gate
therefore authors 8,175 real one-cycle resets so the target-neutral execution
plan contains exactly 8,192 source-map records without duplicating a map or
padding the source.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

open my $fh, '<:raw', 'ppif/ahb_lite_subordinate.ppif'
    or die "cannot read checked AHB source: $!";
local $/;
my $checked_ahb = <$fh>;
close $fh or die "cannot close checked AHB source: $!";

my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
    primary_axis => 'source_map_records',
    level => 'gate_candidate_v1',
    reference_hial_text => $checked_ahb,
});
die $workload->{diagnostics}[0]{message} unless $workload->{ok};

my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
    construction => $workload,
});
die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
die "unexpected map construction\n"
    unless $evaluation->{metrics}{source_map_records} == 8_192
        && $evaluation->{metrics}{expanded_operations_total} == 8_175;
```

All 8,192 plan paths are unique. Operation map `N` points to semantic action
`N`, carries one ordered non-empty generated-VIAL byte span, and needs no
fabricated bridge fact; each fixed binding map resolves to its real bridge
fact. The 8,175 resets form one contiguous successor chain in one root fiber.
The generated VIAL is 115,478 bytes, the unchanged checked-AHB bridge report
is 508,968 bytes, and the deterministic plan is 2,949,646 bytes. Exact source,
SemanticIR, bridge, workload, and plan identities are regression-locked. The
public AHB capability remains present, the private scale capability remains
absent, and mutation, missing checked source, or an unfinished level fails
closed.

The three source-map levels above the gate now close under decision `0072` as
well. They retain the checked-AHB source as input 0 and grow input 1 by adding
one genuine reset for every requested map above the 17 fixed binding maps. The
generated VIAL source crosses the 1,114,112-byte per-input envelope at every
selected point:

| Level | Source maps | Resets | VIAL bytes | Outcome |
| --- | ---: | ---: | ---: | --- |
| qualification | 262,144 | 262,127 | 3,670,808 | `envelope_unconstructible` |
| limit | 1,000,000 | 999,983 | 14,000,792 | `envelope_unconstructible` |
| over limit | 1,000,001 | 999,984 | 14,000,806 | `envelope_unconstructible` |

Here the exact constructor diagnostic names input 1, not the fixed HIAL input:
`VIAL_SCALE_INPUT_ERROR`, `input 1 exceeds the bounded construction envelope`,
at `/inputs/1/content`. The rejected construction retains neither input and
claims no workload or stage identity. Evaluation is
`envelope_unconstructible` / `not_constructed`, the raw builder refuses it, and
the paired decision-`0072` records state both the fixture-bound decider and the
measured whole-route alternative: 46,294 maps accept in a 16,777,026-byte plan,
while 46,295 rejects at the 16,777,216-byte serialized-plan cap at `/plan`,
against the declared one-million-map execution cap.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

open my $fh, '<:raw', 'ppif/ahb_lite_subordinate.ppif'
    or die "cannot read checked AHB source: $!";
local $/;
my $checked_ahb = <$fh>;
close $fh or die "cannot close checked AHB source: $!";

my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
    primary_axis => 'source_map_records',
    level => 'limit_v1',
    reference_hial_text => $checked_ahb,
});
my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
    construction => $workload,
});
die "unexpected source-map limit outcome\n"
    unless $evaluation->{ok}
        && $evaluation->{status} eq 'envelope_unconstructible'
        && $evaluation->{observed_outcome} eq 'not_constructed'
        && $evaluation->{diagnostics}[0]{path} eq '/inputs/1/content'
        && $evaluation->{contract_discrepancies}[1]{code}
            eq 'VIAL_SCALE_ROUTE_BOUNDARY';
```

The 46,294/46,295 whole-route boundary remains opt-in evidence because both
probes build complete plans:

```bash
FSMGEN_VIAL_SCALE_EXACT=1 scripts/run_with_ram_guard.sh -- \
  prove -Iperl t/1607-vial-architecture-scale-execution-source-maps.t
```

The random-attempt gate also uses the frozen checked-AHB route, but isolates the
primary axis to one referenced two-state `u64` choice. Its uniform distribution
covers `0..2^64-1`; an authored equality constraint selects decimal
`9053010565424434193` (`0x7da2c124f3fb4c11`), the deterministic proposal at
zero-based attempt 8,191. One real `expect` operation references that choice in
the portable `check` phase, so the decision cannot be optimized away or counted
without executable semantics.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

open my $fh, '<:raw', 'ppif/ahb_lite_subordinate.ppif'
    or die "cannot read checked AHB source: $!";
local $/;
my $checked_ahb = <$fh>;
close $fh or die "cannot close checked AHB source: $!";

my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
    primary_axis => 'random_attempts',
    level => 'gate_candidate_v1',
    reference_hial_text => $checked_ahb,
});
die $workload->{diagnostics}[0]{message} unless $workload->{ok};

my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
    construction => $workload,
});
die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
die "unexpected random construction\n"
    unless $evaluation->{metrics}{random_attempts} == 8_192
        && $evaluation->{metrics}{random_occurrences} == 1;
```

Evaluation performs two independent generated builds and a strict
`fsmgen.vial_replay.v1` build through the unchanged public binder. Generated
and replayed decision records are byte-equal after removing `origin`; the only
permitted values are `generated` and `replayed`. The derived plan identity also
changes, while every other plan field is equal. The generated/replayed plans
are exactly 34,295/34,294 canonical bytes. The execution graph contains one
scenario, operation, and root/live fiber, eight normalized types, 22 bindings,
and 19 maps: the 17 fixed checked-AHB maps plus one operation map and one
decision map. Independent identities, public capability isolation, replay-
attempt mutation, source mutation, missing checked source, and level-specific
admission are regression-locked.

The random-attempt qualification reuses that exact route at 262,144 attempts.
Its equality constraint selects decimal `68173369137783556`
(`0x00f233516a996304`), the deterministic proposal at zero-based attempt
262,143. The generated decision and strict replay retain the same occurrence,
normalized value, attempt, distribution, type, operation reference, and source
span; again, only `origin` changes. The generated/replayed plans are exactly
34,297/34,296 canonical bytes with IDs
`plan/1f01b357206cb9b768172be41b415084b0ee49ef5494131dd50df74d195d185e`
and
`plan/a6d4516c28989dccf67d0989d7a71d8e60cc6315451761947386d86a75123ba7`.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

open my $fh, '<:raw', 'ppif/ahb_lite_subordinate.ppif'
    or die "cannot read checked AHB source: $!";
local $/;
my $checked_ahb = <$fh>;
close $fh or die "cannot close checked AHB source: $!";

my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
    primary_axis => 'random_attempts',
    level => 'qualification_candidate_v1',
    reference_hial_text => $checked_ahb,
});
die $workload->{diagnostics}[0]{message} unless $workload->{ok};

my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
    construction => $workload,
});
die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
die "unexpected random qualification\n"
    unless $evaluation->{metrics}{random_attempts} == 262_144
        && $evaluation->{metrics}{random_occurrences} == 1;
```

The exact limit uses the same isolated graph. Candidate
`0xdd7997a868500a54` succeeds at zero-based attempt 999,999; generated and
strict-replay plans are 34,297/34,296 bytes with IDs
`plan/02b9207cd9392ba8b0d9e52afe9912f026fc00412ace076ff0fc30a32868b614`
and
`plan/90660802ee2bbbebdad84f79f66e1f5b6102befdb45de2f4c36f9a0d7f359f90`.
The adjacent source targets candidate `0xce7d67adbe54da82` at attempt
1,000,000. The unchanged public binder exhausts after its shipped million
attempts and returns only `VIAL_RANDOM_EXHAUSTED` in phase `random`, with no
partial ExecutionIR or plan. The evaluator accepts only that exact diagnostic
as the selected over-limit result.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

open my $fh, '<:raw', 'ppif/ahb_lite_subordinate.ppif'
    or die "cannot read checked AHB source: $!";
local $/;
my $checked_ahb = <$fh>;
close $fh or die "cannot close checked AHB source: $!";

for my $case (['limit_v1' => 1_000_000], ['over_limit_v1' => undef]) {
    my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
        primary_axis => 'random_attempts',
        level => $case->[0],
        reference_hial_text => $checked_ahb,
    });
    my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
        construction => $workload,
    });
    die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
    if (defined $case->[1]) {
        die "unexpected random limit\n"
            unless $evaluation->{metrics}{random_attempts} == $case->[1];
    } else {
        die "unexpected random exhaustion\n"
            unless $evaluation->{status} eq 'expected_rejection';
    }
}
```

These are deterministic construction and boundary facts, not throughput,
capacity, final qualification, or support promotion.

The first serialized-plan byte gate now reaches exactly one MiB through the
same checked-AHB source and public binder. It authors 2,974 real reset actions,
not an imported plan or opaque byte field. A bounded scenario identifier closes
the selected 41-character semantic suffix, while endpoint alias `r_q` closes
the two-character suffix and remains live because coverpoint `c` samples its
real `HREADYOUT` binding. The generated source is a single semantic form plus
its terminating newline; comments, blank data, and path inflation contribute
nothing.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

open my $fh, '<:raw', 'ppif/ahb_lite_subordinate.ppif'
    or die "cannot read checked AHB source: $!";
local $/;
my $checked_ahb = <$fh>;
close $fh or die "cannot close checked AHB source: $!";

my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
    primary_axis => 'serialized_plan_bytes',
    level => 'gate_candidate_v1',
    reference_hial_text => $checked_ahb,
});
die $workload->{diagnostics}[0]{message} unless $workload->{ok};

my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
    construction => $workload,
});
die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
die "unexpected plan-byte construction\n"
    unless $evaluation->{metrics}{serialized_plan_bytes} == 1_048_576
        && $evaluation->{metrics}{expanded_operations_total} == 2_974;
```

The canonical plan contains one scenario and root/live fiber, 22 bindings,
seven execution types, six bridge events, and exactly 2,991 source maps: 17
fixed checked-AHB maps plus one for every reset. All map paths and generated
source spans are unique and closed; every reset is a drive-phase operation in
one contiguous successor chain. Independent construction is byte-stable. The
plan has ID
`plan/ee10e4a5749a4398b9e62d5a1624d24c74e585459afd57f8cb7503306545c035`
and canonical SHA-256
`15106539d198cc3a3df2cfc73c87a7f8039cda02a9327f151bec196228a258be`.
These are reproducible construction facts, not a support or capacity claim.

The qualification recipe reaches exactly four MiB through the same public
binder. It authors 12,166 real resets in scenario `sg_4_mib`. Compact domain
alias `b` still resolves the checked AHB clock/reset domain, and endpoint alias
`ready_out_q` remains referenced by coverpoint `ready_sampled` on the real
`HREADYOUT` binding. The generated VIAL is one semantic form plus its newline;
its 147,115 bytes contain no comments, blank data, imported plan, or opaque
padding.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

open my $fh, '<:raw', 'ppif/ahb_lite_subordinate.ppif'
    or die "cannot read checked AHB source: $!";
local $/;
my $checked_ahb = <$fh>;
close $fh or die "cannot close checked AHB source: $!";

my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
    primary_axis => 'serialized_plan_bytes',
    level => 'qualification_candidate_v1',
    reference_hial_text => $checked_ahb,
});
die $workload->{diagnostics}[0]{message} unless $workload->{ok};

my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
    construction => $workload,
});
die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
die "unexpected qualification plan\n"
    unless $evaluation->{metrics}{serialized_plan_bytes} == 4_194_304
        && $evaluation->{metrics}{expanded_operations_total} == 12_166
        && $evaluation->{metrics}{source_map_records} == 12_183;
```

The target-neutral plan contains one scenario and root/live fiber, 22
bindings, seven execution types, six bridge events, and exactly 12,183 unique
source maps. It has ID
`plan/63673374ece891a4234613c00c920ffe60cb4d6d73904ba0be2a2d5799f60d62`
and canonical SHA-256
`bc5d44cd8bdafcb50654c1a7c8c3e0ac7101b496b16084cad9535d901253d076`.
The checked-AHB bridge remains byte-identical to the one-MiB gate. Independent
construction, every reset successor, every source span, the public capability
boundary, post-identity mutation rejection, missing checked source, and the
separately exercised adjacent over-limit boundary are regression-locked. This
is qualification construction evidence, not a promoted support or capacity
claim.

The limit recipe reaches exactly sixteen MiB without changing the binder or
its declared byte ceiling. It authors 48,850 genuine resets under one scenario
whose referenced semantic suffix has the selected 106 characters. Endpoint
`ready_out_q` remains sampled by coverpoint `ready_sampled`; bin `asserted1`
names the genuine value-one match. The compact repository-relative source route
is `generated/vial-scale/execution_graph/p16m.vial`. Its 587,422-byte VIAL
source is one semantic form plus its newline, with no comments, blank data,
path inflation, caller-created plan, or opaque padding.

```perl
use FSM::VIAL::ArchitectureScaleExecutionGraph;

open my $fh, '<:raw', 'ppif/ahb_lite_subordinate.ppif'
    or die "cannot read checked AHB source: $!";
local $/;
my $checked_ahb = <$fh>;
close $fh or die "cannot close checked AHB source: $!";

my $workload = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
    primary_axis => 'serialized_plan_bytes',
    level => 'limit_v1',
    reference_hial_text => $checked_ahb,
});
die $workload->{diagnostics}[0]{message} unless $workload->{ok};

my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
    construction => $workload,
});
die $evaluation->{diagnostics}[0]{message} unless $evaluation->{ok};
die "unexpected limit plan\n"
    unless $evaluation->{metrics}{serialized_plan_bytes} == 16_777_216
        && $evaluation->{metrics}{expanded_operations_total} == 48_850
        && $evaluation->{metrics}{source_map_records} == 48_867;
```

The plan has ID
`plan/0709d0c4d1432a218a0f26d9cce0c2b308d2f6fcf95f008bf6ceb65b15dc1e64`
and canonical SHA-256
`0fcf9649c03cf53745842ed4161d42ced9030df297a30a894b56e9ba3448b98e`.
It retains one scenario/root/live fiber, 22 bindings, seven execution types,
six bridge events, and 48,867 unique source maps. The checked-AHB bridge remains
508,968 bytes and byte-identical to the smaller exact plans. Independent
construction, the complete reset successor chain, source spans, public
capability isolation, hostile-input rejection, and missing checked source are
regression-locked. This exact limit is construction evidence, not promoted
scale support or a performance budget.

The adjacent over-limit recipe changes no limit semantic name, source path,
coverpoint, bin, or timeout. It appends exactly one complete 12-byte
` (reset b 1)` record to the accepted source, producing 48,851 genuine resets
in 587,434 source bytes. Removing that last record reproduces the exact limit
source byte-for-byte. Ordinary parsing accepts the complete source; the
unchanged public builder then rejects the serialized plan at its authoritative
16-MiB cap.

```perl
my $over = FSM::VIAL::ArchitectureScaleExecutionGraph->construct({
    primary_axis => 'serialized_plan_bytes',
    level => 'over_limit_v1',
    reference_hial_text => $checked_ahb,
});
die $over->{diagnostics}[0]{message} unless $over->{ok};

my $evaluation = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
    construction => $over,
});
die "over-limit oracle failed\n"
    unless $evaluation->{ok}
        && $evaluation->{status} eq 'expected_rejection'
        && $evaluation->{diagnostics}[0]{code}
            eq 'VIAL_EXECUTION_LIMIT_ERROR'
        && $evaluation->{diagnostics}[0]{phase} eq 'limit'
        && $evaluation->{diagnostics}[0]{semantic_path} eq '/plan';
```

The exact message is
`serialized_plan_bytes exceeds the limit 16777216`. Rejection publishes no
partial ExecutionIR or plan, and the scale evaluator accepts no looser or
different diagnostic as the selected result. This is a boundary-conformance
fact, not evidence that the project supports a 16-MiB production workload.

The implemented ladder reports these selected outcomes:

| Axis | Gate | Qualification | Limit | Over limit |
| --- | --- | --- | --- | --- |
| selected fixture/unit/domain | `1` accepted | `1` accepted | `1` accepted | scalar selection or bridge cap rejects `2` |
| scenarios | `32` accepted | `512` accepted | `4,096` accepted | scenario cap rejects `4,097` |
| operations in one scenario | `256` accepted | `8,192` accepted | plan-byte cap wins at `65,536` | semantic action cap rejects `65,537` |
| operations total | `1,024` accepted | plan-byte cap wins at `65,536` | plan-byte cap wins at `1,000,000` | total-operation cap rejects `1,000,001` |
| fibers total | `128` accepted | `8,192` accepted | plan-byte cap wins at `65,536` | total-fiber cap rejects `65,537` |
| simultaneously live fibers | `32` accepted | `1,024` accepted | `16,384` accepted | live-fiber cap rejects `16,385` |
| bindings | `2,048` accepted through the sealed event route | envelope rejects source before a product stage | envelope rejects source before a product stage | envelope rejects source before a product stage |
| execution types | `512` accepted through plain IAL1 | parser declaration cap wins | envelope rejects source before a product stage | envelope rejects source before a product stage |
| source-map records | `8,192` accepted | envelope rejects source before a product stage | envelope rejects source before a product stage | envelope rejects source before a product stage |
| random attempts | `8,192` accepted | `262,144` accepted | `1,000,000` accepted | deterministic exhaustion rejects `1,000,001` |
| serialized plan | exact 1 MiB | exact 4 MiB | exact 16 MiB | first additional complete operation is rejected |

Final default qualification runs the complete architecture-scale family from
`t/1600` through `t/1628` under the repository RAM guard: all 29 files and 136
tests pass. The execution generator publishes 40 selected shapes. The 25
catalog shapes outside that set are deliberate: all 13 `reference_v1` profiles
plus the four non-reference levels of each fixed scalar axis
(`selected_fixtures`, `selected_units`, and `selected_domains`). Every one fails
closed at the caller seal; none is an unfinished generated level.

Checking-state reachability and proof are now selected by
[decision `0073`](../../decisions/0073-checking-state-scale-uses-packed-state-oracles-and-static-cross-domains.md).
The selection keeps every declared level and reports the earliest authority
instead of rewriting a level around whatever happens to pass:

| Axis | Accepted levels | First earlier-cap level |
| --- | --- | --- |
| model instances | 32 / 1,024 / 4,096 | 4,097 at `/models` |
| scalar model-state cells | 512 / 32,768 / 65,536 | 65,537 at `/models` |
| scoreboard instances | 32 / 1,024 / 4,096 | 4,097 at `/scoreboards` |
| declared scoreboard capacity | 4,096 / 262,144 / 1,000,000 | 1,000,001 at the semantic capacity bound |
| coverpoints | 256 / 8,192 | 65,536 is envelope-unconstructible |
| bins plus static cross tuples | 4,096 / 262,144 / 1,000,000 | 1,000,001 at `/coverage` |
| faults | 32 / 1,024 / 4,096 | 4,097 at `/faults` |
| random occurrences | 1,024 | 32,768 and 65,536 hit plan bytes; 65,537 hits its count cap |

The implemented coverpoint renderer emits exactly 110 bytes per declaration plus
827 fixed bytes. It accepts 9,524 declarations in 1,048,467 source bytes and rejects 9,525 at the parser cap; selected 65,536/65,537 sources report
`envelope_unconstructible` with that product boundary recorded separately.

VIAL v1 crosses use only the Cartesian product of explicitly authored point
bins. The compact recipe puts 999 matching bins on each of two points, authors
their 998,001-tuple cross, and adds one independent bin: exactly
1,000,000 entries in 62,841 bytes. One 29-byte bin more returns only the exact
`/coverage` rejection at 62,870 bytes; no backend invents a bin or tuple.

Accepted model, scoreboard, coverage, fault, and random/replay levels execute state through caller-sealed canonical SemanticIR and ExecutionIR. The provider-free evaluator uses a 4,000,000-byte FIFO for one million scoreboard entries and a 125,000-byte LSB-first coverage vector.
One sample hits the entire authored domain; its vector digest is `ae450c20…`, while ordered-domain digest `696d5310…` closes illegal, ignore, bit, and order mutations. The random gate independently generates and strictly replays every keyed Boolean value.

Public runtime traces, `ResultProducer`, and the first portable SystemVerilog backend remain excluded as scale oracles: they project or implement a narrower profile and do not independently recompute the general state semantics above.
Implementation is separately owned under `.17.2.5.2`. Its completed model, scoreboard, coverage, fault, and random/replay slices publish 32 levels: four non-reference levels on each of eight axes:

```perl
use strict;
use warnings;
use lib 'perl';
use FSM::VIAL::ArchitectureScaleCheckingState;

my $owned = FSM::VIAL::ArchitectureScaleCheckingState->owned_shapes;
die "checking ladder ownership changed\n" unless @$owned == 32;
die "unexpected axis\n"
    if grep { $_->{primary_axis} !~ /\A(?:bins_and_cross_tuples|coverpoints|faults|model_instances|random_occurrences|scalar_model_state_cells|scoreboard_instances|scoreboard_capacity)\z/ }
        @$owned;
print "all eight checking-state axes own 32 non-reference levels\n";
```

`construct` rejects `reference_v1` because it remains a catalog record, plus unknown axes, levels, keys, IR, trace, result, or support metadata.
Internally, one same-package-only candidate boundary accepts just generated ordinary VIAL text and the exact 1,326-byte checked-AHB source. It regenerates the content-addressed workload before every build or evaluation, then produces SemanticIR, the IAL2-via-generated-and-reparsed-IAL1 bridge, ExecutionIR, and plan only canonically. Callers cannot inject them.

The model-instance source reuses one known unsigned eight-bit counter with an
initial value of zero and a rule that adds one on the checked AHB `accepted`
event. It binds that same definition to 32, 1,024, or 4,096 distinctly named
instances. The scalar-state source instead binds 32 instances to one definition
containing 16, 1,024, or 2,048 cells. That factorization reaches exactly 512,
32,768, or 65,536 cells without duplicating state declarations in source. The
65,537 excess adds a separate one-cell definition and one instance.

| Axis/level | Requested | Generated VIAL bytes | Outcome |
| --- | ---: | ---: | --- |
| model gate / qualification / limit | 32 / 1,024 / 4,096 | 6,753 / 173,409 / 689,505 | accepted and state-checked |
| model excess | 4,097 | 689,673 | exact model-instance cap at `/models` |
| scalar-cell gate / qualification / limit | 512 / 32,768 / 65,536 | 10,935 / 250,839 / 494,551 | accepted and state-checked |
| scalar-cell excess | 65,537 | 495,108 | exact scalar-cell cap at `/models` |
| scoreboard instances | 32 / 1,024 / 4,096 | 6,404 / 168,100 / 668,836 | accepted and FIFO-checked; 4,097 rejects at `/scoreboards` in 668,999 bytes |
| scoreboard capacity | 4,096 / 262,144 / 1,000,000 | 1,351 / 1,353 / 1,354 | accepted and FIFO-checked; 1,000,001 rejects at the semantic bound in 1,354 bytes |
| faults | 32 / 1,024 / 4,096 | 5,650 / 148,498 / 590,866 | accepted and lifecycle-checked; 4,097 rejects at `/faults` in 591,010 bytes |
| random occurrences | 1,024 / 32,768 / 65,536 / 65,537 | 26,101 / 470,412 / 933,555 / 933,642 | generated/replayed gate; exact plan rejection; preflight-dominated; exact occurrence-cap rejection |

Every admitted model/scoreboard source stays below the construction envelope. For an
accepted level, the provider-free oracle reads the event binding and complete
rule from canonical ExecutionIR, requires the exact known u8 `0 + 1` shape,
and synthesizes one ordered `accepted` occurrence per instance. It initializes,
commits, and reads every cell. Its packed initial bytes must equal an
independently derived all-zero vector, and its packed final bytes must equal an
independently derived all-one vector. For the 65,536-cell limit those SHA-256
identities are `de2f2560…` and `916b1448…`; the report also carries exact first
and last instance, state, trigger, count, and byte identities. Unknown-bit masks
and post-identity source or report mutation fail closed.

At 4,097 instances and 65,537 cells, canonical execution returns one complete
`VIAL_EXECUTION_LIMIT_ERROR` only, with semantic path `/models`. The evaluation
publishes the accepted SemanticIR and bridge identities but no ExecutionIR or
plan identity and explicitly says the state oracle did not run. Independent
route rejection must reproduce the diagnostic byte-for-byte. The default
foundation/model suite passes at Files=2/Tests=11; the four high accepted levels
pass their exact RAM-guarded sweep.

The scoreboard-instance source binds one shared capacity-one in-order definition
to 32, 1,024, or 4,096 instances; the capacity source binds one instance at
4,096, 262,144, or 1,000,000. Its single-reset scenario lets the qualification
oracle supply the bounded transaction program without a million-operation plan.

Each entry stores only a big-endian 32-bit varying payload. The oracle
reconstructs five fixed fields, compares all six fields, preserves FIFO order,
drains both queues, and rejects mismatch, at-capacity enqueue, and byte
corruption. At one million entries it makes 6,000,000 comparisons over exactly
4,000,000 bytes (`a515ca39…`), reaches expected/actual depths 1,000,000/1, and
ends with zero pending entries.

Instance 4,097 returns only `VIAL_EXECUTION_LIMIT_ERROR` at `/scoreboards`,
with semantic/bridge but no downstream identity. Capacity 1,000,001 returns
parser `VIAL_LIMIT_ERROR` at `/packages/0/scoreboards/0/capacity` with no stage
identity. Reruns reproduce both diagnostics; hostile policy/source/report
mutations fail closed. Default Files=3/Tests=17 and the exact scoreboard sweep
pass under the 4,096-MiB repository RAM guard.

The fault source targets the checked AHB write transaction's three-bit `size` field. Each
declaration substitutes known `7` for original `2` for one `bus` drive interval. The oracle
validates every target and lifetime, then arms, applies, expires, and restores every fault in
stable declaration order. Actual and independently reconstructed streams hash four
length-delimited lifecycle records per fault, so 4,096 faults prove 16,384 transitions with
digest `4042b666…` without a 4,096-entry report array. Armed reinjection, active overlap,
substitute/order/source/report mutation fail closed. Fault 4,097 returns only `VIAL_EXECUTION_LIMIT_ERROR` at `/faults` and no execution/plan identity. Guarded default Files=5/Tests=29 and exact Files=1/Tests=5 pass.

The random renderer reuses a bounded palette of 128 Boolean choices. Each referenced `(scenario, choice)` pair is one real occurrence, so the 1,024 gate contains eight scenarios and its canonical plan is exactly 2,073,805 bytes. The oracle generates all keyed values twice, creates and strictly replays the canonical manifest, and requires byte-equal origin-free decision sequences and plans. Keyed-value and order mutations fail closed.

Higher selected levels preserve the earliest real authority. The full 32,768 route counts all occurrences in SemanticIR and returns only `VIAL_EXECUTION_LIMIT_ERROR` at `/plan`. The 65,536 level is explicitly `preflight_dominated` / `not_materialized`, publishes no stage identity, and does not claim the nominal occurrence count. The 65,537 route reaches only the exact `/randomness/decisions` diagnostic. Opt-in evidence accepts 8,440 occurrences at 16,775,415 plan bytes and rejects adjacent 8,441 at the 16,777,216-byte cap. These are exact checking outcomes, not supported-capacity or runtime-throughput claims.

The frozen foundation route uses the checked AHB VIAL content as a deliberately
non-axis-evaluated source witness. Its workload identity is
`workload/7a125500c716e333ac8849ca5594849dc52e34380f0ba0ec416a2e12975247c7`;
its SemanticIR, bridge, ExecutionIR, and plan digests are respectively
`00dce649…`, `a4565d40…`, `5f04ca97…`, and `1a3b97f4…`. The 44,467-byte plan
observes two model instances/two scalar cells, one capacity-four scoreboard,
one coverpoint/two static bins, one fault, and one keyed random occurrence. The
report says `accepted_not_axis_evaluated`, sets both `axis_oracle_executed` and
`selected_count_claimed` false, and carries no axis evidence. Those observations
therefore cannot be mistaken for the requested 32-model gate.

The closed report populates model, scoreboard, coverage, fault, or `random_replay` evidence only for the corresponding accepted level. Its
packed contract fixes big-endian fixed-width model values with unknown-state rejection, a
big-endian 32-bit FIFO payload capped at 1,000,000 entries/4,000,000 bytes with complete
transaction reconstruction, and an LSB-first coverage vector capped at 1,000,000
entries/125,000 bytes with independent byte equality. It claims qualification-only status
and denies capability, support, performance, capacity, backend, runtime, and owned-level authority.

Independent complete-route reruns reproduce every stage digest; the foundation keeps its
`rerun/ceefc4f30…` identity and each generated level has its own content address. Canonical
regeneration rejects construction/evaluation mutation. Success and consumer failure stage
only below repository-derived `.artifacts/tmp/vial-scale/` and remove that exact directory.
Focused `t/1635` freezes exactly 32 selected shapes and eight rejected references, byte-equal gate reports, hostile-caller rejection, nonclaims, and cleanup. Guarded default `t/1629`-`t/1635` passes at Files=7/Tests=36 in 166 seconds; the complete exact `t/1630`-`t/1634` matrix passes at Files=5/Tests=27 in 593 seconds under the 4,096-MiB RAM guard.
These fixtures change no parser, SemanticIR, bridge, ExecutionIR, backend,
runtime, public product API, capability, support, performance, or capacity behavior.

Backend-emission selection is complete under decision `0075`. Portable profiles start from the checked AHB reference, repeat its real response expectation before `scoreboard_check`, and use expanded operation total `T` as a profile-local axis through ordinary parsing, the checked-AHB bridge, public `PlanBuilder`, and canonical ExecutionIR. Portable SV selects `T=21/1,024/4,096/6,319`: eight artifacts/three sources, with the limit at 16,776,830 source bytes/6,352 maps; `6,320` rejects at `/artifacts`.
Portable VHDL selects `T=21/128/512/29,508`: seventeen artifacts/six sources/twenty checks, with the limit at 16,776,739 source bytes/29,546 maps; `29,509` renders 16,777,307 bytes and rejects. OSVVM uses the same ladder, copies those six sources byte-for-byte, and adds one fixed 4,351-byte adapter: its selected limit totals 16,781,090 wrapper-source bytes/29,553 maps, while `29,509` rejects in the portable foundation. Native UVM remains a selected review profile: `T=21` emits sixteen artifacts/ten sources/75 maps/fourteen checks; `T=22` is the first unsupported shape and must reject negotiation, so larger levels are not constructed.
Portable VHDL now indexes metadata and generated-line anchors once per source: guarded canonical emission accepts `T=29,508` twice at 16,776,739 bytes/29,546 maps with all twenty checks and retains exact atomic `T=29,509` rejection. OSVVM provider verification is reusable through one sealed callback evaluation, and all 59 portable maps are validated then translated after seven adapter entries for 66-map reference closure. Native UVM rejects T=22, larger plans, and changed same-count expectation shapes before artifact construction. The five repairs are qualified together; this is structural durability, not compile, runtime, support, performance, or capacity evidence.
`FSM::VIAL::BackendEmissionAuthority` is the single closed catalog/discovery source. It distinguishes portable SV's three source/eight total artifacts; portable VHDL's six/17 inventory, 59 reference maps, and twenty checks; OSVVM's six-source portable foundation, one 4,351-byte adapter, seven total sources, sixteen artifacts, portable-only 16-MiB boundary, 66 maps, and 12+20 checks; and native UVM's ten/sixteen inventory, 16-MiB and one-million-map enforced caps, and selected 21-operation/75-map/14-check/25-mapping matrix. Unknown, missing, obsolete, or contradictory fields fail closed. VIAL still accepts a 128-byte source identifier and rejects 129; generated maxima are 131/142/142/154 bytes below 255. Completed generator foundation `.17.2.6.3.1` retains a private profile-neutral qualification mode: it admits only the frozen checked-AHB source pair, independently regenerates ordinary SemanticIR, bridge manifest, canonical ExecutionIR, backend inputs, and target-neutral plan, preserves the frozen 21-operation non-emission report, and cleans success or consumer-failure staging below `.artifacts/tmp/vial-scale/`. Completed portable-SV child `.17.2.6.3.2` owns exactly the five selected routes through that boundary. Its caller-sealed profile module emits T=21/1,024/4,096/6,319 twice and proves the exact eight-artifact/three-source inventories at 164,093/2,803,325/10,910,333/16,776,830 source bytes with 54/1,057/4,129/6,352 complete maps; T=6,320 returns only `VIAL_BACKEND_LIMIT_EXCEEDED` at `/artifacts`, with no partial plan, operation, manifest, map, or artifact graph. Each accepted oracle freezes all three source hashes and ordered relative paths, checks every map's generated-source span, compares the exact mapped operation-ID set, validates encoded source-map and manifest closure, observes a stable 113-byte maximum generated identifier below the separate 255-byte limit, content-addresses the result, and rejects report mutation by canonical regeneration. Completed portable-VHDL child `.17.2.6.3.3` adds exactly five selected routes through the same boundary. Its caller-sealed profile module emits T=21/128/512/29,508 twice and proves the exact seventeen-artifact/six-source inventories at 116,560/174,929/386,897/16,776,739 source bytes with 59/166/550/29,546 complete maps and twenty passing structural checks; T=29,509 returns only `VIAL_VHDL_BACKEND_LIMIT_EXCEEDED` at `/artifacts`, with no partial plan, operation, manifest, map, validation, or artifact graph. Each accepted VHDL oracle freezes all six source hashes and ordered relative paths, checks every generated-line span, compares the exact mapped operation-ID set, validates encoded source-map, validation, and manifest closure, observes a stable 37-byte maximum generated identifier for this selected ladder below the separate 255-byte limit, content-addresses the result, and rejects report mutation by canonical regeneration. The modules remain pure: `prove -Iperl t/1645-vial-architecture-scale-backend-emission-foundation.t t/1646-vial-architecture-scale-backend-emission-portable-sv.t t/1647-vial-architecture-scale-backend-emission-portable-vhdl.t` reproduces the foundation and both completed ladder examples without executing Verilator, GHDL, or another external runtime and leaves no scale-stage residue. OSVVM `.4` is active only as the next clean implementation owner and owns no additional profile shape yet; native UVM and family closure remain proposed. No support, performance, runtime, whole-product capacity, native-UVM execution, or cross-backend claim is added.

These are construction outcomes, not supported capacities. The exact 1/4/16-
MiB plans contain 2,974/12,166/48,850 real reset operations plus bounded,
referenced scenario and endpoint identifiers that close the remaining byte
difference. The endpoint alias remains used by its coverpoint; comments, blank
data, path inflation, caller-created plans, and opaque padding are forbidden.

Random attempt level `N` authors a u64 equality constraint for the deterministic
candidate at zero-based attempt `N - 1`. This makes the million-attempt limit a
real successful generation, while the one-over target exhausts exactly. Replay
must preserve the keyed value and attempt byte-for-byte; only the decision
origin changes from generated to replayed.

Every accepted run must prove exact counts and IDs, logical-time ordering,
parallel join/cancel semantics, replay equality, source-map closure, immutable
reports, and equal plan identity on rerun. High-count construction is preflighted
against minimum representation and runs only under the repository RAM guard;
a killed or exhausted host is never accepted as a cap result.

Performance never substitutes for correctness. One validation plus three
measured gate runs, or one plus five qualification runs, must first pass every
stage oracle. Measurements retain wall and CPU time, peak process-tree and
single-descendant RSS, files/lines/bytes, semantic counts, exact tool/host
identity, and raw samples. The repository RAM guard retains its 88% host and
4,096-MiB descendant ceilings. A promoted pinned-host budget is frozen from
clean calibration with explicit headroom; unknown hosts run correctness,
determinism, safety, and cleanup without flaky performance failure.

Generated work stays below repository-derived `.artifacts/tmp/vial-scale/` and
is removed exactly. An over-limit proof must fail at the earliest authoritative
stage with a stable diagnostic, no partial publication, and no residue. Host
exhaustion, signal 137, or an external-tool crash is never accepted as the
product's limit behavior.

The public support snapshot and normative contract report the portable-SV
Runner's enforced 8-MiB compile and 64-MiB runtime capture limits. Those are
bounded transcript-capture controls, not scale qualification or evidence that
the selected AHB fixture approaches either limit.

Even a later passing architecture profile will not substitute for the
separately owned whole-product `big`/`really_big` qualification, mixed-language
scale, native-UVM runtime scale, synthesis scale, or general backend parity.
