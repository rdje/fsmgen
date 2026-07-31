# VIAL Portable SystemVerilog/Verilator Backend Version-1 Contract

Date: 2026-07-31
Owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.9`
Status: selected; implementation remains owned by proposed `.10`
Decision: `0043`

## Outcome

`sv_portable_verilator` is VIAL's first selected executable backend profile. It
maps the shipped bounded `core_directed_single_clock_execution_v1` plan to
plain, readable, source-mapped SystemVerilog with no UVM dependency, executes
it under one exact Verilator profile, and produces the already-selected
`fsmgen.verification_result_manifest.v1` result.

The selection changes no product behavior. It freezes the contract that `.10`
must implement and `.11` must use for runtime parity. VIAL authors continue to
write verification intent; they do not write or need to understand simulator
regions, event controls, tasks, hierarchy, `$display`, build flags, or result
serialization.

The governing boundary is:

```text
VIAL source + reviewed HIAL source
  -> private SemanticIR + bridge + immutable ExecutionIR
  -> partial evaluation for sv_portable_verilator
  -> plain SystemVerilog DUT/runtime/fixture artifacts
  -> exact Verilator compile + executable + run gates
  -> validated private runtime trace
  -> normalized public result manifest
```

The backend consumes only a successfully bound `FSM::VIAL::ExecutionIR` and
the reviewed HIAL artifact set selected by the public tooling contract. It may
not independently reinterpret SemanticIR, bridge facts, random decisions, or
logical scheduling.

## Profile Identity And Qualification Boundary

The stable profile ID is `sv_portable_verilator`; its contract schema is
`fsmgen.vial_backend.sv_portable_verilator.v1`. The first reference
qualification records exactly:

```text
tool_name: verilator
tool_version: 5.046
tool_version_output: Verilator 5.046 2026-02-28 rev vUNKNOWN-built20260228
timing: enabled
assertions: enabled
build_jobs: 1
runtime_threads: 1
x_initial: 0
x_assign: 0
default_timescale: 1ns/1ps
target_language: SystemVerilog
methodology: plain_sv_no_uvm
```

The observed external build tools are Apple clang 21.0.0 and GNU Make 3.81.
They are qualification evidence, not VIAL semantics or portable capability
claims. Tool executables and their installed resources are explicit read-only
operating-system/toolchain dependencies. Resolved absolute paths are never
persisted; project sources, objects, logs, traces, and results remain under the
repository-derived artifact or staging roots.

Another Verilator version is `unqualified`, not “close enough”. It may become
qualified only after the full focused compile/runtime/result gate is rerun and
its exact version/capability evidence is recorded. A successful source parse or
`--lint-only` invocation is not qualification.

The backend advertises only exercised constructs needed by the bounded plan:

- modules, packages, packed `logic` vectors, fixed arrays, records represented
  as fixed fields, functions, automatic tasks, loops with static bounds, and
  deterministic procedural assignments;
- one generated clock, active/inactive edge controls, supported delays through
  `--timing`, `$display`, `$finish`, and guarded `$fatal` for backend-internal
  corruption only;
- generated assertions in the HIAL DUT through `--assert`; and
- compiler-generated hierarchy access for an explicitly declared bridge probe.

This list is exercised support, not a SystemVerilog-language inventory.

## Backend Negotiation

Negotiation occurs before any target artifact is emitted. The backend requires:

1. ExecutionIR schema `fsmgen.vial_execution_ir.v1`, execution profile
   `core_directed_single_clock_execution_v1`, one unit, one domain, and no
   native extension;
2. every execution-profile capability already classified as satisfied;
3. every backend requirement recognized and satisfied by this exact profile;
4. a positive finite scalar width representable by generated packed vectors;
5. only the closed version-1 actions, properties, models, scoreboards,
   coverage, and substitution faults listed below;
6. all plan-time random decisions already resolved and unchanged;
7. no authored value or outcome that requires X/Z identity; and
8. every verification probe resolved through one declared backend adapter.

The first AHB plan's
`hial_vial.bridge_probe.equivalent_adapter_required` requirement is satisfied
only by the exact generated adapter for `probe/reg_data_q`. Unknown
requirements, native-only requirements, missing adapters, native extensions,
multi-domain plans, or unsupported value semantics produce
`VIAL_BACKEND_UNSUPPORTED` before source generation.

Negotiation returns an exact ledger with `required`, `satisfied`,
`unsatisfied`, `native_only`, and `limitations` arrays. It cannot relabel or
drop an ExecutionIR requirement to make the profile appear supported.

## Lowering Strategy

The backend uses **static partial evaluation**, not a general-purpose runtime
interpreter. Stable declarations and operation topology become named
SystemVerilog constants, functions, tasks, fixed arrays, and state machines.
Only values and control state that can change during a run remain runtime
state.

This strategy is selected because it:

- keeps emitted artifacts readable beside the plan and source map;
- lets Verilator optimize fixed topology and widths;
- avoids dynamic reflection, target randomization, classes, DPI, VPI, and host
  callbacks;
- gives every generated block a stable plan operation or semantic identity;
  and
- prevents target execution order from replacing the plan's exact ranks.

The backend must share repeated serialization, normalized-value, trace, and
diagnostic helpers through one small generated runtime package. It must not
duplicate the complete helper body per scenario or emit one opaque monolithic
statement stream. Scenario/fiber logic stays grouped by stable authored
identity, with concise comments naming VIAL semantic IDs and logical phases.

## Artifact Graph

Within the public content-addressed output root selected by decision `0039`, a
successful run materializes these backend artifacts:

```text
backends/sv_portable_verilator/
  backend-manifest.json
  backend-source-map.json
  commands/compile-command.json
  commands/run-command.json
  evidence/tool-profile.json
  evidence/compile-transcript.txt
  evidence/run-transcript.txt
  evidence/runtime-trace.jsonl
  src/dut/<unit-slug>.sv
  src/fsmgen_vial_runtime_pkg.sv
  src/<fixture-slug>_tb.sv
