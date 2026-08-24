# Decision 0083: Portable SystemVerilog runtime scale uses authored cycle sampling and one shared staged lifecycle

- **Status:** Accepted
- **Date:** 2026-08-24
- **Owner:** `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1`
- **Refines:** [0055](0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md), [0056](0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md), [0043](0043-vial-portable-systemverilog-is-a-deterministic-known-value-profile.md)

## Context

The provider-free runtime-stream constructor records 10,000- and
100,000-record candidates, but it deliberately materializes neither runtime
activity nor a trace. The public portable-SystemVerilog Runner executes the
checked AHB plan correctly, yet it owns tool discovery, preparation, compile,
run, trace validation, result production, artifact assembly, and cleanup as
one private transaction. The common measurement controller needs those costs
as distinct process-isolated stages. Copying the Runner would create a second
execution semantics; patching emitted SystemVerilog or padding a trace would
make the measured workload false.

The corrected portable backend was probed through the ordinary public
parse/bridge/plan/emission/Runner path. The checked two-scenario reference
produced 274 validated records. During an authored reset action, every
additional clock cycle produces four genuine endpoint/probe sample records,
and scenario finalization produces one corresponding coverage record. A final
passing response expectation after the existing scoreboard check adds one
more genuine record without introducing a phase barrier. For reset count `N`,
the selected schedule therefore has:

```text
records(N) = 274 + 5 * (N - 3) + 1 = 5N + 260
```

The ordinary qualified run proved `N=1,948` reaches exactly 10,000 records.
The former 100,000-record candidate at `N=19,948` exceeded the Runner's
67,108,864-byte output cap before publication. This is a genuine earlier cap,
not a reason to weaken the cap or truncate evidence.

The public VIAL transaction also caps the complete virtual artifact graph at
67,108,864 bytes. Exact selection probes produced these complete-graph
outcomes:

| Records | Complete graph | Outcome |
| ---: | ---: | --- |
| 10,000 | 32,096,420 bytes | accepted gate candidate |
| 15,000 | 47,502,039 bytes | accepted qualification candidate |
| 20,000 | 62,914,039 bytes | accepted but insufficient qualification headroom |
| 25,000 | above the 67,108,864-byte cap | atomically rejected |
| 100,000 | runtime output exceeds 67,108,864 bytes | atomically rejected before publication |

The exact probe bytes are revision-local selection evidence, not promoted
capacity. The implementation must regenerate its final tracked fixture and
artifact graph rather than copy these numbers blindly.

## Decision

### Authored runtime-stream fixtures

Portable runtime scale uses checked-in, reviewable VIAL qualification sources,
not runtime source rewriting. The implementation owns one gate source and one
qualification source under `vial/qualification/`. Each keeps the checked AHB
package, fixture, two scenarios, real transaction, model, scoreboard,
coverage, fault, random decision, and final semantic outcomes. The only
selected scale changes are:

1. the success scenario's authored reset hold;
2. its matching timeout/window envelope; and
3. one final passing `scale_response_zero` expectation after the scoreboard
   check.

The gate source uses `N=1,948` and must produce exactly 10,000 records. The
portable qualification source uses `N=2,948` and must produce exactly 15,000
records. A structural equivalence oracle compares both sources with the
checked reference through SemanticIR and ExecutionIR, permitting only those
declared differences. It also proves the reset count, selected scenarios,
operation/source-map identities, generated reset loop, expected record-family
counts, and final expectation before any tool starts.

The 15,000-record level replaces the unrepresentable 100,000-record candidate
for `sv_portable_verilator` only. It is the largest 5,000-record selection step
whose complete public artifact graph stays at or below three quarters of the
67,108,864-byte hard cap. The selection probe leaves 19,606,825 bytes of hard-
cap headroom; 20,000 leaves only 4,194,825 bytes and is rejected as a
qualification candidate even though that exact probe still fit. The final
tracked source must independently satisfy the same three-quarter rule.

This headroom is a qualification-candidate admission rule, not a new public
artifact limit, performance budget, or capacity claim. Other runtime backends
retain their own candidate selection until their exact artifact graphs are
audited.

Every repeated cycle remains linked through one evidence chain:

```text
authored VIAL reset count
  -> SemanticIR action
  -> ExecutionIR reset operation and source map
  -> emitted bounded reset loop
  -> real sample and coverage trace records
  -> TraceValidator projection
  -> ResultProducer streams and metrics
  -> trace/result/backend-manifest identities
```

