# Portable Verilator Runtime Measurement

Portable-SystemVerilog runtime measurement follows the
[structural backend-emission matrix](16db-vial-structural-backend-emission-matrix.md).
Decision `0083` closes its architecture, and the authored-workload
materialization is now implemented. Two tracked VIAL sources, one
caller-sealed structural qualifier, and an exact public-Runner watcher bind the
10,000/15,000 candidates to real schedules without manufacturing activity.
The shared lifecycle, guarded host qualification, and common-controller
measurement adapter are implemented. Exact guarded qualification covers one
correctness-only reference, one validation plus three measured gate runs, and
one validation plus five measured qualification runs. The immutable matrix
publisher and its default hostile watcher are implemented; clean-revision
capture and separate fresh-process reload are the remaining closure step.

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
passed in the other attempts. The shared lifecycle now distinguishes process-
group creation, successful `exec` handoff, first generated output, and process
exit with monotonic evidence. Three implementation-time failures completed
`exec` in milliseconds but produced no bytes before the unchanged deadline. A
read-only macOS stack sample then placed every sampled main-thread frame in
`_dyld_start`, before the generated FSMGEN `main` or trace output. This closes
the lifecycle-attribution question for those observations; it does not prove
that macOS policy activity was causal or general.

Decision `0084` retains the host follow-up without changing the backend. On the
same macOS 26.5.2/M4 Pro/APFS host, a concurrent-link primary reached first
output in 391.195 ms while `syspolicyd` was at 49.0% CPU. Two naturally quiet,
zero-compiler primaries reached first output in 311.167 and 345.101 ms. The
generated 1,847,672-byte ARM64 executable, its byte-identical different-path
copy, and a fresh minimal C++ control all carried `com.apple.provenance` and
valid linker-created ad-hoc signatures; all ran, as did `/usr/bin/true`. An
exact quiet-primary four-second log window contained zero `syspolicyd` events.
Those controls show that compiler activity, policy-daemon CPU, provenance,
signature form, generated bytes, and generated path are not individually
sufficient deterministic causes. They do not claim that Gatekeeper or another
loader dependency can never participate in the intermittent host stall.

A fresh guarded observation then reproduced the movable failure: the generated
binary completed `exec` in 3.653 ms, produced zero bytes, and remained failed at
the exact 30-second wall. Its one-second sample placed all 895 main-thread
frames at `_dyld_start`, with a 96-KiB footprint and no binary-image map. The
byte-identical different-path control still executed, although it needed
10.823397 seconds to first output; fresh minimal C++ and `/usr/bin/true`
controls also passed. The failed primary plus those controls directly attribute
the observation to intermittent pre-main host loading, not generated VIAL
scenario semantics.

<!-- CLAIM-VERIFICATION:BEGIN vial-macos-premain-qualification-v1 -->
- Claim: On the recorded macOS 26.5.2/M4 Pro/APFS host, guarded qualification retains three successful primaries and one fresh failed 1,847,672-byte ARM64 primary whose 895/895 sampled main-thread frames remained at `_dyld_start`; all byte-identical-path, fresh-link, and platform controls pass, while standard Darwin regression uses an explicit qualification boundary and changes no backend runtime contract.
- Re-derive: Run the one-primary guarded watcher under an exact declared host condition, inspect its repository-local sample and primary/control/cleanup record independently, and run the complete public integration only with `FSMGEN_VIAL_DARWIN_RUNTIME_INTEGRATION=1` on Darwin; non-Darwin integration remains ordinary.
- Falsify: Compare the fresh failed and earlier passing concurrent-link observations, quiet no-compiler runs, byte-identical different-path, fresh minimal C++, platform true, exact policy-log-window, and complete public-integration control; keep every timeout failed and require the static validator to reject altered guard order, counts, hashes, controls, sampler locality, or boundaries.
- Durability: Retain the bounded evidence projection, guarded producer, default static validator, decisions 0084 and 0085, book, task-tree, Knowledge Map card, claim registry, and doctrine gate in one Git history chain after consuming and exactly removing raw host records.
<!-- CLAIM-VERIFICATION:END vial-macos-premain-qualification-v1 -->