results/<run-id>/verification-result-manifest.json
```

Names are deterministic slug projections with collision-resistant suffixes
where required. Every artifact is declared and hashed before the atomic final
tree is committed. Verilator object/C++ files and the executable live only in
the exact repository-local staging tree:

```text
.artifacts/tmp/vial/<operation-id>/work/sv_portable_verilator/obj/
```

They are deleted after the final manifest graph has validated. They are never
silently redirected to `/tmp`, a home cache, or another volume. On failure the
same exact owned staging root is removed; unrelated cache or artifact roots are
not touched.

Command records contain the logical executable name, ordered arguments,
repository-relative working directory and inputs, expected outputs, and a
command digest. They never contain a resolved host executable path. Persisted
transcripts are normalized to repository-relative paths and stable newlines;
raw tool output exists only in staging long enough to diagnose and sanitize.

## Generated Backend Manifest

`backend-manifest.json` has schema
`fsmgen.vial_backend.sv_portable_verilator.v1` and exactly:

```text
schema
schema_version
backend_profile
plan_id
fixture_id
generated_top
execution_profile
tool_profile
capability_evidence
limitations
artifacts
commands
source_map
result
cleanup
diagnostics
```

`tool_profile` records the exact factual executed identity above. `artifacts`,
`commands`, `source_map`, and `result` are identity/digest references into the
public artifact graph. `cleanup` records only repository-relative staging
identity and completed/removed state. A successful manifest has empty
diagnostics. An unsupported pre-emission outcome is returned through public
tool/result envelopes and does not create this persisted backend manifest.

## Clock And Logical-Phase Mapping

One generated fixture module owns the clock and one generated scheduler process
owns all VIAL runtime transitions. No scenario or fiber creates an independent
clock process. For a domain whose DUT active edge is `posedge`, the schedule is:

```text
inactive edge N:
  capture sample for logical cycle N-1
  execute react(N-1), check(N-1), completion/timeout
  apply drive(N)
