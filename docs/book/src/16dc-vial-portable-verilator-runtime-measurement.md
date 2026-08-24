# Portable Verilator Runtime Measurement

Portable-SystemVerilog runtime measurement follows the
[structural backend-emission matrix](16db-vial-structural-backend-emission-matrix.md).
Decision `0083` closes its architecture, and the authored-workload
materialization is now implemented. Two tracked VIAL sources, one
caller-sealed structural qualifier, and an exact public-Runner watcher bind the
10,000/15,000 candidates to real schedules without manufacturing activity.
Repeated stage measurement is not complete: the separately owned shared
Verilator lifecycle is now the active implementation boundary.

This “execution” means external execution of generated portable SystemVerilog
with the already qualified Verilator profile. It is not IASIM execution and it
does not change IASIM's separately owned reference-semantics role.

<!-- CLAIM-VERIFICATION:BEGIN vial-portable-runtime-materialization-v1 -->
- Claim: The two tracked portable-SystemVerilog runtime sources produce exact 10,000- and 15,000-record semantic traces through the qualified public Runner; each complete graph contains 19 artifacts totaling 32,098,531 and 47,505,049 bytes respectively, and qualification remains 2,826,599 bytes below the selected three-quarter admission ceiling.
- Re-derive: Reconstruct each tracked source through the ordinary Parser/PlanBuilder/bridge/ExecutionIR/portable-emitter route twice, independently project its semantic record families, then run both through the unchanged qualified public Runner and census the returned artifact sink and validated trace.
- Falsify: Run source/report/route/invocant/relocation/staging mutations and the guarded opt-in Runner path; require exact inventory, total bytes, record-family partition, result/scenario closure, sibling-profile preservation, preflight denial, and zero residue.
- Durability: Retain the tracked authored sources, caller-sealed materializer, provider-free profile watcher, guarded opt-in public Runner watcher, book/card/task claim, claim registry, and doctrine gate in one Git history chain.
<!-- CLAIM-VERIFICATION:END vial-portable-runtime-materialization-v1 -->

## Why contract selection came first

The shipped public Runner is an atomic transaction: it validates the exact
tool, materializes inputs, compiles, runs, validates the trace, produces the
normalized result, assembles artifacts, and removes its private stage. That is
the right public behavior. Measurement, however, must report those operations
as distinct stages while preserving one compiled executable and one coherent
evidence chain across isolated measurement workers.

The runtime-stream family also selects semantic activity counts rather than a
larger source file. A production-grade implementation therefore needs a
canonical runtime schedule whose identity is carried by emission, trace, and
result evidence. Editing generated source text after emission, padding output,
truncating a trace, or introducing a second tool runner would make the measured
work differ from the qualified work and is forbidden.

Decision `0083` closes both contracts before implementation:

| Boundary | Required decision |
| --- | --- |
| runtime activity | how canonical semantic work reaches each selected candidate without falsifying the base execution plan |
| identity | how the schedule is bound into backend, trace, transcript, and result evidence |
| applicability | which reference, candidate, limit, and excess shapes may execute the tool and which reject earlier |
| stage state | what immutable repository-local evidence moves from prepare to compile, run, trace validation, and result production |
| reuse | how the public Runner and scale measurement invoke the same caller-sealed lifecycle |
| failure | how timeout, signal, capture limit, malformed state, collision, and cleanup remain atomic and diagnosable |

## Completed prerequisite: successor phase rollover

The first real reachability probe found a product defect before it found a
scale limit. A legal scenario placed a check-phase `expect` before a later
react-phase `scoreboard_expect`. ExecutionIR retained the authored dependency,
increasing static ranks, and both eligible phases correctly. The portable
SystemVerilog scenario task called the two generated tasks directly, so the
real Verilator trace contained cycle-4 check followed by cycle-4 react. The
unchanged deterministic-order validator correctly rejected that regression.

The completed repair keeps static partial evaluation. It does not introduce a
target interpreter or phase-sort the source. The emitter has one independently
qualified compatibility table that pairs each supported action's ExecutionIR
eligible phase with the last logical phase consumed by its generated task:

| Lowering returns after | Actions |
| --- | --- |
| `drive` | `drive` |
| `react` | `start`, `repeat`, `scoreboard_expect`, `inject` |
| `check` | `reset`, `await`, `parallel`, `expect`, `scoreboard_check` |