Implementation verification keeps those two conclusions separate. The exact
guarded lifecycle watcher traverses all nine states with qualified Verilator,
assembles the expected public artifact graph, and removes its stage. The
independent guarded AHB runtime-parity watcher also passes. The broader public
API/CLI watcher now passes all seven top-level subtests in 167 seconds under a
natural no-compiler condition. Repeated API, CLI, phase-rollover, and direct-
drive results/artifacts are byte-deterministic and clean exactly. This later
pass does not erase or relabel the earlier failed run; it falsifies a stable
backend defect under the recorded condition.

Decision `0085` makes the durable response explicit. On Darwin, standard
`t/1558` regression skips before Verilator discovery; setting
`FSMGEN_VIAL_DARWIN_RUNTIME_INTEGRATION=1` runs the unchanged complete
integration and preserves a first timeout as failure. Non-Darwin integration
is unchanged. `t/1665` remains the one-primary diagnostic with its own explicit
guard and honest process-census condition. If its primary stays alive past two
seconds, `/usr/bin/sample -file` writes to a prevalidated repository-derived
sidecar; the watcher reads that exact regular file on the repository volume.
Default `t/1666` verifies the bounded failed/passing evidence, opt-in boundary,
producer identity, and sampler locality without launching a host-sensitive
primary. The one earlier sampler invocation that defaulted to `/tmp` was
copied, hash/size verified, consumed, deleted exactly, and censused absent. No
retry, larger timeout, xattr/signature change, security bypass, unrelated-
process termination, support promise, backend workaround, or public API change
follows from this qualification.

A later pre-push complete-CI run exposed a separate legacy-test boundary, not
a change to the qualified public Runner: the two-subordinate paired-BUSY test
launched its generated Verilator binary directly through `IPC::Cmd::run` with
no timeout or Darwin qualification. A live sample matched the retained
pre-main `_dyld_start` signature, so the run was stopped honestly; neither the
current file nor the unrun suffix was promoted to success. The complete audit
found 37 compile and 37 generated-runtime calls across the same 34 legacy test
files. Thirty-six runtime calls were unbounded; the remaining `t/1559` path
used an alarm timeout without verified descendant cleanup.

Decision `0086` is now implemented. Every audited compile and generated run
uses `FSM::Test::VerilatorRuntime`; no direct generated-binary IPC launch
remains. The test helper is deliberately not public product API. It derives
the repository root from its tracked module location, changes every child to
that root, accepts scalar argument vectors without a shell, requires the
compile object directory and generated executable to remain on the repository
volume, and rejects symlink executables. Version, compile, and runtime have
sealed 10/120/30-second walls and aggregate 65,536/8,388,608/67,108,864-byte
capture limits. Callers cannot replace or widen those values.

The boundary deliberately does not borrow the private VIAL
lifecycle. These IAL2/ISF tests compile handwritten harnesses and do not own
VIAL ExecutionIR, artifact, or state-transition authority. Their test-only
supervisor applies the same mature process principles at the proper layer.
Separate nonblocking stdout and stderr share the stage limit; a close-on-exec
control pipe distinguishes successful exec handoff from containment, chdir,
descriptor, and exec failures. Monotonic evidence records spawn, exec, first
output when present, and completion. Each child owns one process group. A
timeout, overflow, interrupted handoff, or surviving descendant sends TERM to
the complete group, escalates to KILL after a fixed grace interval, reaps the
leader, and verifies that the group is gone before returning.

The returned `fsmgen.test.verilator_runtime_result.v1` hash keeps separate
streams, exit and signal truth, timeout/overflow/exec flags, selected bounds,
timings, and closed cleanup evidence. `success`, `invocation_error`,
`qualification_required`, `exec_error`, `timed_out`, `output_limited`,
`signaled`, `nonzero_exit`, `surviving_descendants`, `cleanup_failed`, and
`host_error` remain distinct. No retry or later control can promote the first
failed result. The helper does not mutate the caller environment.

On Darwin, each affected legacy test issues `skip_all` with the exact reason
before any Verilator discovery unless the exact
`FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1` opt-in is present.
The helper enforces the same boundary independently before it can inspect a
command path or fork. This deliberate double boundary makes an omitted caller
skip fail closed. Non-Darwin execution remains ordinary, so hosted Linux keeps
the existing generated-HDL runtime coverage. The earlier
`FSMGEN_VIAL_DARWIN_RUNTIME_INTEGRATION` guard keeps its narrower public-VIAL
scope. This is test-process supervision, not IASIM execution and not a VIAL
execution profile.

