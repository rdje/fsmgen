# 0056 — VIAL scale measurements use pinned evidence and bounded failure

- Date: 2026-08-10
- Type: verification architecture/scalability
- Status: accepted
- Refines: [0055](0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md)
- Evidence owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.1`

## Context

Correct workload topology does not by itself make performance evidence stable.
Wall/CPU time and memory depend on host and tool identity, while incorrect or
partial work can appear faster. Fixed numbers invented before calibration would
be unsupported and flaky; thresholds silently recalibrated after a slow run
would be meaningless.

Scale runs also approach explicit semantic, serialized-byte, trace/result,
timeout, and memory boundaries. The architecture needs one rule for the first
dominant cap, bounded external-tool execution, same-volume data, atomic cleanup,
and promotion without borrowing whole-product or broader-language claims.

The audit found a current-truth discrepancy: the portable-SV Runner and
normative backend contract enforce 8 MiB compile and 64 MiB runtime capture,
while the support snapshot reports 4 MiB for both. Scale automation cannot
choose whichever number is convenient.

## Decision

1. A performance sample exists only after every applicable stage-local
   correctness oracle from decision `0055` passes.
2. Retain fixed 88% host-memory and 4,096 MiB descendant safety guards plus the
   selected stage timeouts. Derive performance budgets from immutable clean
   calibration evidence and enforce them only on an exact pinned host/tool
   profile.
3. Record raw stage measurements and host/tool identity; exclude timing, RSS,
   host paths, timestamps, and run ordinals from workload and semantic identity.
4. Treat the earliest authoritative cap as the result. Host exhaustion,
   external-tool crash, partial publication, or manual cleanup is not graceful
   failure.
5. Keep project-owned work repository-derived and same-volume, and require
   atomic publication plus exact owned cleanup on success and failure.
6. Promote only exact measured profiles with complete raw evidence and
   nonclaims. Architecture scale never implies whole-product `big` /
   `really_big`, multi-unit/domain, mixed-language, native-UVM runtime,
   full-language, synthesis, or general-parity support.
7. Use the Runner/normative 8-MiB/64-MiB capture limits as enforced truth;
   repair the support snapshot under separate leaf `.17.6` before automation
   consumes it.

## Consequences

- Calibration is reproducible without making unmatched hosts flaky or allowing
  a regression to move its own threshold.
- Correctness, FSMGen-owned cost, external-tool cost, resource safety, failure,
  publication, and cleanup remain independently visible.
- Dominant earlier caps and unreachable nominal limits are reported honestly.
- Measurement, cap repair, and stable promotion remain separate implementation
  and rollback owners.

## Selected Contract

The following measurement and bounded-failure contract is normative for
implementation leaves `.17.2` through `.17.5`. Selection itself changes no
code, runtime behavior, support record, or scale claim.

## Measurement Record

Every measured invocation produces
`fsmgen.vial_architecture_scale_measurement.v1` with:

```text
schema / schema_version
workload_identity / workload_specification
git_revision / dirty_state
host_profile / tool_profile
run_class / run_ordinal
stage_measurements[]
correctness_oracles[]
resource_guard
artifacts
outcome / diagnostic / cleanup
explicit_nonclaims
```

Each stage measurement records monotonic wall nanoseconds; user and system CPU
nanoseconds for the controller and descendants; peak summed live process-tree
RSS; peak single-descendant RSS; input and output files/lines/bytes; semantic
object counts; command identity; exit/signal/timeout; and external-tool versus
FSMGen-owned classification. The sampler interval is 250 ms and is recorded.
Short-lived-process undercount remains explicit; unsupported host counters are
null with a reason, never zero.

The host profile records OS/version, architecture, CPU model, logical-core
count, physical memory, filesystem type, and measurement implementation. Tool
profiles record exact executable logical name, reported version/build, provider
identity, arguments, and thread/job count. Persisted paths are repository-
relative. No absolute executable, home, temporary, or cache path is published.

Stage boundaries are `construct`, `parse_validate`, `bridge`, `bind_plan`,
`emit`, `compile_analyze`, `elaborate`, `run`, `trace_validate`,
`result_produce`, `publish`, and `cleanup`. Unsupported stages are `not_run`
with a reason. Aggregate-only timing cannot substitute for stage timing.

## Repetitions And Noise

An always-on gate calibration uses one unmeasured validation run followed by
three measured runs in fresh operation-owned staging. Qualification uses one
validation run followed by five measured runs. Every run reconstructs the
workload and proves deterministic bytes. Filesystem and OS caches are not
claimed cold or controlled; that condition is recorded.

The report retains every sample. Median, minimum, maximum, and median absolute
deviation are derived views, not replacements for raw records. Samples cannot
be discarded merely because they are slow. A sample is excluded only for an
explicit correctness failure, guard trip, external interruption, or recorded
host/tool identity change, and the exclusion remains in the report.

## Safety Ceilings And Timeouts

Every architecture-scale command runs under the repository RAM guard with the
current defaults: stop at 88% host memory or when any descendant reaches 4,096
MiB RSS. The stage sampler additionally reports summed process-tree RSS; it
does not weaken the guard. A guard trip invalidates the sample and requires a
smaller workload or an implementation repair.

Outer safety timeouts are:

| Stage | Outer ceiling |
| --- | ---: |
| construct / parse_validate / bridge | 120 seconds each |
| bind_plan / emit | 300 seconds each |
| compile_analyze | 900 seconds total, retaining any stricter per-source/tool limit |
| elaborate | 60 seconds |
| run | 300 seconds qualification envelope, retaining a stricter backend limit |
| trace_validate / result_produce / publish / cleanup | 120 seconds each |

The effective ceiling is always the smaller of this table and the backend's
qualified contract. Thus portable-SV compile/run remain 120/30 seconds, and
current VHDL analysis/elaboration/run remain 120 seconds per source, 60
seconds, and 30 seconds. Increasing a qualified backend timeout is a separate
contract and qualification change, not a benchmark convenience.

## Calibration And Regression Budgets

Fixed safety ceilings apply immediately. Performance pass/fail budgets are not
invented by this selection. `.17.3` derives a candidate budget from a clean
pinned host/tool calibration, and `.17.5` publishes it only after the complete
correctness and repetition contract passes.

For a promoted gate, the frozen budgets are computed exactly from the accepted
calibration samples:

```text
wall_budget = ceil_to_1_ms(max(2 seconds, 1.50 * maximum_wall))
cpu_budget  = ceil_to_1_ms(max(2 seconds, 1.50 * maximum_cpu))
rss_budget  = ceil_to_16_MiB(max(256 MiB, 1.25 * maximum_tree_RSS))
```

The raw calibration values, formula, resulting integers, host profile, tool
profile, and git revision are immutable qualification evidence. Artifact,
object, record, and byte counts remain exact deterministic oracles with no
percentage tolerance.

A performance regression fails only when the host/tool profile exactly matches
the frozen profile and one hard budget is exceeded after correctness succeeds.
Other hosts run correctness, deterministic-output, safety, and cleanup gates;
they report performance as informational. Recalibration requires an owned task,
an explained host/tool or intentional performance change, old-versus-new
evidence, and explicit budget-version replacement. A slow run never silently
rewrites its own budget.

## Graceful Failure

`limit_v1` and `over_limit_v1` are not ordinary regression workloads until
preflight proves their minimum memory and byte representation stays inside the
safety envelope. Boundary proof proceeds from compact counting checks toward
materialized evidence. The earliest authoritative stage must reject excess
before publishing target artifacts or invoking an external tool when that
stage already knows the limit is exceeded.

Every over-limit result must provide a stable diagnostic family and semantic
path, requested and allowed values where safe, no Perl stack or machine-local
path, no partial final output, and verified deletion of the exact owned staging
tree. Current diagnostic families remain `VIAL_LIMIT_ERROR`,
`HIAL_VIAL_BRIDGE_LIMIT_ERROR`, `VIAL_EXECUTION_LIMIT_ERROR`, and the applicable
backend/tool limit error. `.17.4` must repair missing early checks or ambiguous
diagnostics without changing accepted-profile semantics.

The proof must never use host swapping, OOM termination, signal 9/137, external
tool crash, truncated unsanitized output, or manual artifact deletion as the
expected product behavior.

## Repository Locality And Cleanup

Ephemeral work lives only below:

```text
.artifacts/tmp/vial-scale/<workload-id>/<run-class>/<run-ordinal>/
```

An explicitly published qualification report lives below:

```text
.artifacts/qualification/vial-scale/<contract-version>/<profile-id>/
```

Both are derived from the repository root at runtime and remain on its volume.
No project-owned output, dependency cache, object directory, transcript, or
fixture may default to `/tmp`, `/private/tmp`, a user home, or an external
volume. Qualified external tools/providers may be read from their exact
documented dependency location; project outputs remain local.

Every run inventories its owned root before work, commits final evidence only
after validation, removes ephemeral staging on success and failure, and proves
the exact root absent. It never recursively cleans an unresolved variable,
repository root, shared cache, or ambiguous provider tree.

## Promotion Gate And Nonclaims

`.17.5` may promote a profile only when:

1. workload construction is deterministic and canonical;
2. all stage-local correctness oracles pass;
3. applicable exact qualified tools pass;
4. all required samples and raw measurements exist;
5. safety and regression budgets are frozen with their evidence;
6. boundary/overflow behavior is graceful for every claimed resource;
7. artifact publication and cleanup are atomic and residue-free;
8. support/capability records describe only the measured profile; and
9. the mdBook states the exact host/tool/workload envelope and nonclaims.

Even after architecture-scale promotion, FSMGen does not thereby claim
whole-product `big`/`really_big`, multiple units/domains, mixed-language scale,
native-UVM runtime scale, full-language scale, arbitrary third-party tool
capacity, synthesis scale, or general cross-backend parity.

## Rollback

Before implementation, rollback removes decision `0055`, this contract, and
its documentation/task references and returns `.17.1` to active. Later leaves
must make generator, measurement, cap, gate, evidence, and support rollback
independently scoped. A rollback cannot retain a capacity claim after removing
the exact workload, correctness, tool, resource, and cleanup evidence that
qualified it.