The scheduler walks immutable root-operation/static-rank order and retains that
last phase as a cursor. Equal or forward phase ranks stay in the same cycle;
same-phase checks therefore remain in authored order without an idle cycle. A
backward crossing advances exactly once:

| Crossing | Generated action | Why |
| --- | --- | --- |
| `check -> react` | one inactive-edge barrier | reaches genuine next-cycle sample/react state |
| `react -> drive` | one logical-cycle increment | selects the next drive phase without an extra sample |
| `check -> drive` | one logical-cycle increment | selects the next drive phase without an extra sample |

A direct slot update returns in `drive`. Another root direct drive therefore
runs in the same phase and retains authored/static-rank order. A later react or
check action is a forward rank numerically, but it cannot consume a post-edge
snapshot until the current cycle has crossed the real inactive-edge sample
barrier. The scheduler inserts exactly that one barrier; it also traverses it
before scenario finalization when drive is the last operation.

There is no sample-eligible version-1 action and no possible backward target at
check. `start` no longer increments the cycle unconditionally inside its own
task: a first start may use cycle-zero drive, and the common successor boundary
advances it only when required. Negotiation now rejects a changed phase order
or action/eligible-phase pair before emitting any artifact.

This division is deliberate. ExecutionIR owns topology, ranks, and eligible
phases; the backend owns how far each of its blocking lowerings advances before
return. Combining those authorities preserves dynamic waits and reset
intervals without guessing their completion cycle. Sorting actions, adding a
barrier after every task, rejecting legal source, or rewriting trace time would
all change semantics rather than implement them.

The structural proof covers every possible backward pair, same-phase
retention, blocking reset, and fail-closed phase drift. The public Runner proof
uses qualified Verilator 5.046, produces one genuine passing inserted
expectation, validates the complete result, removes staging, and returns
byte-identical results and artifacts on a repeated repaired run. Decision
`0080` records the alternatives and rollback.

## Completed prerequisite: direct `drive`

The phase-table signoff exposed a separate pre-existing defect rather than
hiding it in the rollover change. Ordinary VIAL could bind a public DUT input
and retain a `drive` operation with typed endpoint/value inputs, yet the effect
target was null and the generated task contained only a barrier. It neither
assigned the endpoint nor emitted a drive record.

Completed task `.17.3.5.1.2` repairs the entire semantic chain. For example,
the checked source can add this endpoint declaration and action:

```lisp
(endpoint select "endpoint/HSEL" (logic 1) public_port)
...
(drive select #b1)
```

The builder now produces one exact `update_driver` target and one drive
representation relation. The backend independently requires that effect,
binding, relation, normalized known scalar, public input carrier, and declared
SystemVerilog port before emitting anything. Its generated operation is
equivalent to:

```systemverilog
vial_transaction_static_rank = 1;
HSEL = 1'h1;
vial_emit("drives", /* exact endpoint, operation, logical time, and value */);
```

This is a zero-duration drive-phase update: the task itself has no barrier.
Same-fiber updates stay ordered in one phase; drive-to-react/check traverses one
real sample barrier. Live sibling writes to the same slot fail once with a
stable scenario/endpoint conflict rather than choosing by simulator order.
After the terminal fiber record, scenario finalization restores each directly
used slot once to safe zero before `scenario_end`; that lifecycle assignment is
not a second authored drive and has its own exact source-map provenance.

Trace validation does not trust a plausible runtime line. For a direct record
it rechecks the immutable operation, exact bound bridge endpoint, null
transaction field, canonical effective value, drive-phase/static/local ranks,
and semantic endpoint identity. Endpoint, value, or phase forgery fails before
result production. A real qualified-Verilator public run observes exactly one
`endpoint/HSEL` drive and returns byte-equal results and artifacts on its
focused replay.

The portable support boundary is deliberately narrower than generic
ExecutionIR: only a public `input` carrier in the scenario root fiber is
accepted. Inout needs a resolved-driver policy and non-root drive needs a
qualified child-fiber scheduler. Both fail before artifacts and remain explicit
non-claims. Decision `0081` records the rationale, alternatives, rollback, and
three verification legs.