A legacy test follows this shape:

```perl
use lib File::Spec->catdir($FindBin::Bin, 'lib');
use FSM::Test::ProjectDataLocality;
use FSM::Test::VerilatorRuntime qw(
    darwin_verilator_runtime_qualified
    darwin_verilator_runtime_skip_reason
    run_generated_binary
    run_verilator_compile
);

plan skip_all => darwin_verilator_runtime_skip_reason()
    unless darwin_verilator_runtime_qualified();

my $compile = run_verilator_compile([
    'verilator', '--binary', '--timing', '--Mdir', $object_dir,
    $generated_hdl, $testbench,
]);
ok($compile->{ok}, 'bounded compile succeeds')
    or diag($compile->{status}, $compile->{stdout}, $compile->{stderr});

my $runtime = run_generated_binary([$generated_executable]);
ok($runtime->{ok}, 'bounded generated runtime succeeds')
    or diag($runtime->{status}, $runtime->{stdout}, $runtime->{stderr});
```

The closed tracked
`t/data/darwin_inline_verilator_runtime_manifest.json` file owns the exact
affected path list and both callsite totals independently of the test code.
`t/1668-darwin-inline-verilator-test-runtime.t` consumes and validates that
manifest, then acts as both the hostile process oracle and recurrence watcher.
It proves guard ordering and environment
preservation; rejects invalid, symlink, and exec paths; retains nonzero and
signal truth; hits the real version capture ceiling; kills a TERM-resistant
descendant at the sealed deadline; rejects a leader that leaves descendants;
and recomputes the complete migration. The originally interrupted `t/1515`
also passes when explicitly qualified under the bounded helper. That passing
observation does not erase the earlier pre-main stall or justify retry-based
success; it proves that either future outcome is now finite and cleanup-safe.

## Shared test-process mechanism and sealed policy adapters

The next complete-CI suffix exposed the same class of infrastructure defect in
a different domain. `t/1545-task-acceptance-doctrine.t` builds small Git
repositories and executes the staged-index checker inside each fixture. Its
two direct `IPC::Cmd` launch paths had no deadline, bounded capture, or
whole-process-group cleanup. On the qualified Darwin host, the first checker
stopped before Bash entered user code: the child remained at
`/usr/bin/env bash`, and a one-second sample placed all 792 captured
main-thread frames at `_dyld_start` with no image map.

Decision `0087` makes the repair an architecture boundary rather than another
copy of process code:

```text
test callsite
  -> sealed domain adapter (commands, paths, bounds, schema)
  -> private ProcessSupervisor (fork/exec, streams, deadline, cleanup)
  -> one closed result
```

`FSM::Test::ProcessSupervisor` is private test infrastructure. It accepts a
scalar argument vector without a shell, validates a repository-contained
same-volume working directory, captures stdout and stderr separately under one
aggregate byte ceiling, and uses a close-on-exec control pipe to distinguish a
successful handoff from `chdir`, descriptor, containment, or `exec` failure.
Monotonic timestamps identify spawn, handoff, first output, and completion.
Every child owns one process group; timeout, overflow, handoff failure, or a
surviving descendant triggers TERM, bounded grace, KILL when required, leader
reaping, and a final group-disappearance check.

The low-level module deliberately does not pick a command or a safety budget.
Only sealed policy adapters in `t/lib/FSM/Test/` may call it, and
`t/1669-task-acceptance-fixture-runtime.t` recomputes that owner set.
`FSM::Test::VerilatorRuntime` remains decision `0086`'s adapter, so its Darwin
guard, 10/120/30-second stages, capture limits, result schema, and callsite
behavior are unchanged after the extraction.

The helper's hostile watcher does not re-enter the env boundary while creating
test programs. Each generated program embeds the canonical already-running
Perl interpreter in its shebang. This is mechanically watched: the portable
`#!/usr/bin/env perl` form may appear only on the watcher entrypoint that
`prove` launches through Perl. The boundary is evidence-driven—a combined run
completed exec handoff for the former env-Perl success fixture but received no
first output before the fixed runtime wall, and that failure was not retried.