active edge N:
  DUT consumes drive(N); DUT sequential state settles
inactive edge N+1:
  capture sample(N)
  ...
```

For an active `negedge`, the inactive barrier is `posedge`. Scenario cycle zero
drive occurs at the first initialized inactive barrier. The scheduler begins
with deterministic safe driver values and reset state, so no pre-cycle sample
enters the result.

The single process performs sample, react, check, then next drive as ordered
procedural calls at the inactive barrier. The half-cycle between drive and the
next active edge, and between that active edge and sampling, prevents races with
DUT active-edge sequential updates. The generated source does not rely on
program blocks, clocking-block skew, `#0`, nondeterministic same-edge wake order,
or host threads.

Within each logical phase the runtime follows the ExecutionIR tuple
`(domain_rank, static_operation_rank, local_emission_index, semantic_id)` and
records its selected ordinal. Simulator timestamps and delta/event-region
positions are never written into portable result records.

The generated clock uses an explicit `timeunit 1ns`, `timeprecision 1ps`, and
one-unit half-period. These physical values are backend mechanics only; VIAL
timeouts and results remain logical cycles. The command supplies
`--timescale 1ns/1ps` as the default for source without a timescale and never
uses `--timescale-override` to rewrite a DUT's authored timing.

Reset follows the ExecutionIR interval exactly: assert before cycle-zero drive,
hold through exactly the selected active-edge samples, deassert during the next
drive, and admit no following DUT-affecting action before the next drive phase.

## Values, Types, And Representation Relations

ExecutionIR remains the semantic type authority. The backend emits fixed-width
packed vectors and fixed field groups; it applies only the recorded relation:

- `bit_domain_identity_v1` copies the bit pattern at drive/sample boundaries;
- `known_value_injection_v1` drives the two-state value with every carrier bit
  known and no Z bit; and
- `enum_encoding_injection_v1` drives the exact recorded enum encoding.

No SystemVerilog cast, truncation, extension, signedness reinterpretation,
implicit enum conversion, or inverse four-state-to-two-state conversion may
replace a proof record.

The Verilator profile is deliberately known-value bounded. Every literal,
decision, expected value, model-state value, scoreboard value, coverage
boundary/value, and fault substitution used by emitted behavior must have all
bits known and no Z bits. `same` is supported only when its authored expected
operands are fully known; `value_eq` retains its existing fully-known rule.
An X/Z literal, unknown-sensitive bin/property, or requested four-state identity
check fails negotiation.

Sample records retain the normalized scalar shape. Under this profile they
contain all-one known masks and zero Z masks because the runtime cannot observe
complete four-state state. This is a factual profile limit, not proof that the
DUT could never produce X/Z. The backend manifest therefore reports
`four_state_observation: false` and
`known_value_trace_only: true`. A full four-state backend result can disagree;
the portable parity machinery must report the mismatch rather than defer to the
Verilator pass.

Widths retain the existing 65,536-bit semantic safety cap. This selection makes
no compile-time, memory, or large-width qualification claim; `.17` owns measured
scale. Implementation must fail before emission if its concrete renderer cannot
materialize a legal width within the selected safety and result-size caps.

## Drivers, Samples, Transactions, And Probe Adapters

One fixed driver slot exists per driven logical endpoint. The generated
scheduler is the only writer. Two live same-phase writes remain the
ExecutionIR conflict error and cannot be resolved by SystemVerilog source order.
Slots persist until changed or deterministic finalization applies the selected
safe value.

One immutable sample snapshot is captured per logical cycle at the inactive
barrier. Event predicates, models, coverage, and checks read that snapshot;
they do not reread live DUT signals at different simulator regions.

The generated transaction adapter owns protocol waveforms but accepts only the
already-normalized immutable effective field record. It reports the bridge's
requested/accepted/captured/held/completed/error event family with stable handle
and event IDs. It cannot rerandomize fields or invent correlation.

A bridge-declared verification probe is mapped through a generated adapter
record with:

