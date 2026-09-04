# Portable SystemVerilog lifecycle-control mapping for VIAL v2

Date: 2026-09-04
Owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2`
Status: selected and executable-contract-watched; backend implementation unavailable
Decision: `0100`

## Outcome and boundary

This part selects how `lifecycle_control@1` will be lowered from an exact
`fsmgen.vial_execution_ir.v2` plan into the `sv_portable_verilator` backend.
It defines the implementation contract before changing the adapter, emitter,
trace validator, result producer, runner, or public v2 `run` path.

The mapping is static. One generated fixture-level controller stores the
finite state derived from the typed lifecycle records and executes beside the
existing statically emitted scenario scheduler. It is not a target interpreter
and does not expose SystemVerilog scheduling, classes, callbacks, UVM phases,
objections, DPI, VPI, or host-language functions as VIAL semantics.

Selection is not availability. Every v2 backend maturity field remains
`unavailable`; successful v2 `check`, `format`, and `plan` do not imply
emission, compile, runtime, result, parity, or public-run support.

The source and target-neutral meanings remain authoritative in the
[lifecycle-control family contract](lifecycle-control-v2.md). The complete v1
portable backend remains independently authoritative in
[its frozen contract](../VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md).

## Machine-readable selection

The following JSON object is normative. T1809 decodes it and independently
derives the record/operation map from the maintained typed plan.

<!-- portable-lifecycle-contract-json:start -->
```json
{
  "schema": "fsmgen.vial_backend_lifecycle_mapping_contract.v1",
  "schema_version": 1,
  "profile_id": "sv_portable_verilator",
  "execution_schema": "fsmgen.vial_execution_ir.v2",
  "execution_profile": "core_directed_single_clock_execution_v2",
  "family_revision": "lifecycle_control@1",
  "backend_schema": "fsmgen.vial_backend.sv_portable_verilator.v2",
  "source_map_schema": "fsmgen.vial_backend_source_map.v2",
  "runtime_trace_schema": "fsmgen.vial_sv_runtime_trace.v2",
  "trace_projection_schema": "fsmgen.vial_sv_trace_projection.v2",
  "result_manifest_schema": "fsmgen.verification_result_manifest.v2",
  "lifecycle_result_schema": "fsmgen.vial_lifecycle_result.v1",
  "trace_prefix": "FSMGEN_VIAL_TRACE_V2\t",
  "controller_kind": "static_fixture_lifecycle_controller_v1",
  "controller_states": [
    "entered",
    "normal",
    "failing",
    "sealed"
  ],
  "check_seams": [
    "after_initialization",
    "after_inactive_barrier",
    "after_scenario_terminal"
  ],
  "condition_sources": [
    "configured",
    "reset_inactive",
    "dependency_satisfied",
    "service_started",
    "service_ready",
    "service_quiescent",
    "service_stopped",
    "lifecycle_point",
    "scenarios_terminal",
    "transactions_terminal",
    "scoreboards_empty",
    "all"
  ],
  "record_mapping": [
    {
      "record_kind": "dependency",
      "controller_steps": ["evaluate", "commit"],
      "trace_transitions": ["dependency_satisfied"]
    },
    {
      "record_kind": "service",
      "controller_steps": ["start", "ready", "quiescent", "stop"],
      "trace_transitions": ["service_started", "service_ready", "service_quiescent", "service_stopped", "service_failed"]
    },
    {
      "record_kind": "readiness",
      "controller_steps": ["evaluate", "commit"],
      "trace_transitions": ["readiness_reached"]
    },
    {
      "record_kind": "stimulus_start",
      "controller_steps": ["evaluate", "commit"],
      "trace_transitions": ["stimulus_started"]
    },
    {
      "record_kind": "completion",
      "controller_steps": ["evaluate", "commit"],
      "trace_transitions": ["completion_reached"]
    },
    {
      "record_kind": "drain",
      "controller_steps": ["evaluate", "commit"],
      "trace_transitions": ["drain_reached", "drain_incomplete"]
    },
    {
      "record_kind": "shutdown",
      "controller_steps": ["evaluate", "commit"],
      "trace_transitions": ["shutdown_reached"]
    },
    {
      "record_kind": "finalize",
      "controller_steps": ["evaluate", "commit"],
      "trace_transitions": ["finalize_reached"]
    },
    {
      "record_kind": "deadline",
      "controller_steps": ["start", "check", "close"],
      "trace_transitions": ["deadline_started", "deadline_met", "deadline_expired", "deadline_cancelled"]
    },
    {
      "record_kind": "failure",
      "controller_steps": ["latch", "cancel", "cleanup", "seal"],
      "trace_transitions": ["failure_latched", "scenario_admission_closed", "record_cancelled", "cleanup_started", "cleanup_finalized", "cleanup_expired", "lifecycle_sealed"]
    }
  ],
  "lifecycle_trace_payload_keys": [
    "diagnostic_ids",
    "lifecycle_id",
    "logical_time",
    "record_id",
    "state",
    "transition"
  ],
  "result_added_keys": ["lifecycle_results"],
  "maturity": {
    "emission": "unavailable",
    "compile": "unavailable",
    "runtime": "unavailable",
    "result": "unavailable",
    "parity": "unavailable"
  }
}
```
<!-- portable-lifecycle-contract-json:end -->

## Admission and version isolation

The future v2 adapter admits only all of these facts, before rendering bytes:

- the exact v2 execution schema/profile above;
- exactly one `lifecycle_control@1` program for the selected fixture, with the
  existing common family and lifecycle validators accepting every record;
- every lifecycle operation ID matching the machine-readable map;
- one reviewed unit and coordination domain, with both typed lifecycle
  bindings retained for every record;
- the already qualified v1 scenario operation subset and known-value limits;
- no unknown family, family revision, effect, capability, condition kind,
  target mechanism, native extension, or unsatisfied requirement.

V1 and v2 are separate adapter branches selected by exact execution schema,
not permissive key probing. The stable backend profile ID does not authorize
cross-version data. V2 never emits a v1 backend manifest, source map, trace,
trace projection, or result manifest. The unchanged HIAL bridge remains
`fsmgen.hial_vial_bridge_manifest.v1`; command and tool-profile records may
retain their existing schema only because their closed fields carry no VIAL
semantic-family data.

Any failed preflight returns `VIAL_BACKEND_UNSUPPORTED`, the complete sorted
unsatisfied set, no backend manifest, and an empty artifact array. It performs
no provider access, host lifecycle admission, staging, or public publication.

## Static controller state

The emitter partially evaluates the lifecycle topology into fixed declarations
and tasks. Mutable runtime state is limited to:

- controller state `entered`, `normal`, `failing`, or `sealed`;
- one latched bit per dependency and lifecycle point;
- one closed state per service: pending, started, ready, quiescent, stopped,
  failed, or cancelled;
- one active/met/expired/cancelled state plus start/end cycle per deadline;
- one monotone lifecycle-cycle counter and per-seam transition ordinal;
- selected-scenario terminal/cancelled state, transaction-active facts,
  scoreboard queue/mismatch facts, and the stimulus-admission gate; and
- one primary diagnostic, ordered additional diagnostics, cleanup state, and
  cleanup deadline.

All arrays and loops are plan-sized and statically bounded. There is no dynamic
name lookup, queue growth, recursive task, spawned lifecycle process, target
randomization, or alternate semantic clock.

`configured` is true only after exact plan/backend admission and generated
connections are initialized. `reset_inactive` reads the bridge-selected reset
carrier and polarity. Dependency, service, and lifecycle-point conditions read
only controller latches. `scenarios_terminal` means every selected scenario has
a terminal result. `transactions_terminal` means no selected-scenario handle
remains active. `scoreboards_empty` means every selected queue is empty with no
unreported mismatch. `all` evaluates its ordered operands without short-cutting
trace or diagnostic order.

The `fixture_background` service represents only the selected observation,
model, scoreboard, coverage, and result-collection aggregate. Its storage is
initialized before the first seam, so the maintained fixture may commit start
and ready at that seam. It never executes scenario stimulus.

## Check seams, fixed point, and logical time

One compiler-owned controller call occurs:

1. after deterministic initialization and the trace header;
2. after each inactive-edge barrier has committed sampled transaction and
   checking state; and
3. after each scenario publishes its terminal record.

A `(lifecycle_cycle, check)` seam is evaluated at most once. The call scans
eligible records in typed semantic rank then semantic-ID order, commits a
transition immediately, and repeats until no state changes. A later-ranked
record may observe an earlier commit at the same seam. Each committed
transition increments the seam ordinal. It never increments the cycle.

The lifecycle counter starts at zero on entry and advances once per genuine
coordination-domain inactive-edge barrier across the whole selected run. The
existing scenario cycle remains scenario-local, so scenario deadlines and v1
result meanings are unchanged. Lifecycle times use only the lifecycle counter;
scenario times use only their existing run-local counter. They share a domain
identity but are never compared without their owning result scope.

The controller does not run in an `always` block, a second clock process, a
host thread, or `VerilatorLifecycle`. That host component continues to own only
repository-local tool verification, compile/run supervision, evidence capture,
and cleanup.

## Success path and scenario relationship

At lifecycle entry the initial fixed point evaluates configured/reset
dependencies, starts the background service, commits service readiness, reaches
readiness, and opens stimulus only when every typed condition is true. No
scenario emits `scenario_start` before stimulus start.

The scenario scheduler remains byte-for-byte v1-derived behavior inside the
new v2 envelope. It owns drive/sample/react/check operation execution,
scenario-local deadlines, fibers, transactions, checks, models, scoreboards,
coverage, faults, and scenario trace records. The lifecycle controller owns
only admission and the aggregate facts named above.

After every selected scenario is terminal, the same fixed-point rule may reach
completion, service quiescence, drain, shutdown, service stop, and finalization
at one check seam when all conditions already hold. That zero-cycle progression
is intentional; its transition ordinals preserve order. A successful seal
requires every dependency satisfied, every normal point reached, every service
stopped, every deadline met, no failure, and exact source-map coverage.

## Inclusive deadlines and failure cleanup

When a deadline's start milestone commits at lifecycle cycle `C`, the emitted
controller stores `C` and accepts the end milestone through `C + N - 1` for a
declared bound `N`. At every seam, reachable milestones commit first; deadline
close/expiry checks run second. An end reached on the last included cycle is
therefore `met`, while the next seam expires it.

The first scenario failure/timeout, service failure, controller corruption,
or expired lifecycle deadline atomically changes `normal` to `failing` and
latches the primary diagnostic. Later causes are ordered evidence only. The
controller then:

1. closes scenario admission and cooperatively cancels active or not-yet-started
   selected scenarios;
2. cancels open deadlines and unreached normal dependency/point records;
3. requests service stop while retaining real transaction/scoreboard residue;
4. starts the independent failure cleanup deadline; and
5. seals `fail` after bounded cleanup, or `error` if cleanup expires or
   structural trace/result validation fails.

Failure cleanup does not claim the normal completion, drain, shutdown, or
finalize milestones. Their result records remain failed/cancelled as observed;
`failure_result.cleanup_status=finalized` records successful failure cleanup.
Unsettled owned work at cleanup finalization emits
`VIAL_LIFECYCLE_DRAIN_INCOMPLETE`. Cleanup expiry emits
`VIAL_LIFECYCLE_CLEANUP_TIMEOUT`. No transition leaves `failing` for `normal`,
and no failed lifecycle can publish pass.

## Runtime trace and normalized result

The v2 runtime stream uses prefix `FSMGEN_VIAL_TRACE_V2` followed by one tab
and canonical JSON. Existing scenario record meanings are preserved under the
v2 trace schema. One added top-level record kind, `lifecycle`, has null
scenario `run_id` and exactly the payload keys in the normative JSON. Its
`record_id` names the typed lifecycle plan record responsible for the
transition; lifecycle entry may use the lifecycle identity itself. Its raw
logical time carries the lifecycle cycle, check phase, semantic rank, seam
ordinal, and semantic ID.

The validator requires one lifecycle entry and one terminal seal, exact plan
identity, contiguous stream sequence, closed transition vocabulary, monotone
lifecycle time, legal state transitions, exact record identity, deadline
arithmetic, complete selected-scenario terminal accounting, and footer counts.
It returns `fsmgen.vial_sv_trace_projection.v2`; malformed input returns no
partial records or projection.

The v2 result producer first reconstructs one
`fsmgen.vial_lifecycle_result.v1` from the validated lifecycle stream and calls
the existing target-neutral lifecycle validator with the exact plan records.
It then creates `fsmgen.verification_result_manifest.v2`, preserving all v1
field meanings and adding exactly `lifecycle_results`. Its aggregate status is
the worst closed scenario/lifecycle status; parity eligibility requires pass
for both. The v2 parity projection includes lifecycle results. Target time,
simulator regions, process IDs, host timing, and tool chatter remain backend
evidence and never enter lifecycle results.

## Source maps and artifact transaction

The v2 backend source map retains the v1 entry fields under its distinct
schema. Every lifecycle record must map, as applicable, its fixed storage,
condition evaluation, transition commit, trace emission, deadline/failure
logic, and final result path to:

- the exact lifecycle semantic and plan IDs;
- its cumulative `fsmgen.vial_source_map.v2` semantic, bridge, execution, plan,
  and authored source paths; and
- the generated relative file, symbol, and inclusive line range.

The backend map does not replace the cumulative family map. Result production
copies every planned family map exactly, adds one result path, reseals its
content identity, and requires exact one-for-one lifecycle record coverage.

The v2 backend uses the existing public artifact layout and atomic transaction
rules, but all content-bearing lifecycle artifacts identify their v2 schemas.
Emission builds and validates a complete in-memory graph. Runtime uses only an
operation-owned repository-local staging root. Publication occurs only after
emission, compile, run, trace, result, complete-tree, and cleanup validation.
Failure removes only the proven-owned staging root and returns no partial
public tree or false success.

## Compatibility, maturity, and rollback

T1809 freezes the canonical v1 emitted graph and synthetic normalized-result
bytes. The implementation children must keep those digests exact and run the
existing complete v1 emitter/trace/result/runtime gates. A v2 change may add a
parallel versioned branch; it may not make v1 code infer, ignore, or drop
lifecycle fields.

At this selection frontier, the common adapter still accepts only v1, every
`lifecycle_control@1` backend maturity value is unavailable, the emitter and
runner reject v2 before allocation, the v1 result producer cannot label v2 as
v1, and public v2 `run` remains unavailable. The standalone private v1 trace
validator does not yet check the ExecutionIR envelope and therefore accepts a
canonical v1-shaped stream against a lifecycle v2 plan. T1809 characterizes
that exact gap, and repair child `.19.2.3.1.2.1` must close it before emitter
work begins. No public v2 route can currently reach the defective seam or
publish a false result.

This contract does not claim emitted v2 source, Verilator compilation,
execution, trace production, result production, parity, public run, scale,
four-state observability, UVM, VHDL, mixed-language, provider, support, or new
HIAL behavior. Rollback removes this part, decision `0100`, its watcher, and
their reader/index links; it leaves v1 and the target-neutral lifecycle
compiler untouched.