`FSM::Test::TaskAcceptanceFixtureRuntime` is the separate `t/1545` policy. It
accepts only repositories created below
`.artifacts/tmp/task-acceptance-tests/`, rejects symlink ancestry and other
repository paths, and admits only the fixture's exact quiet-init, two local
identity-config, repository-relative add, and fixed baseline-commit argument
shapes. A global config, an absolute/parent add path, or another option fails
before process creation. Git and checker invocations each have a fixed
ten-second wall. Their aggregate capture ceilings are 1,048,576 and 4,194,304
bytes respectively. These values are selected by the adapter and cannot be
overridden by the test.
The adapter resolves `git` once from absolute inherited `PATH` entries and
retains its canonical executable; changing `PATH` later cannot substitute a
different tool for an already admitted Git operation.

The checker still begins with `#!/usr/bin/env bash`, but the adapter does not
execute that shebang. It similarly resolves `bash` once from absolute entries in the
inherited `PATH`, canonicalizes the selected executable, validates it, and
passes the repository-local checker path directly:

```perl
use FSM::Test::TaskAcceptanceFixtureRuntime qw(
    run_fixture_checker
    run_fixture_git
);

my $git = run_fixture_git($fixture, ['add', '--', 'README.md']);
die $git->{diagnostic} unless $git->{ok};

my $checked = run_fixture_checker($fixture);
ok($checked->{ok}, 'bounded staged-index checker succeeds')
    or diag($checked->{status}, $checked->{stdout}, $checked->{stderr});
```

This direct handoff preserves the Bash selected by the caller's toolchain
while removing the failed `env` process. Selecting macOS `/bin/bash` instead
was tested and rejected: version 3.2 fails the checker's empty-array loop under
`set -u`. Git and Bash are therefore explicit read-only host/toolchain dependencies;
project-owned fixture repositories, checker scratch space, streams, and
diagnostics remain on the repository volume.

The adapter returns
`fsmgen.test.task_acceptance_fixture_result.v1`, with separate streams,
exit/signal/timeout/limit/exec truth, selected bounds, monotonic timings, and
closed cleanup evidence. There is no retry. A nonzero checker remains nonzero,
a first timeout remains failed, and no later control can promote it. All nine
original `t/1545` subtests pass unchanged under the adapter. The combined
focused regression—original doctrine fixture, unchanged Verilator hostile
watcher, and the new shared-engine/adapter watcher—passes at three files and
19 top-level tests under the repository RAM guard.

The quantitative statements above have three independent legs:

- Re-derive the direct callsites and selected constants from `t/1545`, both
  policy adapters, and the shared engine, then run the original doctrine test.
- Falsify the interpreter choice with the retained macOS `/bin/bash` replay,
  and exercise rejected paths/subcommands, nonzero exit, plus a TERM-resistant
  descendant in the focused watcher.
- Keep the result durable through decision `0087`, the owning task-tree,
  Knowledge Map card `test-subprocess-policy-adapters`, the focused watcher,
  and the work-unit Git commit.

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
fresh worker process per stage. The implemented design preserves both needs with
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

The implementation validates more than the final state filename. Every resume
reconstructs the ExecutionIR and emission authority supplied by its sealed
caller, verifies the complete state-file census and predecessor chain, requires
the exact state-specific object-kind inventory, and rehashes every object with
its byte count and file mode. Prepared SystemVerilog work copies are compared
again with the sealed emitted sources before another process can consume them;
after compile, the executable work copy is compared with its sealed executable
object on every later transition. A stale handle may authorize cleanup only
after its lifecycle/storage authority is proved. A malformed or foreign handle
never gains deletion authority, while a failure after creation cleans the exact
new root.

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

Concretely, the measurement caller supplies one of the controller-owned
`validation/00`, `gate_measurement/01..03`, or
`qualification_measurement/01..05` lifecycle roots. The lifecycle derives the
actual compile/run records by rebasing only the emitted operation-owned work
prefix and then recomputes their content digests. Independently, it replaces
the concrete lifecycle and artifact roots with stable tokens to derive the
workspace-normalized identities. The real public and measurement command
digests therefore remain honestly different, while the normalized identities
prove that tool, flags, top, inputs, outputs, and command semantics are the
same. No caller-provided argv or arbitrary storage root is accepted.

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
and runtime keeps 30 seconds and 67,108,864 captured bytes. Those tool limits
begin inside the shared lifecycle, after the isolated worker has reconstructed
canonical route and emission authority. The controller independently contains
the complete compile worker for 900 seconds and the complete run worker for 300
seconds. These are outer failure/cleanup envelopes, not alternate tool
allowances: accepted evidence must prove both the outer envelope and the exact
inner 10/120/30-second captures.