The reference level remains an executable correctness-only validation of the
unchanged checked source. Gate and portable qualification levels are eligible
for one validation followed by three and five measured runs respectively.
The nominal record `limit_v1` and `over_limit_v1` levels are structural
specifications only: their minimum truthful representation is dominated by
earlier byte envelopes, so they must reject during preflight without invoking
Verilator. Neither level claims a reached record boundary. Exact byte-boundary
qualification remains owned by the later cap-repair lane.

### One caller-sealed lifecycle

`FSM::VIAL::Backend::VerilatorLifecycle` is the selected private authority for
both the public Runner and scale measurement. It admits only canonical
ExecutionIR plus a successful portable emission and exposes no public API. Its
closed forward-only states are:

```text
admitted
  -> prepared
  -> tool_verified
  -> compiled
  -> ran
  -> trace_validated
  -> result_produced
  -> assembled
  -> cleaned
```

Failure can occur from any nonterminal state and is followed only by exact
cleanup. A transition cannot be skipped, replayed, reordered, or supplied by a
caller. Each process reconstructs the canonical source-to-emission authority,
derives the lifecycle identity, reloads the predecessor, and independently
validates the complete predecessor chain before proceeding.

Lifecycle state is closed canonical JSON in ordinal, content-addressed files.
Every state names its schema/version, lifecycle and operation identities,
state/ordinal, predecessor digest, plan/input/emission/tool/command seals,
content-addressed object references, and the only legal successor. Large
generated sources, the compiled executable, bounded raw output, normalized
trace, and result content live as digest/byte/kind-checked objects below the
same exact owned root; they never cross the controller's bounded JSON pipe.
Timing, RSS, host paths, run ordinals, and timestamps are evidence metadata and
do not enter semantic or workload identity.

The public Runner retains its existing repository-relative workspace and must
return byte-equal successful artifacts. Measurement uses a separately sealed
storage context nested below the common controller's exact
`.artifacts/tmp/vial-scale/<workload>/<run-class>/<run-ordinal>/` root. Storage
context may change exact staging paths and command digests, so every run keeps
the actual command plus a stable workspace-normalized command identity.
Flags, tool, inputs, stage semantics, trace validation, result production, and
final public evidence are shared. Storage policy is not a second executor.

Portable Verilator maps lifecycle work to the common stage vocabulary as
follows:

| Measurement stage | Shared lifecycle work |
| --- | --- |
| `emit` | canonical emission and lifecycle admission |
| `compile_analyze` | prepare, exact tool verification, and `verilator --binary` |
| `elaborate` | `not_run`; elaboration is integrated into `--binary` |
| `run` | execute the exact compiled binary and retain bounded raw output |
| `trace_validate` | extract framing, validate, and retain normalized trace/projection |
| `result_produce` | independently revalidate the predecessor and produce the normalized result |
| `publish` | assemble the same final artifact graph and compact measurement evidence |
| `cleanup` | remove and census the exact lifecycle and controller roots |

The lifecycle reuses the current 10-second version query, 120-second compile
deadline, 30-second run deadline, 8,388,608-byte compile capture, and
67,108,864-byte run capture. The measurement controller retains its stricter-
of outer policy. No observation in this selection authorizes retry, timeout
widening, or a changed qualified tool.

Implementation clarification (2026-08-24): an isolated common-controller
worker reconstructs the canonical route and emission before it enters the
shared lifecycle. Its 900-second compile-worker and 300-second run-worker
envelopes cover that complete worker transaction, including reconstruction,
process startup, lifecycle work, evidence projection, and cleanup. They are
containment/failure ceilings, not tool allowances. Inside that worker the
shared lifecycle remains the sole tool supervisor and still applies the exact
10/120/30-second version/compile/run deadlines and existing capture ceilings.
Applying the 30-second tool wall to route reconstruction plus execution would
silently shorten the qualified runtime allowance, let unrelated reconstruction
load race the cleanup/evidence handoff, and misclassify a controller kill as a
Verilator timeout. Accepted records therefore prove both layers independently:
the controller envelope and the unchanged lifecycle capture limit.

Measurement also keeps the controller pipe bounded. At `assembled`, the
lifecycle persists a content-addressed descriptor containing the result-
payload digest, artifact count and identity, and result-object path instead of
copying the 30--47 MiB public graph into state JSON. A fresh public resume
reconstructs and verifies the complete assembly from the sealed predecessor;
an ordinary same-process Runner uses the already validated in-memory assembly.
The measurement finalizer writes the complete graph exactly once beneath the
controller-owned publish output and returns only compact artifact identities,
actual commands, normalized command digests, and bounded transcripts. This is
an internal storage/projection refinement: the Runner's public result and
complete artifact graph remain unchanged.