The same signoff audit found that the current `parallel` renderer is a property
scheduler, not a general child-fiber interpreter. An ordinary-source RED
replaced one child `await` with `reset`: target-neutral planning succeeded and
the backend emitted a complete artifact set, but the reset was never executed.
Completed `.17.3.5.1.3` now reconstructs the complete parallel/fiber ownership
shape during negotiation and admits only the already qualified profile: every
distinct direct child fiber contains exactly one terminal `await`. Every other
recognized child operation, multi-operation sequence, nested parallel, and
malformed ownership shape fails before artifacts with identity-complete stable
diagnostics. Existing `all`/`any` tie and cancellation behavior is unchanged;
general parallel-child sequences are an explicit machine-readable nonclaim.
Decision `0082` records why a future general scheduler must be a selected,
versioned architecture rather than an implicit defect-repair side effect.
The gate is scoped to the public revision-1 runtime profile: the separately
caller-sealed balanced revision-2 renderer remains a structural-qualification
route with no compile/runtime/trace/result claim and its own exact-shape oracle.

That compatibility sweep also found and closed a separate, older scale-evidence
drift. The frozen portable oracle predated the completed phase-rollover and
direct-drive repairs. Independent regeneration produced different deltas at
reference and expanded levels, so the result was not fixed padding. Decision
`0075` now defines portable artifact-oracle revision 2: reference, gate, and
qualification are 164,507, 2,803,857, and 10,910,865 source bytes; `T=6,318`
is the exact 16,774,723-byte accepted limit; and pre-cap `T=6,319` is
16,777,362 bytes and rejects atomically under the unchanged 16-MiB cap. The
renderer already conditions rollover on a real backward phase transition, so
removing it would reintroduce the semantic defect; cosmetic byte shaving was
also rejected as a boundary-preservation hack. The versioned oracle, all
source identities, byte-equal reruns, mutation rejection, balanced revision-2
prerequisite, and cleanup watchers now let runtime materialization selection
resume without weakening semantics or borrowing a support/capacity claim.

Repeated guarded full integration attempts also exposed the existing Runner's
fixed 30-second run wall under concurrent cross-repository compiler load. A
direct-drive replay, a baseline replay, and later the first unchanged baseline
run have each timed out in separate attempts, while byte-identical counterparts
passed in the other attempts. The available diagnostic cannot distinguish
executable-launch delay from time spent in generated `main`, so no narrower
root-cause claim is made. Active implementation task `.17.3.5.3` now owns
timeout/stage-state evidence and the shared lifecycle policy; the focused
direct-drive runtime proof remains separate from that lifecycle defect/risk.

## Selected authored runtime activity

The runtime-stream axis measures the cost of producing, validating, and
normalizing semantic runtime evidence. A larger generated source is a different
axis. The selected workload therefore keeps a small checked AHB plan while
increasing real clocked activity.

The checked reference produces 274 validated records. Its fixture samples four
values on each inactive-edge scheduler cycle: three output endpoints and one
declared verification probe. Coverage records are accumulated during those
cycles and emitted at scenario finalization. Extending an authored reset hold
by one cycle therefore adds four `samples` records plus one `coverage` record.

The selected candidate adds one passing `scale_response_zero` expectation
after the existing scoreboard check. Both are check-phase operations, so that
expectation contributes one record without inserting another clock barrier.
For authored reset count `N`:

```text
records(N) = 274 + 5 * (N - 3) + 1
           = 5N + 260
```

The implemented gate source is
`vial/qualification/sv_portable_verilator_runtime_gate.vial`; it uses
`N=1,948` and reaches exactly 10,000 records. The implemented qualification
source is
`vial/qualification/sv_portable_verilator_runtime_qualification.vial`; it uses
`N=2,948` and reaches exactly 15,000 records. Both use a 4,096-cycle success
timeout/window envelope and retain the real transaction, random decision,
parallel waits, event models, scoreboard, coverage, injected fault, passing
expectations, and unsupported-size scenario from the reference. Their only
additional terminal operation is:

```lisp
(scoreboard_check writes)
(expect scale_response_zero (same (sample response) #b0))
```

These are tracked sources, not strings patched during a run.

Before Verilator starts,
`FSM::VIAL::ArchitectureScalePortableRuntimeMaterialization` verifies the exact
source bytes and reconstructs an oracle-only reference projection. It accepts
only the declared reset/timeout/window literals and terminal expectation as
deltas, then independently rebuilds SemanticIR, the checked bridge,
ExecutionIR, source maps, plan, and portable emission twice. The actual route
always consumes the tracked source; the projection is never an emission or
runtime input. The evidence chain is:

```text
VIAL reset count
  -> SemanticIR action
  -> ExecutionIR operation and source map
  -> generated reset loop
  -> clocked sample and coverage records
  -> trace projection
  -> result streams and metrics
  -> backend, trace, and result identities
```