Process supervision establishes containment before `exec`, uses close-on-exec
control pipes, and records spawn/exec handoff separately from generated-main
time. This is necessary because a single generic “runtime timeout” cannot tell
whether delay occurred before or after the executable began. A timeout, signal,
capture overflow, tool drift, malformed output, or consumer failure terminates
and reaps the complete owned process tree, publishes no final graph, and removes
only the exact proven-owned stage. No retry or timeout widening is selected.

The process evidence keeps the following distinctions:

| Evidence | Meaning |
| --- | --- |
| `spawn_to_exec_ns` | containment, working-directory, and descriptor handoff before successful `exec` |
| `exec_to_first_output_ns` | loader/startup plus generated execution before the first captured byte |
| `first_output_to_exit_ns` | generated execution after output begins |
| `exec_failed` / `exec_error` | bounded control-pipe failure before the target image ran |
| `timed_out` / `output_limited` / `signal` | independent deadline, aggregate-capture, and process outcomes |

Control-pipe readiness is consumed before ordinary output when both are ready,
so observation order cannot invert the causal `exec` boundary. The deadline
continues even if a hostile child closes both output descriptors and hangs.
Public execution owns a fresh process group; TERM/KILL completion checks the
whole group rather than treating leader reaping as proof that descendants are
gone. Measurement tools remain in the common controller worker's outer process
group, while the lifecycle remains their sole tool-deadline supervisor.

## Implemented common-controller measurement

`FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement` is the one
caller-sealed adapter between the generic architecture-scale controller, the
portable runtime materializer, and the shared Verilator lifecycle. It owns
exactly five shapes:

| Shape | Controller/tool behavior |
| --- | --- |
| `reference_v1` | one correctness-only controller validation |
| `gate_candidate_v1` | one validation, then three measured repetitions |
| `qualification_candidate_v1` | one validation, then five measured repetitions |
| `limit_v1` | structural preflight rejection; no controller or Verilator |
| `over_limit_v1` | structural preflight rejection; no controller or Verilator |

Every applicable worker reconstructs the tracked construction, blessed route,
ExecutionIR, emission, and tool profile from repository anchors. The adapter
then cross-checks the structural identities and admits only the exact qualified
Verilator 5.046 profile. `compile_analyze` and `run` are classified as external
tool stages; construction, parse/validation, bridge, bind/plan, emission,
trace validation, result production, publication, and cleanup remain
FSMGEN-owned. Integrated elaboration is retained explicitly as `not_run`, not
silently omitted or assigned a fabricated duration.

An accepted controller record retains raw samples for every executed measured
stage, exact controller command identity and input counts, lifecycle and
operation identities, the full predecessor-state chain, actual compile/run
commands and their digests, workspace-normalized command digests, bounded
compile/run transcripts, trace count/hash, result identity, the complete final
artifact census, and exact lifecycle/controller cleanup. Validation records
run the same correctness route but intentionally retain no performance sample.
A failed validation prevents measured repetitions; a failed repetition stays a
failed exclusion and is never retried or relabelled.

The final public graph is large enough that moving it through the controller's
JSON pipe would duplicate tens of MiB of already sealed evidence. Measurement
therefore stores a compact content-addressed assembled-state descriptor with
the result-payload digest, artifact count/identity, and result path. A fresh
resume rebuilds and verifies the complete assembly from lifecycle objects. The
terminal measurement transition materializes the public graph exactly once
beneath the controller-owned publish output and returns compact identities,
commands, digests, and transcripts. The public Runner still returns its
unchanged complete in-memory graph.

The measurement graph contains the 12 artifacts actually returned by the
qualified runtime lifecycle. The earlier structural materialization graph has
19 complete virtual artifacts because it projects additional pre-tool
structure. Both are valid for their separate questions; their counts and byte
totals must not be compared as though they were the same graph.

The normal closed-contract watcher is inexpensive and tool-free:

```sh
prove -Iperl t/1667-vial-architecture-scale-portable-runtime-measurement.t
```