```text
adapter_id
probe_id
bridge_binding_id
kind: generated_hierarchical_read_alias_v1
generated_symbol
width
relation_id
source_map_id
capability_id
```

Only bridge-published probe facts may create such records. The first AHB
adapter maps `probe/reg_data_q` to the generated DUT instance's declared
storage binding, as the handwritten oracle already exercises. VIAL source
cannot spell, derive, concatenate, or traverse the hierarchy. Another backend
must provide its own equivalent adapter or remain unsupported.

## Actions, Fibers, Checks, And Stateful Families

The first backend implements exactly the execution-v1 meanings of:

- `reset`, `drive`, `start`, `await`, `parallel`, literal `repeat`, `expect`,
  `scoreboard_expect`, `scoreboard_check`, and substitution `inject`;
- root/nested fibers, `all`/`any` joins, deterministic tie selection,
  cancellation, failure propagation, and finalization;
- Boolean, overlapping implication, `next`, and bounded `within` evaluators;
- event counters and scalar-state deterministic models;
- bounded `in_order` and `keyed` scoreboards;
- explicit coverpoints/bins/materialized crosses; and
- one-drive-interval transaction-field substitution faults.

Each family uses fixed plan-derived storage. There is no dynamic name lookup,
class factory, unbounded queue, backend callback, simulator randomization,
recursive task, fork scheduling authority, DPI/VPI, or host-language escape.

Runtime limit failure, expectation failure, mismatch, illegal bin, timeout, or
internal error follows the ExecutionIR's deterministic cancellation and
finalization order and emits normalized records. Expected VIAL failures do not
use `$fatal`; `$fatal` is reserved for generated-runtime corruption that makes
the trace untrustworthy.

## Private Runtime Trace

The simulator emits machine records on stdout as:

```text
FSMGEN_VIAL_TRACE_V1<TAB><canonical-json-object>
```

The host strips only the exact prefix and writes the objects, one per line, to
`evidence/runtime-trace.jsonl`. Other simulator output remains sanitized tool
evidence and cannot become a semantic result by pattern guessing.

The private trace schema is `fsmgen.vial_sv_runtime_trace.v1`. It begins with
one `header`, contains the normalized stream records selected by the result
contract for all selected scenarios in authored order, and ends with exactly
one `footer`. Every object contains `schema`, `schema_version`, `record_kind`,
`plan_id`, `run_id`, `sequence`, and `payload`. Sequence starts at zero and is
contiguous across the file. Header/footer `run_id` is null; each scenario-owned
record uses the exact `run/<plan-id>/<scenario-id>` identity. Header payload
identifies the fixture/profile, ordered scenario/run IDs, and exact decision
digest. Footer payload contains final status, scenario completion summaries,
per-family counts, and a clean termination marker.

Static strings are JSON-escaped at generation time; runtime values are emitted
only through closed hexadecimal/integer/Boolean helpers. Newlines, tabs,
non-canonical numbers, duplicate keys, unknown record kinds, wrong IDs,
out-of-order sequence/logical time, missing header/footer, count mismatch,
records after footer, or an unsuccessful simulator exit make the result
`error`. A plausible `$display` line cannot forge a trace because the complete
closed stream and plan/run identities must validate.

The host result producer validates and projects; it does not execute VIAL
meaning. Models, scoreboards, coverage, faults, scheduling, decisions, and
scenario status must already be present and mutually consistent in the trace.
The producer adds factual backend/tool/artifact evidence, canonical IDs/hashes,
and the parity projection defined by the execution contract.

## Source Mapping And Generated-Code Quality

`backend-source-map.json` has schema
`fsmgen.vial_backend_source_map.v1` and exactly `schema`, `schema_version`,
`plan_id`, `artifacts`, and `entries`. Each artifact identity includes its
relative path and digest. Each entry contains:

```text
source_map_id
generated_relpath
generated_start_line
generated_end_line
generated_symbol
role
plan_paths[]
semantic_paths[]
bridge_fact_paths[]
source_locations[]
```