Output padding, trace truncation, post-emission HDL editing, or a backend-only
synthetic loop would break this chain and are forbidden.

The structural reports freeze 22 operations and 40 ExecutionIR source maps for
each candidate. Emission contains one exact `repeat (1948)` or `repeat (2948)`
inactive-barrier loop and 55 backend source-map entries. The reports also
derive each trace family before tool execution:

| Record family | 10,000 gate | 15,000 qualification |
| --- | ---: | ---: |
| samples | 7,928 | 11,928 |
| coverage | 1,982 | 2,982 |
| expectations | 11 | 11 |
| events / drives | 36 / 16 | 36 / 16 |
| models / scoreboards | 4 / 4 | 4 / 4 |
| faults / fibers / transactions | 3 / 8 / 2 | 3 / 8 / 2 |
| scenario start / end | 2 / 2 | 2 / 2 |
| header / footer | 1 / 1 | 1 / 1 |
| **total** | **10,000** | **15,000** |

The default structural watcher is:

```text
prove -Iperl t/1663-vial-architecture-scale-portable-runtime-materialization.t
```

Setting `FSMGEN_RUN_VIAL_PORTABLE_RUNTIME_EXACT=1` while running that test
under `scripts/run_with_ram_guard.sh` additionally executes both tracked
sources through the unchanged qualified public Runner and compares the real
19-artifact graphs and every trace-family count with the pre-tool reports.

## Why portable qualification uses 15,000 records

The earlier provider-free specification named 100,000 records before proving
that its truthful representation fit the qualified/public byte envelopes.
Exact ordinary public runs found two independent 64-MiB authorities:

- the Runner captures at most 67,108,864 runtime-output bytes; and
- the public VIAL transaction permits at most 67,108,864 bytes across the
  complete virtual artifact graph.

The complete graph includes generated/review sources, plans, bridge and tool
manifests, command records, normalized trace and result, transcripts, and
evidence. A trace that fits by itself is not usable if its required result makes
the public graph unpublishable.

Selection probes established this profile before final source paths and
identities were tracked:

| Trace records | Complete graph bytes | Selection result |
| ---: | ---: | --- |
| 10,000 | 32,096,420 | gate candidate accepted |
| 15,000 | 47,502,039 | qualification candidate accepted |
| 20,000 | 62,914,039 | fits, but lacks qualification headroom |
| 25,000 | more than 67,108,864 | public graph rejects atomically |
| 100,000 | runtime output exceeds 67,108,864 | Runner rejects before publication |

Qualification uses the largest 5,000-record step whose complete graph occupies
no more than three quarters of the hard public artifact cap. The 15,000-record
probe left 19,606,825 bytes of hard-cap headroom; 20,000 left only 4,194,825.
The implemented tracked-source reruns independently regenerate slightly
different complete-graph bytes because their final source paths and identities
are themselves evidence:

| Tracked level | Complete graph | Three-quarter margin | Hard-cap headroom |
| --- | ---: | ---: | ---: |
| 10,000 gate | 32,098,531 | 18,233,117 | 35,010,333 |
| 15,000 qualification | 47,505,049 | 2,826,599 | 19,603,815 |

The governing three-quarter ceiling is 50,331,648 bytes. The final 15,000
source therefore passes the rule independently rather than inheriting the
47,502,039-byte selection observation. The 20,000 selection remains rejected
by headroom, 25,000 by the complete-graph cap, and 100,000 by runtime capture;
all three are classified before an external tool can start in the
materialization contract.

The rule does not lower or replace a public limit. It chooses a non-boundary
qualification workload with deliberate room for honest evidence-schema growth.
It also does not set a performance budget; budgets require the later repeated,
pinned-host measurement evidence.

The portable levels are now classified as follows:

| Level | Runtime treatment |
| --- | --- |
| `reference_v1` | unchanged checked source; one correctness-only validation |
| `gate_candidate_v1` | exact 10,000 records; validation plus three measured runs |
| `qualification_candidate_v1` | exact portable override of 15,000 records; validation plus five measured runs |
| `limit_v1` | structural specification only; earlier byte representation dominates, so no tool run |
| `over_limit_v1` | structural excess specification only; fail during preflight with no tool run |