Exact runtime qualification is deliberately opt-in and must run below the
repository RAM guard:

```sh
FSMGEN_VIAL_PORTABLE_RUNTIME_MEASUREMENT_EXACT=1 \
  scripts/run_with_ram_guard.sh -- \
  prove -Iperl t/1667-vial-architecture-scale-portable-runtime-measurement.t
```

The shared lifecycle's compact assembled-state fresh-resume proof is likewise
available as an exact guarded watcher:

```sh
FSMGEN_VIAL_MEASUREMENT_COMPACT_RESUME_EXACT=1 \
  scripts/run_with_ram_guard.sh -- \
  prove -Iperl t/1664-vial-verilator-shared-lifecycle.t
```

Here, “runtime execution” means running the generated portable SystemVerilog
through Verilator. IASIM remains the separately owned reference-semantics
engine; this adapter neither invokes it nor changes its contract.

<!-- CLAIM-VERIFICATION:BEGIN vial-portable-runtime-measurement-v1 -->
- Claim: The exact guarded common-controller watcher accepts one 274-record reference validation, one 10,000-record gate validation plus three measured repetitions, and one 15,000-record qualification validation plus five measured repetitions; every accepted runtime returns the exact 12-artifact graph, all selected measured-stage samples, zero exclusions, and zero cleanup residue.
- Re-derive: Run guarded `t/1667-vial-architecture-scale-portable-runtime-measurement.t`; the adapter independently reconstructs repository construction, route, emission, tool, lifecycle, trace/result, artifact, and cleanup authority for every isolated stage and reloads the completed report.
- Falsify: Run the default preflight/caller-seal/guard/schema/failure-evidence tests, the exact compact-descriptor fresh-resume watcher, and the guarded full watcher; require tool-free limit/excess, typed command identities, exact state/trace/result/artifact closure, and keep every host timeout, guard trip, or exclusion failed.
- Durability: Retain the tracked adapter, sole lifecycle, materializer seam, default and guarded watchers, task/decision/book/card/claim records, doctrine gates, and Git history. Raw wall-time, CPU, and RSS values remain unpublished; the separately claimed matrix seal retains exact sample and lifecycle evidence without promoting a performance budget.
<!-- CLAIM-VERIFICATION:END vial-portable-runtime-measurement-v1 -->

## Immutable runtime matrix publication

`FSM::VIAL::ArchitectureScalePortableRuntimeMeasurementMatrix` derives its
five coordinates directly and in order from the measurement producer. It
routes validation and preflight modes through `validate_profile`, while gate
and qualification modes use `measure_profile`. An unknown mode fails before
producer work; callers cannot supply profiles, reports, identities, or seals.

Each coordinate runs in a separate close-on-exec child. The child reconstructs
and validates the complete producer report, atomically publishes that raw
report below the repository-derived same-volume qualification root, and sends
only a closed compact entry across a nonblocking bounded pipe. The coordinator
admits one clean Git revision plus one host, exact Verilator tool, and enforced
guard identity. Because preflight reports intentionally have no controller
record, they may inherit only the identity already established by the earlier
reference/gate/qualification coordinates; they cannot originate or alter it.

<!-- CLAIM-VERIFICATION:BEGIN vial-portable-runtime-matrix-bounds-v1 -->
- Claim: The portable-runtime publisher derives five profiles from producer ownership, limits each canonical publication to 4,194,304 bytes, and limits each compact child result to 65,536 bytes; its exact 848,468-byte three-sample/10,000-record gate publication scales under the selected five-sample/15,000-record qualification route to a conservative 2,121,170-byte projection, leaving 2,073,134 bytes before the binary ceiling.
- Re-derive: Compare producer `owned_shapes` with runner `--inventory`, independently census the accepted canonical gate publication, query `publication_limits`, and recompute `848,468 * (5/3) * (15,000/10,000)`; do not infer the calibration or projection from the ceiling.
- Falsify: Run the default t1670 watcher mutations for order, duplicate/missing samples, forged preflight execution/identity, oversized IPC/publications, signals, collisions, and exact-versus-ambiguous crash staging; the closing guarded capture must also fit and reload the real largest report.
- Durability: Retain the tracked producer, publisher, runner, watcher, task/book/card/claim records, doctrine gates, and Git chain; rerun the bound watcher when any participant changes.
<!-- CLAIM-VERIFICATION:END vial-portable-runtime-matrix-bounds-v1 -->