Process supervision must establish containment before `exec`, use close-on-
exec control pipes, distinguish spawn/exec handoff from generated-main time,
record monotonic stage-local evidence, and terminate/reap the complete owned
process tree with TERM then KILL escalation. Under a measurement worker the
tool remains in the worker's outer containment domain; under the public Runner
the lifecycle owns the tool process group. Either mode runs the same command
and state transition. Timeout, signal, capture overflow, malformed output,
tool drift, collision, symlink, mutation, partial state, and consumer failure
all publish no final graph and remove only the exact proven-owned root.

## Rationale

Long reset sampling stresses the selected runtime-stream axis while keeping
source and operation topology small. Every record is caused by authored VIAL,
an actual clock edge, and a real observed endpoint or coverage update. The
base functional transaction and all semantic oracles still run afterward.
This is more truthful than repeating source operations merely to enlarge
generated HDL, and much safer than manufacturing trace text.

The full-graph headroom rule recognizes the real public boundary: a passing
trace that cannot coexist with its normalized result and other artifacts is
not a usable qualification workload. A coarse reproducible step and explicit
headroom avoid selecting a near-cap benchmark that would be fragile to honest
schema growth.

The staged lifecycle keeps the public atomic abstraction while giving the
measurement controller real stage boundaries. Content-addressed predecessor
validation and canonical reconstruction allow process isolation without
trusting caller JSON or duplicating compiler/simulator behavior.

## Alternatives rejected

- **Keep 100,000 and raise the limits.** The candidate is dominated by existing
  qualified/public byte contracts. A benchmark does not get to rewrite its
  safety boundary.
- **Use 20,000 because it happened to fit.** Its exact probe consumed more than
  93% of the public cap and left too little evolution/failure headroom for a
  non-boundary qualification candidate.
- **Count repeated expectations.** Static expansion grows operations and
  generated HDL, colliding with the portable source cap before isolating the
  runtime-stream axis.
- **Patch emitted SystemVerilog or trace output.** That severs authored intent,
  source maps, runtime truth, and normalized result identity.
- **Add a backend-private synthetic trace loop.** It creates activity that does
  not exist in VIAL semantics and therefore a second execution model.
- **Copy the Runner into measurement workers.** Two process runners, timeout
  policies, artifact assemblers, and cleanup paths would drift.
- **Expose lifecycle checkpoints publicly.** They are private implementation
  state, not a stable user contract.
- **Measure the existing Runner as one aggregate stage.** It loses the required
  compile/run/trace/result cost boundaries and cannot reuse compiled state
  across isolated workers.

## Compatibility and evolution

Selection changes no parser, bridge, ExecutionIR, backend, Runner, trace,
result, public tooling, support, limit, or runtime behavior. The implementation
leaf versions the portable runtime-stream materialization/oracle, replaces
only that profile's 100,000-record candidate, and preserves the shared level
role name. Existing public Runner success bytes are a mandatory compatibility
oracle for lifecycle extraction.

Rollback removes the qualification sources and portable candidate override,
restores the provider-free unmaterialized expectation, and makes the lifecycle
implementation unreachable. It does not remove or weaken current public
Runner behavior. Once measurement evidence is published, its schema/profile
revision remains immutable rather than being relabelled.

## Claim verification

- **Re-derivation:** derive the record equation independently from the authored
  reset, portable scheduler, trace families, and unchanged reference count;
  derive the artifact ceiling independently from the public tooling contract.
  The implementation must regenerate the tracked sources, plans, emitted
  loops, complete artifact bytes, and lifecycle transition chain.
- **Falsification:** execute exact 10,000/15,000 candidates; show 20,000 violates
  the three-quarter admission rule, 25,000 hits the complete-graph cap, and
  100,000 hits runtime capture. Mutate source equivalence, count, state,
  predecessor, object, command, tool, order, path, signal, timeout, capture,
  collision, and cleanup evidence; each must fail closed. Compare the refactored
  public Runner's successful result/artifact bytes with the predecessor.
- **Durability:** retain the tracked qualification sources, structural/runtime
  and lifecycle tests, versioned oracle, common measurement evidence, mdBook,
  Knowledge Map card, owning task-tree, this decision, and Git commits. The
  probe values remain selection evidence until the implementation reruns and
  seals the exact final source identities.