The old portable 100,000 candidate was therefore an owned contract defect, not
an ignored failed test. The workload constructor now returns 15,000 only for
`sv_portable_verilator/qualification_candidate_v1`; portable VHDL and qualified
OSVVM retain their separately owned 100,000 candidate under the same stable
role label. Nominal limit and excess reports contain only structural minimum
representations, create no route or stage, and claim no reached record
boundary.

The nominal record limit and excess remain useful specifications, but neither
is a reached record boundary. Later cap work must identify the exact earliest
byte boundary using compact preflight before it considers materialized proof.

## One shared lifecycle, two views

The shipped public Runner is correctly atomic from a user's perspective: it
validates the tool, prepares inputs, compiles, runs, validates the trace,
produces the result, assembles artifacts, and removes its stage before return.
Scale measurement needs those operations as separate cost centers and uses a
fresh worker process per stage. The selected design preserves both needs with
one private `FSM::VIAL::Backend::VerilatorLifecycle` implementation.

Its only legal state chain is:

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

Each state is closed canonical JSON in an ordinal, content-addressed file. It
names its predecessor digest, plan and emission seals, exact tool and command
identities, referenced object digests, and only legal successor. Large sources,
the executable, bounded raw output, normalized trace, and result are stored as
digest/byte/kind-checked objects on the repository volume; they do not cross
the measurement controller's bounded JSON pipe.

A later worker cannot trust a path or state supplied by its caller. It
reconstructs the canonical source-to-emission route, derives the lifecycle
identity and owned root, verifies the complete predecessor chain and object
census, and only then performs the next transition. Skipped, replayed,
reordered, malformed, collided, symlinked, or mutated state fails closed.

The public Runner keeps its existing staging convention and must preserve
successful artifact bytes. Measurement uses a separately sealed storage
context nested below its exact `.artifacts/tmp/vial-scale/` run root. Actual
staging paths and command digests may consequently differ, so the lifecycle
retains both the exact command and a stable workspace-normalized command
identity. The executable, flags, input bytes, tool, scheduling, trace validator,
result producer, and artifact assembly remain one shared implementation.

The common measurement stages map to lifecycle work like this:

| Measurement stage | Work |
| --- | --- |
| `emit` | canonical backend emission and lifecycle admission |
| `compile_analyze` | prepare, verify exact Verilator identity, run `verilator --binary` |
| `elaborate` | not run; portable Verilator integrates elaboration into `--binary` |
| `run` | execute the exact compiled binary and retain bounded raw output |
| `trace_validate` | extract closed framing and validate the normalized trace |
| `result_produce` | revalidate predecessor evidence and produce the normalized result |
| `publish` | assemble final artifacts and compact measurement evidence |
| `cleanup` | remove and census the exact lifecycle and controller roots |

The backend limits do not widen for measurement: the exact version query keeps
its 10-second ceiling, compile keeps 120 seconds and 8,388,608 captured bytes,
and runtime keeps 30 seconds and 67,108,864 captured bytes. The common outer
stage ceiling remains an additional guard; the effective deadline is the
smaller applicable value.

Process supervision establishes containment before `exec`, uses close-on-exec
control pipes, and records spawn/exec handoff separately from generated-main
time. This is necessary because a single generic “runtime timeout” cannot tell
whether delay occurred before or after the executable began. A timeout, signal,
capture overflow, tool drift, malformed output, or consumer failure terminates
and reaps the complete owned process tree, publishes no final graph, and removes
only the exact proven-owned stage. No retry or timeout widening is selected.

## Intended ownership sequence

The task tree separates completed prerequisite repairs and selection from
runtime materialization, shared lifecycle, per-profile measurement, and
immutable matrix publication. Each unit must commit cleanly before the next
begins. The shared lifecycle remains private:
the existing public command and result contract must keep its successful bytes,
qualified commands, stable diagnostics, process-group termination, transcript
limits, and exact cleanup behavior.

Only the canonical portable profile may enter this lane. A validation run must
succeed before measured repetitions are retained. Gate and qualification
samples remain raw evidence under the common resource guard; limit or excess
shapes that are already authoritatively dominated must not invoke Verilator.
Every accepted measurement must independently close artifact/source-map,
command, tool, trace framing/order/count, semantic outcome, normalized result,
publication, and cleanup oracles.

No work in this lane implies full-SystemVerilog behavior, complete four-state
observation, UVM, VHDL or OSVVM execution, mixed-language behavior, general
cross-backend parity, a public performance budget, architecture capacity, a
reached boundary, or a new public API. Those claims require their own completed
evidence and owners.