The first clean exact campaign falsified the provisional one-MiB bound after
successfully sealing a 75,883-byte reference file and an 848,468-byte gate
file containing all three raw repetitions. No oversized qualification file or
aggregate seal was written. The repair scales the entire gate publication by
both repetition growth and workload growth, deliberately scaling fixed
metadata twice, then rounds the 2,121,170-byte result up to a four-MiB binary
containment envelope. Rejection diagnostics disclose actual and allowed bytes;
the compact child IPC and error ceilings remain 65,536 and 4,096 bytes. A new
second clean exact campaign fits the real largest report but remains unsealed
after a later tool-free dispatch failure. The explicit dispatcher repair and
one subsequent clean campaign now seal and independently reload the full set.

<!-- CLAIM-VERIFICATION:BEGIN vial-portable-runtime-matrix-seal-5268f50e2-v1 -->
- Claim: Clean revision `5268f50e2118900af5b7da13867a449350993fa6` seals the five-profile portable-runtime matrix as seven immutable files totaling 2,674,079 bytes; the largest profile is 1,722,758 bytes, the accepted aggregate retains three validation-route and two measured-route profiles, eight raw and zero excluded records, two preflight-dominated profiles, eleven cleanup and zero residue records, and a separate guarded reload returns complete identity `portable-runtime-matrix/7673f6be149be57d7963c8ba14fb03dba8604ad523c055de5beb0d8717050426`.
- Re-derive: Run guarded `--validate`, census only the five portable-runtime profile publications plus family and complete manifests independently with `find` and `wc`, and hash all seven files with `shasum -a 256`.
- Falsify: Run exact guarded t1670 from an empty namespace and require rejection for any profile, manifest, common-identity, route, sample, exclusion, dominance, checksum, collision, cleanup, or staging disagreement.
- Durability: Preserve the content-addressed profile publications plus family/complete manifests on the repository volume, and retain the exact task, book, Knowledge Map, watcher, claim record, and Git closure chain.
<!-- CLAIM-VERIFICATION:END vial-portable-runtime-matrix-seal-5268f50e2-v1 -->

Raw profile files, the family `matrix.json`, and the complete
`complete-matrix.json` are immutable single-file publications. Byte-equal
resume is accepted; different content collides. Exact crash staging may be
recovered only when its single canonical file is byte-identical. Malformed,
extra, symlinked, cross-volume, partial, stale, reordered, mixed-identity, or
oversized state fails before an aggregate seal is visible. The aggregate
retains validation and measurement identities, requested/validated trace
counts, artifact counts, exclusions, cleanup, dominance, and nonclaims.

Inventory is tool-free and needs no guard. Capture and independent reload use
the repository guard; capture additionally requires a clean revision:

```sh
scripts/run_vial_portable_runtime_measurement_matrix.pl --inventory
scripts/run_with_ram_guard.sh -- \
  scripts/run_vial_portable_runtime_measurement_matrix.pl
scripts/run_with_ram_guard.sh -- \
  scripts/run_vial_portable_runtime_measurement_matrix.pl --validate
```

The default watcher is fast and does not create qualification evidence:

```sh
prove -Iperl \
  t/1670-vial-architecture-scale-portable-runtime-measurement-matrix.t
```

The exact watcher is deliberately opt-in because it executes every selected
runtime repetition and then starts a fresh validator process:

```sh
FSMGEN_VIAL_PORTABLE_RUNTIME_MATRIX_EXACT=1 \
  scripts/run_with_ram_guard.sh -- \
  prove -Iperl \
    t/1670-vial-architecture-scale-portable-runtime-measurement-matrix.t
```

The reference and gate observations calibrate serialization containment; they
are not performance results. The clean seal publishes no raw wall/CPU/RSS
value, and no bound here claims backend support,
performance, capacity, a reached record boundary, cross-backend parity, IASIM
execution, or a public API change.

## Intended ownership sequence

The task tree separates completed prerequisite repairs and selection from
runtime materialization, shared lifecycle, per-profile measurement, and
immutable matrix publication. Each unit must commit cleanly before the next
begins. The implemented shared lifecycle remains private:
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