Entries are sorted by artifact then generated span and stable ID. Every
generated scenario, fiber, operation, driver/sample binding, transaction/event
adapter, model rule, scoreboard operation, coverage point/bin/cross, fault,
diagnostic site, and probe adapter has at least one entry. Boilerplate maps to
the backend contract rather than inventing an authored VIAL location.

Generated source uses deterministic LF text, two-space indentation, stable
declaration order, meaningful plan-derived symbols, concise identity comments,
and one final newline. It must contain no absolute paths, host addresses,
nondeterministic timestamps, hash insertion order, UVM vocabulary, raw private
object dumps, or unexplained numeric action tags. Equivalent input and tool
contract produce byte-identical target source and source maps.

## Exact Verilator Command And Gates

The reference compile command is the ordered logical argv:

```text
verilator
--binary
--timing
--assert
-j 1
--threads 1
--x-initial 0
--x-assign 0
--timescale 1ns/1ps
--top-module <generated-top>
--Mdir <repository-local-staging-objdir>
<ordered-dut-and-backend-sources>
```

`--timescale-override`, `--no-timing`, `--no-assert`, blanket warning
suppression, UVM flags, DPI/VPI linkage, network discovery, and off-volume
object/cache roots are forbidden. The current AHB evidence compiles with this
profile without `-Wno-fatal` and runs with assertions enabled.

The gates are independent and ordered:

1. **negotiate** — exact schemas/profile/capabilities/known-value/adapters;
2. **emit** — deterministic sources, manifests, hashes, and complete source map;
3. **compile/elaborate/build** — exact Verilator version and argv, zero exit,
   expected executable only, no error diagnostics;
4. **run** — exact repository-local executable, zero exit, bounded timeout and
   output bytes, one complete trace;
5. **result** — closed trace validation and exact normalized result schema;
6. **semantic outcome** — every selected scenario has the expected status and
   all resource/stream counts are internally consistent.

Failure at one gate cannot be relabeled as a later pass. Compile success is not
runtime success; a clean simulator exit without a valid footer is not result
success; a result pass is not UVM/full-LRM/four-state/parity/scale support.

## Capabilities And Honest Non-Claims

Implementation `.10` may advertise these only after their exact gates pass:

```text
vial.backend.sv_portable_verilator.v1
vial.backend.sv_portable_verilator.known_value_runtime_v1
vial.backend.sv_portable_verilator.inactive_edge_scheduler_v1
vial.backend.sv_portable_verilator.declared_probe_adapter_v1
vial.backend.sv_portable_verilator.runtime_trace_v1
vial.result_manifest.v1
```

It may then satisfy `hial_vial.bridge_probe.equivalent_adapter_required` only
for exact adapter records it emitted and executed. Public capability and
support accounting must distinguish emission, compile, runtime, result, and
later parity evidence.

The profile does **not** claim:

- complete four-state/X/Z observation or unknown-sensitive checks;
- complete SystemVerilog LRM conformance, event-region equivalence outside the
  selected scheduler, SVA breadth beyond generated DUT assertions, coverage
  database compatibility, DPI, VPI, classes, constrained randomization, or UVM;
- native VIAL semantic families, UVM events/callbacks, factories, phases,
  objections, sequences, TLM, config DB, RAL, or methodology components;
- VHDL, mixed-language, formal, analog/real-time, performance, large-fixture,
  or cross-backend parity qualification; or
- compatibility of any unexecuted Verilator/toolchain version.

Decision `0034` remains controlling: these are limits of one first backend,
not limits of VIAL.

## Bounded Runtime And Artifact Limits

The backend preserves every smaller SemanticIR/bridge/ExecutionIR limit and
adds these pre-materialization caps:

| Resource | Limit |
| --- | ---: |
| generated SystemVerilog artifacts | 3 plus one DUT artifact per bound unit |
| generated SystemVerilog bytes total | 16,777,216 |
| source-map entries | 1,000,000 |
| persisted normalized transcript bytes | 16,777,216 |
| private runtime-trace records / bytes | 8,000,002 / 67,108,864 |
| compile transcript bytes | 8,388,608 |
| run transcript bytes | 67,108,864 |
| one scenario logical cycles | authored positive 32-bit timeout |
| Verilator build jobs / runtime threads | 1 / 1 |

