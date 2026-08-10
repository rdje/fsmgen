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
`osvvm_common.AddressBusTransactionPkg`. Thirteen source-map entries, twelve
structural checks, and six unchanged-semantic guards keep portable replay,
phase order, comparison/coverage meaning, trace, and normalized results in
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

The private emitter and validator are discoverable through the capability
manifest. Public `fsmgen vial run` deliberately remains the separately
qualified portable-Verilator path.

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

The reachability audit selects these outcomes before generator implementation:

| Axis | Gate | Qualification | Limit | Over limit |
| --- | --- | --- | --- | --- |
| selected fixture/unit/domain | `1` accepted | `1` accepted | `1` accepted | scalar selection or bridge cap rejects `2` |
| scenarios | `32` accepted | `512` accepted | `4,096` accepted | scenario cap rejects `4,097` |
| operations in one scenario | `256` accepted | `8,192` accepted | plan-byte cap wins at `65,536` | semantic action cap rejects `65,537` |
| operations total | `1,024` accepted | plan-byte cap wins at `65,536` | plan-byte cap wins at `1,000,000` | total-operation cap rejects `1,000,001` |
| fibers total | `128` accepted | `8,192` accepted | plan-byte cap wins at `65,536` | total-fiber cap rejects `65,537` |
| simultaneously live fibers | `32` accepted | `1,024` accepted | `16,384` accepted | live-fiber cap rejects `16,385` |
| bindings | `2,048` accepted through the sealed event route | bridge event cap wins | VIAL source-byte cap wins | VIAL source-byte cap wins |
| execution types | `512` accepted through plain IAL1 | bridge type cap wins | VIAL source-byte cap wins | VIAL source-byte cap wins |
| source-map records | `8,192` accepted | plan-byte cap wins | plan-byte cap wins | source-map cap rejects `1,000,001` |
| random attempts | `8,192` accepted | `262,144` accepted | `1,000,000` accepted | deterministic exhaustion rejects `1,000,001` |
| serialized plan | exact 1 MiB | exact 4 MiB | exact 16 MiB | first additional complete operation is rejected |

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