The two extra trace records are header and footer above the ExecutionIR's
8,000,000 total semantic-stream cap. Exceeding any cap is an explicit backend
or result error; output is never truncated into a pass. These are safety caps,
not `.17` scale qualification.

## First Implementation And Runtime Oracles

Implementation `.10` owns the backend, public `fsmgen vial` implementation
needed to reach it, exact result producer, and focused `t/1553` successor chosen
at activation. Its first compile/run fixture is the already checked
`vial/ahb_subordinate_base_output_arbitration.vial` plan bound through
`ppif/ahb_lite_subordinate.ppif`.

The implementation gate must prove:

- exact negotiation and rejection of wrong schema/profile/tool requirement,
  native extension, X/Z-dependent semantics, missing/forged probe adapters,
  unsupported relations, multiple domains, unknown capabilities, and limits;
- deterministic readable target artifacts, byte-identical rerender, complete
  source maps, no absolute/off-volume path, and defensive public projections;
- inactive-edge scheduling with drive-before-active-edge and stable
  post-active-edge snapshot, exact reset interval, logical ordinal order,
  timeout boundary, fiber ties/cancellation, and no same-edge races;
- exact normalized values and all three directional drive/sample relation
  mappings without target casts or rerandomization;
- action/property/model/scoreboard/coverage/fault semantics and fixed resource
  accounting against the 21-operation/four-fiber checked plan;
- generated `probe/reg_data_q` adapter satisfaction without authored raw
  hierarchy;
- exact Verilator 5.046 command, assertions enabled, no blanket warning
  suppression, local object root, zero-exit compile/run, closed trace, and
  normalized result validation;
- success and unsupported-size scenarios with stable decisions, events,
  transactions, expectations, model/scoreboard/coverage/fault/fiber outcomes;
- malformed/truncated/forged/out-of-order/over-limit trace and nonzero tool
  exits fail atomically with sanitized diagnostics; and
- existing VIAL source/bridge/execution behavior, HIAL SV/VHDL output, inert
  UVM/VHDL verification targets, legacy manifest v1, and every non-claim remain
  unchanged.

`.10` proves one backend result. `.11` alone compares the generated result with
the handwritten AHB oracle and implements/claims portable runtime parity.

The local selection probe generated the existing AHB DUT and compiled the
handwritten 178-line harness under the exact command options above. Verilator
5.046 built three modules with assertions and timing enabled, then reported:

```text
BASE_ASSERT_SUCCESS accepts=1 captures=1 holds=2 completions=1 ready_low=15 storage=cafebabe
BASE_ASSERT_ERROR accepts=1 captures=1 holds=2 completions=1 error_cycles=2 storage=00000000
```

The exact repository-local probe tree was removed after measurement. This is
substrate evidence for selection, not generated-VIAL backend evidence.

## Implementation Ownership, Validation, And Rollback

This selection creates no parser widening, public command/API, artifact,
backend module, runtime package, Verilator invocation in product code, result
producer, capability/support entry, or runtime/parity claim. Proposed `.10`
must be separately activated from a clean repository before implementation.

Selection signoff requires current source/bridge/execution tests, the existing
AHB Verilator oracle, task/roadmap/audit/decision/book/fact continuity, relative
paths, every mdBook chapter and repository-local build, Knowledge Map, bounded
Memory, diff hygiene, staged docs-only acceptance, all doctrines, and exact
cleanup.

Selection rollback removes decision `0043` and this contract and returns `.9`
to active. It preserves all shipped VIAL/HIAL implementation and public
non-claims. Future implementation rollback removes only the exact `.10`
backend/public-tool/result implementation and its owned artifacts/capability
entries, retaining this selected contract, the private VIAL stages, and every
legacy verification-output surface.
