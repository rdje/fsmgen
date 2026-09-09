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
aggregate byte ceiling, and retains `chdir`, descriptor, containment, and
`exec` errors through a close-on-exec control pipe. Monotonic timestamps record
spawn, observed control-pipe closure, first output, and completion.
The legacy `exec_handoff_monotonic_ns` field records that observed closure;
it does not prove entry into the program's `main`. Abrupt child death can also
close the pipe before `exec`. If capture ends without observing closure,
the handoff timestamp and dependent durations remain null, including after
timeout cleanup. Completion time never substitutes for missing launch evidence.
Every child owns one process group; timeout, overflow, handoff failure, or a
surviving descendant triggers TERM, bounded grace, KILL when required, leader
reaping, and a final group-disappearance check.

Before executing the command, the child checks both the process-group call's
return value and its actual group identity. A failed call or a child outside
its intended group returns `exec_error` without executing the command. The
parent's parallel group-creation attempt does not replace this child check.
After KILL, leader reaping uses nonblocking polling within the existing cleanup
grace. If the leader or group remains, the result retains incomplete cleanup
evidence; sending a signal alone never proves that the process has disappeared.

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
a first timeout remains failed, and no later control can promote it. At the
decision `0087` qualification, all nine original `t/1545` subtests passed under
the adapter. Its combined focused regression—original doctrine fixture,
Verilator hostile watcher, and shared-engine/adapter watcher—passed at three
files and 19 top-level tests under the repository RAM guard.

T1545 emits each failed checker result as a canonical JSON TAP diagnostic,
prefixed `fixture checker result: `. It preserves separate streams, status,
explanation, exit/signal, timings, bounds, and cleanup evidence even when the
child produced no output. The checker-output assertions still receive only
the original captured streams. A deliberate failed-checker control watches
the complete diagnostic record with empty and nonempty output. This fixes
the loss of failure evidence; it does not identify the cause of an earlier
empty-output failure whose supervisor record was discarded. A later passing
run cannot retroactively diagnose or erase that failed invocation.

Every T1545 checker invocation also emits `fixture checker launch: ` followed
by a separate canonical JSON observation. It retains the supervising test PID,
actual forked child PID, launch count, and flags for observed control EOF,
first output, a native `[task-acceptance] OK:` or `FAIL:` diagnostic, cleanup,
and completion. Test-private wrappers read existing supervisor state; the
checker command, environment, limits, streams, and result schema are unchanged.
A missing flag means that progress was not observed: silence cannot locate a
child before or after main, and EOF alone cannot prove exec. The record is
emitted after return, so its PID is historical evidence, not authority to
signal a process or a live stack sample. Bash's own PID, unmodified checker
output, and an independently held pre-exec child qualify these distinctions.

RAM-guard metric fixtures now use `FSM::Test::RamGuardFixtureRuntime` over the
same shared process mechanism. T1595 preserves its healthy, pressured and
malformed-sample metric assertions. The adapter invokes the exact repository
guard through the selected canonical Bash, prepares its fixed fake inspection
tools with canonical Bash shebangs, and admits only its fixture workspace,
sample basename and closed child scenario. Caller command, path, environment
and limit substitutions cannot redirect those operations. Bash and Perl are
read-only toolchain dependencies; fixture data remains repository-local.

Each invocation has a ten-second wall and one MiB of aggregate capture; sample
admission has a 64-KiB input ceiling. These are fixed safety ceilings, with the
shared engine's existing bounded cleanup grace. The guard's production metrics,
defaults and thresholds are unchanged. Results use
`fsmgen.test.ram_guard_fixture_result.v1`, retaining separate stdout/stderr,
actual exit or signal, timeout, overflow and process-group cleanup. A signal
cannot become exit zero, and incomplete cleanup cannot become success.
There is no retry. The boundary is one process group; this adapter neither
activates the private coordinator nor claims general nested containment.

Run the original metric assertions and the associated hostile controls with:

```bash
bash scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib \
  t/1595-agent-runtime-ram-guard-macos-metric.t \
  t/1811-ram-guard-fixture-runtime.t \
  t/1669-task-acceptance-fixture-runtime.t
```

The tracked controls retain an exact legacy capture counterexample, independently
record producer progress, and qualify concurrent capture, signal truth, input
admission, caller rejection, overflow and bounded TERM/KILL cleanup. Test-private
producer injection exercises the real engine through the adapter's fixed policy;
actual guard fixtures separately qualify metric behavior and startup cleanup.
Source policy re-derives the limits, independent boundary and hostile controls
challenge them, and task-owned tests/book/Git preserve the evidence. This fixes
the fixture harness; it does not identify the historical Darwin startup cause.

The observation qualification exposed fresh timeouts in the unchanged Rust
proxy controls and Verilator Perl fixtures. A live OS sample placed one
Verilator fixture at `_dyld_start` before its body ran. The failed broader run
remains failed. A subsequent authenticated native capture identifies a delayed
fixture waiting inside AppleSystemPolicy; independent `syspolicyd` records name
that exact fixture in an XProtect evaluation and an allowed-script result.
That invocation eventually passes. This narrows its startup wait, but does not
establish the reason for the delay or retroactively explain the original Rust,
Verilator or T1545 failures. HIAL/VIAL `.19.2.3.1.2.2.5.5.2.3.1.2.2.3` owns
causal verification and repair before wire qualification can close.

The approved iTerm2 Developer Tools permission remains enabled. The unchanged
focused bands pass both before and after a fresh shell/Codex launch, but exact
fixture OS records still identify XProtect scanning. Neither control verifies
a timeout repair; original failures and qualification remain open.

The approved private endpoint groundwork is implemented separately in
`FSM::Support::ProcessSupervisor::Endpoint`. It creates an exclusive private
run directory below `.artifacts/tmp/process-coordinator/`, admits the directory
and socket by their filesystem identity, and obtains run/job authority from
the read-only operating-system random source. Tokens stay in memory. Bind and
connect use the local socket name inside the admitted directory, then restore
the caller's directory by handle and its exact signal mask. Long checkout
paths therefore work without placing project data in a system temporary tree.
The caller's environment and umask are preserved. Replaced identities,
unexpected entries and incomplete restoration remain failures; cleanup never
recursively deletes a directory or reclaims an earlier run.

This module is inactive: the production supervisor does not import it, and it
launches no commands. Filesystem admission alone does not authenticate a live
parent. Its private server-side connection mechanism is now implemented in
`FSM::Support::ProcessSupervisor::Connection`. It admits the frame length and
message type before reading a body, preserves exact bytes under partial writes,
and keeps control capacity separate from stream backpressure. A partly sent
frame finishes before another frame can take priority. EOF remains observable
while output is saturated. Fixed framing and stalled-write walls remain clipped
to the original invocation deadline; receiving another byte or queueing more
output cannot renew them. Socket writes restore the caller's native SIGPIPE
handler, mask and flags even after EPIPE or an exception.

The mechanism uses the private Wire limits and performs no sleeping or blocking
I/O in advancement. It neither authenticates a parent nor admits a command.
The inactive `FSM::Support::ProcessSupervisor::Service` now owns finite accepted
connections and validates HELLO against the exact run and a live parent token.
It removes authority before closing affected sockets; root revocation closes
all authority. Parent identities cannot be reused. Separate one-shot connections
may share a live parent, but duplicate HELLO, repeated SPAWN and cancellation
before ACCEPT fail. Connection outcomes occupy bounded slots until consumed;
a full service leaves kernel backlog unaccepted, with no waiting-job queue.

Authentication and admission use fixed Wire windows clipped to the original
run and parent lifetimes. SPAWN timestamps must fit the HELLO window, and the
request's own wall can only shorten its deadline. Receipt and snapshot transfer
both recheck expiry. The service hands exact validated snapshots to its private
owner without launching commands or sending ACCEPT; taking a snapshot does not
renew admission. Job-slot reservation, command ownership, result delivery and
runtime routing remain separate unfinished work. Reported socket-close failure
keeps cleanup failed even when the endpoint files are successfully removed.

These modules remain absent from production runner imports. Startup causal
repair and broader runtime qualification remain open. The filesystem controls
use real Unix socket peers on the current macOS host; foreign-owner/device
cases are model-only and Linux execution is still unqualified. To reproduce
the endpoint and existing wire/mechanism checks:

```bash
bash scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib \
  t/1814-process-coordinator-service.t \
  t/1813-process-coordinator-connection.t \
  t/1812-process-coordinator-endpoint.t \
  t/1669-task-acceptance-fixture-runtime.t
```

For this Darwin startup investigation, an administrator can open a temporary
sampling session from the repository root:

```bash
bash scripts/await_fixture_kernel_samples.sh
```

Enter the administrator password in Terminal and wait for `READY`. The helper
runs as the normal user and authenticates the fixed native `spindump` operation;
tests remain unprivileged. The engineer can submit subsequent capture requests
without another interactive prompt while the session is active.

Each request identifies exact native birth identities. The original T1668 route admits its
direct `orphaning-runtime` child. The T1669 route admits the exact
`rust-tool-resolution` or `legacy-ram-capture` wrapper, or its generated
`rustup`, `legacy-ram-signal` or `legacy-ram-streams` child through that wrapper.
Nested requests include the test's `ancestor_pid`, `ancestor_start_sec` and
`ancestor_start_usec` alongside the existing child and parent identity fields.

Every process must use the selected system Perl as the normal user; commands
and their arguments must match the generating test and a common fixture
workspace. T1668 fixtures stay under `.artifacts/tmp/tests/`; T1669 uses
its explicit `.artifacts/tmp/process-supervisor-tests/` allocator root. Other
allocator purposes and the former wrong T1669 root are rejected. Each inspected
source retains its digest and filesystem identity.
PID reuse, unrelated commands, cross-workspace arguments, indirect sources,
reparenting and identity changes during inspection are rejected before sampling.

Admission is a checked observation, not an atomic kernel handle: inspect the
native report against the retained identities before attributing a wait.
Output stays under `.artifacts/logs/fixture-kernel-capture/`. Ctrl+C or the
session's `STOP` file ends it; expiry and request limits also stop the helper.
It invalidates its authentication timestamp on orderly shutdown. Authentication
refresh is non-interactive and fails closed if access expires or is revoked.
This is a diagnostic handoff, not a startup repair or qualification result.

The T1669 admission controls execute the original allocation call through an
unchanged copy of the repository allocator in an isolated local root. The
allocating Perl process retains ownership until normal cleanup; the sampler
does not supply the expected path. Native held Rust and legacy wrapper/producer
chains then exercise admission, alongside hostile requests, without privileged
sampling. The tracked observer is
`scripts/observe_fixture_startup.py`; inspect its argument contract with:

```bash
python3 -B scripts/observe_fixture_startup.py --help
```

The engineer supplies the exact live test PID and native birth fields, plus
the ready helper's repository-relative session directory. The observer runs
through the RAM guard and attaches to that test; it neither starts nor signals
tests. The caller retains the original guarded invocation's TAP and exit result.
The observer records source digests, copies the exact inspected source bytes,
and retains candidate ancestry and observed main-entry progress under
`.artifacts/logs/t1669-startup-observation/`. Event and source storage have
separate fixed bounds.
An independently bounded `failure.json` retains terminal errors if the event
log fills.

The observer prefers the generated child over a waiting wrapper. A legacy
producer that has written its native main-entry marker is excluded from startup
sampling, so the deliberate blocked-stream control is not mistaken for a
pre-main stall. It submits at most one capture, preserves failures without
retry, and waits for the selected test and observed fixtures to disappear.
It stops the selected helper and verifies authentication invalidation and
helper disappearance. Unobserved descendants remain unknown; neither a quiet
process census nor a passing invocation establishes a causal repair.

If the observer sees no selected fixture, it reports
`no selected fixture was observed; coverage is unestablished` and fails after
helper cleanup. Its settlement record includes `observed_fixture_count`, so an
empty observation cannot silently claim fixture coverage. The original test
result remains separate, including when the test itself passes. Seeing some
fixtures still does not prove complete coverage of every transient process;
keep launch, readiness and candidate evidence.

For a new diagnostic invocation, the fixed caller
`scripts/run_fixture_startup_observation.py` prepares the observer in its own
process and holds its test child behind a pipe until readiness is recorded.
Set `FSMGEN_CAPTURE_SESSION` to the exact repository-relative directory printed
by the authenticated helper's `READY` message, then run:

```bash
bash scripts/run_with_ram_guard.sh -- python3 -B \
  scripts/run_fixture_startup_observation.py --session "$FSMGEN_CAPTURE_SESSION"
```

This command releases only the fixed T1669 invocation. A child-side witness
records consumption of the release token; it proves readiness ordering, while
successful exec and main entry require their own observations. The caller
retains `test.tap`, `test.stderr` and the original native wait status in
`test-result.json` beside the observer evidence. Its whole-test, preparation,
exec-observation, file-size and reap limits are diagnostic bounds; fixture
assertions and individual regression walls are unchanged. It restores normal
exec signal defaults so Python's ignored signals do not leak into the test.
Failed readiness prevents release. Observer failure preserves the original
test result and stops the helper without retrying. Only the owned direct test
child is reaped or signalled by this caller; unobserved descendants remain
unknown. The attach-only command remains available for an already-live test.

The first fixed-launch attempt reproduced the legacy producer failure after
ordered readiness, but the observer admitted no fixtures. Investigation found
an admission defect: T1669 allocates under
`.artifacts/tmp/process-supervisor-tests/`, while the sampler and its controls
assumed `.artifacts/tmp/tests/`. The earlier controlled admission result therefore
did not qualify real T1669 coverage. Task `.3.8.5` repairs that mismatch and
qualifies the actual allocator path independently. The failed original test
remains failed; a fresh authenticated attempt is still needed for native wait
evidence, and no causal repair is claimed.
The selected helper stopped and invalidated authentication.

A later attempt confirmed admission of real Rust and legacy fixtures, but an
exiting wrapper made its command query fail and stopped observation before a
capture. Task `.3.8.6` repairs that race. The observed `ps` no-match exit status
now triggers a fresh native identity check: only confirmed disappearance is
skipped. A live or reused PID retains the query failure; unavailable native
identity, timeouts, unexpected query exits and signals also remain failures. The same disappearance handling applies when a selected
fixture finishes during final target/source validation before request publication.
Observation can then reach another eligible fixture. Once a request is published,
its rejection or capture failure stays failed without retry.

The exit-race controls include a real identified Perl child released and reaped
before its command query, plus separate controls for later-target progression
and genuine inspection errors. The original test's passing result remains
separate from the interrupted observation; it does not repair the historical
startup failure. After the race repair, a complete observed invocation passes
through Rust, signal and streams fixtures without an eligible kernel capture.
The native streams marker excludes its expected body wait. Exact-path XProtect
records accompany the passing invocation; they do not establish the earlier
failure's cause. Recorded process births are independently absent and the
helper has stopped with authentication invalidated. Task `.3.8.7` qualifies
a bounded prospective sequence using one helper lifetime; `.3.8.8` owns its
authenticated execution.

Administrator authentication is for the fixed native kernel-stack capture:
`spindump` rejected the unprivileged probe because root is required. Tests and
the observer run as the normal user. The helper supports repeated requests
within its expiring session, but the single-invocation observer shuts it down
after each attempt. That shutdown requires fresh authentication for a later
attempt; it is separate from the director's authorization to continue work.

For that finite prospective experiment, use the sequence controller with the
same ready session directory:

```bash
bash scripts/run_with_ram_guard.sh -- python3 -B \
  scripts/run_fixture_startup_sequence.py --session "$FSMGEN_CAPTURE_SESSION"
```

The sequence permits at most 20 T1669 invocations.
The fixed budget is 300 seconds for all/legacy and 900 seconds for Rust.
Before each invocation it reserves the complete existing caller allowance and
helper cleanup, so it may stop well before either ceiling. It does not shorten fixture deadlines to use the remaining time;
an observed budget overrun is a diagnostic error. The original test, admission
policy, source retention and native capture command remain unchanged.

To reserve the capture for the failing legacy signal/streams family, select it
explicitly (the standalone observer and single-invocation caller accept the
same option):

```bash
bash scripts/run_with_ram_guard.sh -- python3 -B \
  scripts/run_fixture_startup_sequence.py --session "$FSMGEN_CAPTURE_SESSION" \
  --target-family legacy
```

The default `--target-family all` preserves all-family selection. Legacy mode
still retains observed Rust identities and sources, but only an admitted legacy
wrapper or producer can consume the single capture. Seeing Rust alone fails
selected-family coverage. Readiness and settlement retain the selected family;
the sequence checks matching positive coverage before another invocation.
An entered/drained producer excludes its remaining wrapper too: that progress
is explicitly scoped to the selected producer, not wrapper main entry. Nested
children remain preferred, and source, ancestry and progress are rechecked
before publication. Invalid selectors fail before test release. These controls
qualify selection only; the fixed caller also prepares the live policy retention
described below before each authenticated experiment.

For a longer-lived Rust candidate, use the same fixed sequence with the Rust
selector:

```bash
bash scripts/run_with_ram_guard.sh -- python3 -B \
  scripts/run_fixture_startup_sequence.py --session "$FSMGEN_CAPTURE_SESSION" \
  --target-family rust
```

Rust selection requires 3 seconds from the candidate's first retained
observation before it can consume the single capture. Only admitted Rust
wrappers/proxies qualify; observed legacy sources remain retained, but legacy
activity alone cannot establish Rust coverage. The attached event records the
allowance. All-family and legacy selection keep their existing allowance, and
the original test's deadlines stay fixed.

This interval is a diagnostic choice. An eligible process may still pass;
selection proves neither timeout nor main entry. Independent modeled controls
prove that an earlier departing Rust candidate and a later legacy candidate
cannot spend the request before the later live Rust child. Restoring early
eligibility or removing family filtering fails that oracle. Real native
lifecycle controls verify Rust readiness and matching coverage with capture
eligibility disabled; they do not authenticate sampling.


The sequence owns helper shutdown across iterations. Every iteration must
retain successful original status and positive observed-fixture cleanup before
another test starts. A failed test, observer error, revoked helper or any capture
ends the sequence. A request alone cannot count as a received capture. The
helper stops and invalidates authentication at the end of the complete sequence.
The standalone observer and single-invocation caller retain their own shutdown.
No administrator interaction is needed between iterations of this sequence.

The sequence journal links every iteration's separate TAP, wait status and
observer evidence. Exit zero means a capture was received with successful
original invocation results; exit two means the finite experiment ended without
a capture. Failures remain failures, and neither outcome establishes a causal
repair or runtime qualification. The controlled qualification uses real Perl
invocations and a held unprivileged helper; native ancestry integration is
Darwin-only, and those controls do not exercise administrator authentication.

These temporary Perl programs stand in for tool-resolution failures, signals
and blocked output while regression tests verify process supervision. The
investigation concerns delayed startup before
native main-entry evidence, distinct from a deliberately blocked fixture body.

The first authenticated sequence stops after its first invocation: the legacy
signal and streams producers fail their main-entry assertions, while the Rust
subtest passes. The retained native report captures the Rust proxy waiting
inside `AppleSystemPolicy`. That observation belongs to the Rust fixture; it
does not establish the cause of either legacy failure. Original nonzero status,
source bytes and native ancestry remain retained. The helper stops with
authentication invalidated, and independent checks find every recorded birth
gone. Task `.3.8.9` qualifies selection of the failed legacy family.

A first exact-path query returns that Rust fixture's XProtect result. Later,
the identical query and broader controls cannot retrieve the same record.
[Apple documents normally memory-only Info and Debug logs](https://developer.apple.com/documentation/os/generating-log-messages-from-your-code).
The observed loss of queryability is consistent with those defaults; the
actual subsystem configuration and precise disappearance mechanism remain
unverified. This means an empty retrospective query cannot establish that no
policy activity occurred. Task `.3.8.10` implements prospective retention while
preserving host settings and keeping missing records and collection failures explicit.

The fixed caller and sequence now prepare the bounded policy collector before
test release. The standalone observer remains an attach-only tool. Collection
invokes the read-only native `log stream` with debug-level
NDJSON, restricted to `syspolicyd` messages containing this checkout's exact
fixture allocator prefix. The native command and log service are required OS
dependencies; output and temporary data remain on the repository volume.
Records without that prefix, including token-only or privacy-filtered messages,
are outside assured coverage.

Preparation requires the native filter header within ten seconds. That header
does not acknowledge subscription readiness or complete delivery. The command
has a 240-second timeout, plus observed lifetime checks; each output file has an
inherited 16-MiB limit. Reaching a limit, premature exit even with zero status,
or a failed collection check remains a diagnostic failure. Cleanup allows one
two-second interrupt wait and one two-second kill wait; forced termination stays
failed. These finite allowances do not promise hard real-time OS scheduling.

The collector retains original stream bytes, including the native header and
completion metadata, separately from its status. Status records the exact
child birth, relative output paths, hashes and path-identity checks, monotonic
witnesses, native exit and reaping. It publishes complete status exclusively,
preserving any existing result or foreign pending file. Callers must inspect
retained failures and consume cleanup; a returned status alone is not success.
The native smoke check returns only a header and zero-record completion, with
normal shutdown and independently verified absence. A separate controlled
producer emits a literal record and deletes its source: the retained copy
survives an empty later lookup, and a discarded-record mutation fails that
oracle. This qualifies retention without claiming the missing legacy cause or
complete OS-log delivery.

The caller records policy preparation, checks collector and helper readiness,
then releases the original test. Observation continues checking collection
while following the selected fixtures. After retaining the original TAP and
wait status, the caller closes collection and reloads its published status and
exact output paths, sizes and hashes. The sequence requires that settlement and
rechecks retained bytes before another invocation; successful test output alone
cannot establish diagnostic success.

Collector preparation and cleanup are included in the existing sequence budget
reservation. Original fixture deadlines remain unchanged. Failed preparation
prevents test release; premature collector exit, forced cleanup, output drift
or missing settlement stops the sequence. A full journal preserves its earlier
observation failure without relabeling physically verified process cleanup.
Independent controlled bodies verify collector preparation and aliveness at
entry. The integrated native smoke uses actual read-only OS streams with
controlled fixtures and a modeled unprivileged helper; it does not authenticate
kernel sampling or replay original T1669. All recorded births are independently
absent afterward, and verified evidence copies survive control cleanup.
The authenticated legacy-selection experiment stops on a Rust status mismatch;
its legacy assertions pass and no eligible legacy capture occurs. Live streams
retain exact-path policy events, even though a later retrospective query cannot
retrieve them. The Rust fixture path is rewritten between nonzero and decoy
modes: retained identities show the same inode with different source bytes and
different process births. A later path-only policy event therefore cannot name
the failed process or source version. Task `.3.8.11` retains these boundaries;
`.3.8.12` repairs the discarded Rust failure detail; `.3.8.13` separates
per-mode source identities. Passing legacy checks and retained policy activity
establish neither
a startup repair nor runtime qualification.

When the Rust tool-resolution status assertion mismatches, T1669 now writes a
`Rust tool-resolution result:` TAP diagnostic followed by canonical ASCII JSON.
Its `mode`, `adapter` and `outer` fields preserve the selected proxy mode, full
decoded adapter result and complete outer supervisor result. This retains nested
stage timing, separate streams and cleanup evidence even when streams are empty.
The assertion remains failed; a matching assertion adds no such diagnostic.
The prior invocation's discarded details cannot be recovered by this repair.

Each Rust mode now allocates a distinct repository-local fixture workspace.
The modes keep their original wrapper and proxy bodies, Cargo directory or
symlink behavior, tool basenames, assertions and deadlines. Preparing a later
mode no longer rewrites an earlier mode's source path. The generation control
runs the actual Rust subtest with supervisor calls intercepted: real filesystem
snapshots prove source preservation and allocator cleanup, while the deliberate
shared-workspace control exposes the old overwrite. Native admission controls
also use the actual new allocation call; these checks execute controlled programs
and do not replay the full original regression or authenticate kernel sampling.

Distinct paths remove the observed cross-mode source ambiguity. The authenticated
all-family observation in task `.3.8.14` captures the nonzero Rust proxy waiting
inside AppleSystemPolicy; its original assertions pass. The later decoy times
out during resolution, and the legacy signal fixture also fails. The full decoy
diagnostic survives, and the live policy record names its distinct source path.
That delayed path record cannot supply the failed process's kernel wait stack.

The sequence stops on this original failure. Its collector, original test and
helper are settled; recorded process births and observed fixture workspaces are
independently absent. The early passing candidate consumed the sole capture,
so `.3.8.15` qualifies the longer-lived Rust selector above. Task `.3.8.16`
records passing invocations with positive Rust coverage but no capture. The
sequence ends at its complete-next-invocation reservation boundary, and native
recorded-birth/workspace cleanup is independently verified. This does not erase
the earlier failures. Task `.3.8.17` qualifies the larger fixed Rust budget
above, preserving invocation limits, original deadlines, first-failure stop and
complete cleanup reserves. Independent modeled timing reproduces the prior
early stop and reaches the count ceiling under ordinary completed-invocation
timing with the new budget. Restoring the prior budget fails that oracle;
near-end reservation and overrun controls still stop correctly. Native
controlled bodies verify the selected and sibling budgets and the original
failure stop. These controls do not replay full T1669 or authenticate sampling.
Task `.3.8.18` then captures the decoy Rust proxy during an original failing
invocation. Native ancestry, distinct source bytes, the request and the report's
PID/parent agree. The decoy should print `relative-cargo` and exit so admission
can reject the relative tool identity. Instead, resolution times out with empty
streams. The sample shows that same process inside AppleSystemPolicy. Its full
diagnostic survives, and the policy log later names its exact source. The first
failure stops the sequence. Independent native birth/workspace checks verify
observed cleanup; the helper stops with authentication invalidated.

This closes the missing failed-Rust-sample gap. It does not establish a
continuous wait throughout the deadline, the daemon's internal cause, Rust
main entry or the separately failed legacy signal process's stack. Earlier
passing samples have the same policy frames; those frames cannot predict
failure. Task `.3.2.1` reviews the actual external-launch contracts and selects
unprivileged policy execution context as the next discriminator. Earlier
retained queue/wakeup messages contain only a policy token; the current
fixture-path filter omits them. Task `.3.2.2` qualifies the collector's closed
`execution_context` scope. The default `fixture_path` scope keeps the exact
existing predicate. Context includes those fixture-path messages and messages
from `syspolicyd` in `com.apple.syspolicy.exec`; it can therefore contain other
launches' paths or tokens and stays in private local diagnostic files.

The preparation witness and `fsmgen.fixture_policy_log.v1` result now carry
`scope`. Reload requires the expected scope and exact fixed command, alongside
existing file identity, hash and settled-cleanup checks. A context result cannot
be read as default fixture-only evidence. Historical records without this field
remain inspectable using their committed reader version.

The native macOS predicate engine independently evaluates the actual command
against earlier token-only queue/wakeup records and unrelated controls. The
predecessor and restored old-filter mutation lose the required context rows.
Both scopes exercise the same real-producer output, failure and cleanup
controls; a normal-user OS collector independently verifies context settlement.
Neither test establishes complete event delivery or diagnoses the earlier wait.

For policy execution context without kernel sampling, task `.3.2.3` adds a
separate fixed caller. Run it as the normal user on Darwin:

```bash
bash scripts/run_with_ram_guard.sh -- python3 -B \
  scripts/run_fixture_startup_policy_observation.py
```

It accepts no session, command or numeric override and runs the original T1669
once. It prints its private evidence directory under
`.artifacts/logs/t1669-startup-observation/`. The context collector prepares
before the held test is released. The existing original invocation, output
and cleanup limits apply. No authenticated helper or sampler is started.

The journal records source hashes, readiness, admitted fixtures and settlement;
`test.tap`, `test.stderr`, `test-result.json`, `fixture-result.json` and the policy
files preserve the separate results.
An original nonzero or timeout remains failed even if collection succeeds.
A collection failure likewise fails the diagnostic while retaining the
original result separately. Original, collector and observed-fixture owners are
settled independently before return. Healthy completion claims no qualification.

Task `.3.2.8` adds native ancestry and retained source bytes for the fixtures
actually admitted by the passive census. It attaches after original exec
admission, while the context collector is already prepared. Original-deadline
and collector checks continue between native inspections. No kernel stack is
collected, and unobserved descendants remain unknown. Empty fixture coverage
remains a diagnostic failure even when the original passes.

`fixture-result.json` records settlement of the observed births. The caller
checks its fields against the census and independently queries those births
again before recording `fixtures_settled`. A callee's false cleanup claim
therefore cannot promote success. Original status, collector state and fixture
settlement remain distinct; a result-delivery or journal failure stays failed,
and other owners still receive their cleanup attempt. Controlled Perl producers
read their own admission event before exiting; separate checks verify ancestry,
retained bytes, exact split output and native absence.

The earlier context-only `.3.2.4` observation passes T1669; collection
settles successfully, and the owned test/collector are independently absent.
Exact path/token records connect the logged Rust proxies and legacy producers
to queue, work-start and waiter-wakeup events omitted by the default filter.
This passing run supplies no failed-run diagnosis or repair. Fixture-native
identities and transient source bytes were not collected; Rust mode attribution
is not inferred solely from event order. The task retains exact event timestamps,
source identities and evidence hashes. Task `.3.2.5` queries the earlier failed
interval without another test launch: the query succeeds but returns only
empty terminal metadata. Independently retained live events from that same
interval falsify an inference that no scan occurred. Historical availability
cannot supply the missing queue/start/wakeup context. Task `.3.2.6` selects a
shared passive fixture census: same-invocation native identity and retained
source bytes join the original result to exact policy path/token
events. Task `.3.2.7` qualifies that shared mechanism. It observes fixtures
without signalling them or requiring an authenticated helper. The existing
authenticated observer now reuses its census while retaining capture selection,
final request validation and helper ownership.

Passive scanning, coverage and observed-birth settlement are separate. An
admitted identity remains available for cleanup even if source archival fails;
capture eligibility still starts after successful archival. Strict passive
tracking rejects changed sources or replacement inodes for an already observed
birth. Legacy wrapper progress explicitly describes its selected producer.
Actual held Perl chains independently verify identities, source bytes, progress,
rejection of live-source changes and settlement only after the fixtures exit.
A false-absence mutation fails the cleanup oracle, and a slow-archive control
protects the existing eligibility timing.

The fixed policy-only command now includes this census through `.3.2.8`.
Its healthy result names an `observed_subset`; it claims no complete descendant
coverage. Existing authenticated commands retain their helper requirement.

The single integrated observation in task `.3.2.9` fails at a different
boundary: the asynchronous `control_wait` outer reports pre-exec process-group
containment failure, while Rust and legacy startup assertions pass. That revision's
combined diagnostic does not identify the failed syscall or group-membership
check; no failed outer PID was retained. Task `.3.2.10` owns its unresolved cause.
The observer separately rejects an identity change during legacy-stream cleanup.
Its combined final comparison does not retain the changed process or field,
so its historical transition remains unclassified.
Original, collector and observed-fixture cleanup all settle, with independent
native absence checks and source archive verification. Same-run exact source
bytes identify the passing Rust modes; path/token events join the passing
producers to policy queue/start/wakeup. Neither the clean collector nor those
passing assertions converts the failed original or observer into success.
Startup repair, complete policy delivery and runtime qualification remain open.

Task `.3.2.10.1` makes containment failures precise while retaining the required
successful `setpgid` and actual owned-group check. Diagnostics identify the
child PID and distinguish an operation's return/errno, its exception, and a
group-membership mismatch. The diagnostic shapes include:

```text
process-group containment failed: pid=<pid> operation=setpgid result=undef errno=<errno> (<system text>)
process-group containment failed: pid=<pid> operation=getpgrp result=-1 errno=<errno> (<system text>)
process-group containment failed: pid=<pid> operation=membership expected=<pid> observed=<group>
```

A successful operation can leave stale error text behind. A membership mismatch
therefore reports the returned group instead of borrowing that error. Exceptions
retain their own cause. PID is not native birth identity; the bounded control
pipe, failed exec status and cleanup contract are unchanged. Native session and
false-success controls distinguish causes merged by the older message.
Isolated query faults and a deliberate wrong-label mutation protect the result.

The updated full T1669 qualification still fails both Rust startup modes and
legacy main-entry checks, while the new diagnostic controls and production HDL
contract pass. Available failures remain in the task; that run did not collect
native fixture identities or live policy context. Legacy streams also reveals
a retention gap: missing main entry fails, but its expected timeout assertion
passes, so the full result is omitted. Task `.3.2.12` owns that gap.
The census repair below and complete failure retention precede another
separately selected causal observation. The diagnostic change does not qualify
original runtime behavior or repair startup.


Task `.3.2.11` reproduces and repairs a command-query exit race. An unreaped
Perl child can already be absent from libproc while `ps` succeeds with
`<defunct>`. During final validation this looked like a changed live command.
Every successful command query now requires fresh native presence too.
Only native disappearance follows the existing skip path; permission failures
and observed live birth, parent, ownership, command or source changes still fail.

A real held process family verifies the exit, retained sources and caller-owned
reaping. Removing the presence check restores the original census error.
This is a proved possible cause of the historical combined rejection; that
earlier run did not retain the changed field, so its exact cause stays unknown.
Native absence does not itself prove reaping. Capture admission, cleanup
ownership and deadlines are unchanged. The repair is qualified by the fixture
diagnostic controls; the original startup and containment failures remain open.

Task `.3.2.12` closes the legacy diagnostic gap. Whenever either main-entry
assertion fails, TAP emits `Legacy main-entry result: ` followed by canonical
JSON. It retains `mode`, `fixture` (repository-relative path, byte count and
SHA-256), `marker` (relative path, regular-file observation and exact contents),
and the complete original `result`. A missing marker has null contents; an
empty or unexpected marker retains its actual bytes. For example, a streams
timeout with no marker keeps the failed entry assertion and publishes the result
even though the expected-timeout assertion passes.

The result, assertions, fixture bytes, limits and cleanup behavior stay intact.
Independent TAP controls reject missing or altered retention; actual generated
producer controls preserve TERM and stream/marker behavior. These are diagnostic
controls, not a startup repair. The earlier omitted streams result remains
unavailable. Task `.3.2.13` owns one separately observed original with these
diagnostics and the repaired passive census.

That single `.3.2.13` observation passes the original and census, with exact
source/policy joins and independently settled observed identities. It supplies
a passing comparison, not a startup or containment repair. Earlier failed
results and their missing fields remain unresolved. Task `.3.2.14` admits at
most three further observations, committed individually, to obtain the missing
failed-run context; the first failed or incomplete result stops that campaign.
Its first slot `.3.2.14.1` fails both Rust and both legacy startup controls,
then stops further slots. Complete legacy failure diagnostics now survive the
actual missing-entry case; the census and all observed cleanup settle.
The full policy stream contains four queued scan tokens, with no retained
work-start/wakeup or exact fixture-path link. Path-seeded selection alone would
lose these events. At capture, the producer births supplied only temporal
pairing. The calibrated attribution below resolves that analysis gap; missing
log records still do not prove work never began.

Task `.3.2.15.1` supplies an offline analyzer for these retained records.
Native CoreFoundation string hashing reproduces the path tokens of two
independently linked observations. Calibration against those literal records
then attributes the failed run's four queues to its observed producer paths.
This is scoped hash attribution; collisions or conflicting literal evidence
fail, and a hash never becomes a universal identity guarantee.

Native PST fields accept one through sixteen lowercase hexadecimal digits.
Leading zeroes are optional in captured messages; canonical output always uses
sixteen digits. For example, `499990c7f2beab5` and `0499990c7f2beab5` identify
the same value, and `0` becomes `0000000000000000`. Equivalent spellings in one
record count once. Calibration, token groups, portable associations and diagnostic
projections use the same normalization. Empty, oversized, signed or nonhexadecimal
recognized fields reject; an adjacent valid token cannot hide a malformed field.
Distinct values beside a literal source URL remain ambiguous, and disagreement
with another literal witness or the calibrated native value still fails.
Raw messages and their record hashes are preserved.

For the retained example runs, execute:

```sh
bash scripts/run_with_ram_guard.sh -- python3 -B scripts/analyze_fixture_policy.py \
  .artifacts/logs/t1669-startup-observation/run-6a2c638c7d214c1d8065190d8d7b2ac2 \
  --calibration .artifacts/logs/t1669-startup-observation/run-ae0697059c164ccd9bcbdadf67f6780c \
  --calibration .artifacts/logs/t1669-startup-observation/run-eb32870bc30d496ea5ea589e44a21b19 \
  > .artifacts/logs/policy-attribution.json
```

Use existing retained runs; this command starts no original test or collector.
It verifies the collector manifest and source archives, reads historical capture
roots from the recorded headers as data, and retains all actual events,
unattributed tokens and original/collector results. No old filesystem root is
accessed. Each input is bounded to 16 MiB, each journal/policy set to 4096 records,
and sources to 64 archives of at most 65536 bytes each. Supply one through four
distinct calibration runs, each with at least two unique literal path/token
pairs. Missing, altered or ambiguous evidence fails without an attribution result.

Output `tokens` contains source identity, record indices and observed
`queued`/`started`/`wakeups` counts. The failed example has one queue and no
retained start/wakeup per producer; the passing comparison has all three.
`missing_records` remains unknown. These counts describe retained records,
not proof of whether unlogged work executed.

An auxiliary native C executable timed out, and a C shared-library check later
completed only after a long delay. A user-level sample caught Python loading
that library through dyld `mapSegments`/`fcntl`; no kernel wait chain was captured.
The native interface values did agree. The explicitly selected native build/load
oracle now uses a separate worker and fixed communication deadline; ordinary
offline tests do not implicitly repeat it. Those startup delays and the original
queued-work cause remain owned by `.3.2.15.2`.

Task `.3.2.15.2` identifies the sampled native-library delay more precisely.
The installed dyld image matches the sample's UUID. Its callsite instructions
and independent disassembly show `F_CHECK_LV`, the library-validation check
that precedes loading the library. Public
[dyld source](https://raw.githubusercontent.com/apple-oss-distributions/dyld/dyld-1378/dyld/Loader.cpp)
provides context, but the finding uses the matching installed binary because
the published source version differs. The exact kernel wait and its relationship
to the original script delays remain unknown. The next discriminator is owned
by `.3.2.15.3`.
The fixed `scripts/run_fixture_startup_context_capture.py` caller combines the
original fixture's kernel capture with complete execution-policy context in the
same run. Set `FSMGEN_CAPTURE_SESSION` to the exact repository-relative directory
from the authenticated helper's `READY` message, as described above:

```bash
bash scripts/run_with_ram_guard.sh -- python3 -B \
  scripts/run_fixture_startup_context_capture.py --session "$FSMGEN_CAPTURE_SESSION" \
  --target-family rust
```

This entrypoint fixes `execution_context` internally. It prepares collection
before releasing the unchanged original and verifies the selected scope and
command again from retained results. It exposes no predicate or scope override.
The existing observation caller and sequence retain their `fixture_path` default.
The helper retains its system-Perl admission, fixed capture command and shutdown;
fixture deadlines and Rust candidate selection are unchanged. Full original
failures remain failures even when observation and cleanup succeed.

Task `.3.2.15.3.2` qualifies this composition with controlled held bodies and
scope mutations. The separately admitted original under `.3.2.15.3.3` passes
with complete retained queue/start/wakeup joins for its observed producer paths.
It triggers no kernel capture. The original and observed fixtures are gone,
their observed workspaces are removed, and the helper has stopped and invalidated
authentication. Complete log and descendant coverage remain unproved.
The retained comparison in `.3.2.15.4` finds continued provenance logging in
the failed interval, including on threads that queue the fixture scans, while
later scan-stage records are absent. Identical collector settings and passing
counterexamples narrow the recorded difference; they do not reveal the worker's
state or prove complete delivery. A tracking-violation message also occurs in
passing producer runs and does not distinguish the failure.

The existing `execution_context` predicate selects the execution-policy subsystem
and messages containing a literal fixture-root path. It can omit unrelated
daemon messages. The internal collector now also admits `daemon_context`, whose
fixed predicate is exactly `process == "syspolicyd"`. It selects daemon records
across subsystems even when their messages contain no fixture path, and excludes
other processes. Both earlier predicates and caller defaults are unchanged;
existing time/output limits, normal-user ownership and cleanup still apply.
Inspect the selected predicate without starting a collector:

```bash
python3 -B -c 'import sys; sys.path.insert(0, "scripts"); from pathlib import Path; import fixture_policy_log as p; print(p.command(Path.cwd(), scope="daemon_context")[-1])'
```

Task `.3.2.15.5.1.3.1` qualifies the predicate with native Foundation evaluation
of synthetic records and the collector lifecycle with held producers. It starts
no live system-log stream. The retained analyzer and association seal still
accept only their frozen execution-context capture contract. The disclosure projection below now accepts pinned private snapshots. Daemon
capture-time association production, fixed single-caller and finite-sequence
entrypoints still require qualification before another observation.
Raw daemon output remains private: it can contain unrelated paths, messages and
metadata. The existing original deadlines and helper admission stay fixed.

The path-policy clarification removes the policy blocker in `.3.2.15.5.1`:
project references remain repository-relative, and paths outside the repository
are private unless they identify an explicit public dependency. Other users
must not need objects from the capture machine. The selected design computes
token associations during capture and retains relative source identities;
relocated analysis must not require the private historical checkout root.
The separate association seal/replay boundary below now qualifies calibration,
integrity and the missing later native re-derivation leg. Automatic caller
integration remains pending. Daemon-wide messages can contain unrelated private
paths; the separately qualified projection below omits their raw text. Raw ignored evidence is not automatically safe to share, and a
filtered diagnostic representation must state its omissions. Existing analysis
still reproduces raw retained records and is not a privacy filter. Required
public OS/toolchain dependencies remain explicit. Separate native-library
evidence does not establish the original fixture's kernel cause; the passing
observation does not establish repair or authorize a retry.

The retained analyzer now checks the versioned execution-context command as
well as the output byte manifest. Its native header must contain the matching
process, fixture prefix and subsystem predicate; the OS-rendered
`composedMessage` spelling is accepted for `eventMessage`. Missing command
metadata, changed options or a widened predicate fail analysis, even when the
recorded output hash matches. These consistency checks apply to the target and
each calibration run. Valid failure results and all retained records remain
available; command consistency does not establish complete log delivery or
privacy safety. The separate diagnostic projection below checks pinned inputs and limits disclosure.

`scripts/fixture_policy_associations.py` seals settled execution-context evidence
while its original checkout root is still available. It checks independent
literal path/token calibration, source archives and collector command/header
identity, rejects collisions and conflicting literal evidence, and rechecks
the input snapshot before returning. Sealing an old capture now does not
backdate the seal. It starts no original fixture or collector.

For the same retained failed example and a separately linked calibration:

```bash
FSMGEN_ASSOCIATION_SHA=$(python3 -B scripts/fixture_policy_associations.py seal \
  .artifacts/logs/t1669-startup-observation/run-6a2c638c7d214c1d8065190d8d7b2ac2 \
  --calibration .artifacts/logs/t1669-startup-observation/run-ae0697059c164ccd9bcbdadf67f6780c \
  --output .artifacts/logs/policy-associations.json)
python3 -B scripts/fixture_policy_associations.py replay \
  .artifacts/logs/policy-associations.json --sha256 "$FSMGEN_ASSOCIATION_SHA" \
  --archives .artifacts/logs/t1669-startup-observation/run-6a2c638c7d214c1d8065190d8d7b2ac2
```

Retain the printed digest separately with the trusted capture record. For
relocation, copy the manifest and its target sources' content-addressed
`.source` archives into the receiving repository's `.artifacts/logs/` tree,
then pass their new local locations and that retained digest to `replay`.
Neither old headers, calibration files, original source paths nor CoreFoundation
are needed for replay. Source bytes can contain private data; these local
archives are not yet a qualified shareable diagnostic bundle.

The closed manifest records relative source identities, calibrated tokens,
private-input and producer digests, and an ordered token/phase projection with
each raw event's canonical digest. It omits raw messages and the private root.
The fixed manifest byte, path and token-cardinality bounds are additional
admission ceilings; existing source, event and calibration limits still apply.
Replay verifies the supplied digest, schema and every relocated target archive,
then reconstructs token joins, record indices and retained queue/start/wakeup
counts, including unattributed tokens. It does not replay original test outcomes
or claim complete raw-record equivalence.

Without the private root, later native hash re-derivation is unavailable.
The seal retains calibration witnesses and pins their provenance; the supplied
digest detects changed mappings against that anchor but is not authentication.
Replacing both the manifest and its trusted digest is a different evidence
claim. Missing records and complete delivery retain their explicit unknown and
unproved states. Automatic daemon-context sealing and caller integration still
require qualification before the next observation.


`scripts/fixture_policy_diagnostics.py` exports a closed diagnostic report from
a separately pinned association manifest and matching private snapshot files.
It rehashes the snapshot, verifies the reviewed command/header and every ordered
event projection, then rechecks the input bytes. It does not read source bodies,
load native hashing or start collection. Using the manifest and digest above:

```bash
FSMGEN_DIAGNOSTIC_SHA=$(python3 -B scripts/fixture_policy_diagnostics.py export \
  .artifacts/logs/policy-associations.json --sha256 "$FSMGEN_ASSOCIATION_SHA" \
  --private-inputs .artifacts/logs/t1669-startup-observation/run-6a2c638c7d214c1d8065190d8d7b2ac2 \
  --output .artifacts/logs/policy-diagnostic.json)
python3 -B scripts/fixture_policy_diagnostics.py read \
  .artifacts/logs/policy-diagnostic.json --sha256 "$FSMGEN_DIAGNOSTIC_SHA"
```

Keep the printed report digest with the trusted export record. The receiving
checkout needs only the canonical report file and that separately held digest.
Neither private snapshots, source archives nor historical roots are needed to
read it. Publication is exclusive and private; an existing output is not replaced.
Changing either report or manifest bytes against its retained anchor rejects;
replacing both bytes and the trusted anchor is not authentication.

The report retains relative source identities, opaque tokens/digests, ordered
phase projections, admitted numeric process/thread/activity/Mach fields, and
validated policy timestamps. Native adjacent-offset and spaced-offset timestamp
spellings are preserved. Subsystems become fixed execution-policy/other/missing
classes; arbitrary subsystem names and unknown context values are omitted or
represented as unknown. It retains typed original exit/timeout and selected
collector failure/cleanup flags. A failed original stays failed, and overall
qualification is always `not_claimed`. Recorded numeric IDs are not native birth
identities; no cross-run identity or cross-clock conversion is inferred.

Raw messages, metadata, errors and source bodies are excluded. The report states
those omissions, counts excluded metadata records, and does not claim raw-record
equivalence, complete delivery, independent source-body verification or observer
success. The source/event bounds and the association manifest's byte ceiling also
bound report admission; oversized or malformed reports fail without successful
output. CLI failures disclose a fixed message, without private arguments or
exception details. Source archives and raw captures remain private even when a
report is shareable.

The internal daemon-capture sealer is qualified under `.3.2.15.5.1.4.1`.
Before launching a daemon collector, the producer binds the canonical checkout
root to a private digest. Settled capture loading requires that digest to match
the current checkout, the exact daemon command/header, intact source archives
and unchanged input snapshots. Separate literal calibration still checks the
native path hash; absent sources or calibration cannot produce invented joins.
The root digest detects inconsistent capture location; it is not authentication.
It is omitted from the shareable manifest and report, whose separately pinned
replay needs no original root. A moved raw capture cannot be resealed as if it
originated in the receiving checkout; relocate its already sealed associations.

Calibration-only preflight is available through `calibration_snapshot` under
`.3.2.15.5.1.4.2.1`. It accepts bounded, distinct local calibration runs and uses
the same literal-pair/native-hash and closed-identity checks as sealing. It
rechecks input and source-archive snapshots, requires no target capture and
starts no observation. Its returned relative identities are the admission
snapshot that the daemon caller compares exactly against its final archive.
A later byte change invalidates that comparison even if the literal path/token
pairs still match. Preflight does not qualify any original result or promise
that a future target will contain enough observed sources.

The legacy offline publication boundary remains qualified under `.3.2.15.5.1.4.2.2.1`.
It compares the final seal's calibration identities with the exact preflight
snapshot before writing, then retains these files in the capture directory:

| File | What it binds |
| --- | --- |
| `policy-associations.json` | Calibrated relative sources and ordered event projections |
| `policy-diagnostic.json` | Admitted context and typed outcomes, linked to that manifest |
| `policy-publication.json` | Both artifact byte identities and the admitted calibration digest |

Each write is exclusive. A known destination collision prevents any new write;
a later failure can leave a complete earlier artifact. The publisher verifies
the pair before attempting the receipt, so partial publication does not receive
a receipt. Preserve partial evidence rather than overwriting it on a retry.
Pin the returned receipt digest separately. `fixture_policy_publication.consume`
checks the canonical receipt, both artifact hashes and their calibration,
source, input and ordered-record linkage. A receiving checkout needs only the
receipt and public pair at their relative paths; no original root, private
capture, source body or native ABI is read. Source bodies are verified during
publication, not during receipt consumption.

A valid receipt establishes consistency of the pinned artifacts. It does not
authenticate them, qualify the original/observer, or establish complete coverage.
An original failure remains failed in the report even when publication succeeds.
The legacy publisher itself starts no observation. The fixed combined caller
now uses the archive successor under `.3.2.15.7.2.4`; it does not produce or
fall back to the legacy pair. With an already admitted helper and local
calibration inputs, its command is:

```sh
scripts/run_with_ram_guard.sh -- python3 -B scripts/run_fixture_startup_daemon_capture.py \
  --session "$FSMGEN_CAPTURE_SESSION" --target-family rust \
  --calibration "$FSMGEN_POLICY_CALIBRATION_A" \
  --calibration "$FSMGEN_POLICY_CALIBRATION_B"
```

The session and calibration values are repository-relative paths. This command
starts one original test and the fixed daemon collector; use it only after
helper readiness and the owning observation task's admission. It starts no
authentication and accepts no predicate, scope, count or deadline override.
Preflight precedes collector preparation and original release. The existing
combined launcher retains its original argv, fixture census, target-family
selection, deadlines and cleanup. After settlement, the caller attempts portable
publication even if the original failed. It retains both failures privately
when observation and publication fail, and prints only the relative evidence
directory and any independently revalidated archive index/digest. Pin that digest
separately. Public error text is fixed; an archive does not change a failed exit
status. Cancellation remains interrupted even if evidence closing also fails.

Standalone use owns helper shutdown, including rejected calibration or evidence
setup. Internal sequence use leaves the helper with its controller while each
invocation settles its original, collector and observed fixtures. Held bodies
check preparation order and native cleanup; calibration in those controls is
modeled, and live system-log launches are trapped. These controls are not a new
original observation, authenticated capture or proof of complete daemon delivery.
The shared finite controller supports calibrated daemon iterations under
`.3.2.15.5.2.1`; `.15.7.2.4` integrates the archive successor. Its fixed CLI is:

```sh
scripts/run_with_ram_guard.sh -- python3 -B scripts/run_fixture_startup_daemon_sequence.py \
  --session "$FSMGEN_CAPTURE_SESSION" --target-family rust \
  --calibration "$FSMGEN_POLICY_CALIBRATION_A" \
  --calibration "$FSMGEN_POLICY_CALIBRATION_B"
```

Use repository-relative session/calibration paths and an already ready helper.
The command accepts only session, repeated calibration and target-family flags;
abbreviations and predicate/scope/count/deadline overrides reject. The existing
fixture-path sequence command keeps its original defaults. The owning observation
task must admit a prospective campaign separately; qualifying this CLI runs none.
The first admitted daemon campaign `.3.2.15.5.3` is exhausted. Both original
invocations pass; the first publishes a checked receipt. The second retains
its complete raw evidence but publication fails on a valid PST token printed
without its leading zero: `499990c7f2beab5`, native value `0499990c7f2beab5`.
The then-current parser required sixteen digits. Task `.3.2.15.5.4.1` repairs
normalization; `.3.2.15.5.4.2` completes the retained-evidence audit and offline
publication recovery.

Sequence status is failure; no third invocation or kernel capture occurs.
Both collectors settle successfully. All recorded native births and observed
fixture workspaces are independently absent, and helper authentication is
invalidated. The passing originals do not repair the earlier startup failures.
The first run's receipt remains in its private sequence journal even though
this later failure prevents normal completion output.

The retained audit finds short spellings in four captures. Earlier calibrated
failed/passing analyses and the first daemon receipt are unchanged. The second
daemon run now has a separately produced recovery manifest, report and receipt;
all original inputs and its failure record remain unchanged. Its twelve formerly
unrecognized records join the decoy source, including one queue, start and
wakeup. The corrected receipt digest is
`aff1e18a4b10591784d7c25dbd8b40eeca0f5ae06b3ece00f7d6d6e972fc5c6f`.
Recovery verifies artifact consistency and does not change the failed sequence
outcome or establish startup repair. Older short-token records retain their
original source/stack limitations.

The corrected campaign `.3.2.15.6` is also exhausted. Its first original fails:
`proxy_nonzero` times out under the unchanged ten-second tool-resolution wall
instead of returning the expected nonzero failure. The helper captures that
exact Rust proxy; receiving its sample does not turn the original into success.
All recorded native births and observed workspaces are independently absent,
and helper authentication is invalidated.

Portable publication rejects this capture's combined daemon-event count:
8,492 log events plus 55 metadata records exceed the analyzer's unchanged
4,096-record bound. The collector retains the complete 7,467,562-byte stream
and settles without reported failure; this does not prove complete log delivery.
Raw evidence and both failures remain authoritative. Task `.3.2.15.7` owns a
bounded diagnostic repair and offline analysis of this failed-target capture;
no further campaign is selected. Startup qualification remains open.

The full retained stream contains the failed proxy's queue, start and wakeup.
Its start and wakeup lie beyond the old record prefix; truncation would produce
a misleading queued-only projection. The full diagnostic projection also
exceeds the old report byte bound, so increasing only the loader count would
leave publication broken. The selected repair uses an explicitly versioned
archive index and bounded ordered pages, retaining metadata hashes and positions
as well as every log projection. Existing formats remain unchanged. Schema,
producer, publication and fixed-caller integration have separate task leaves.
The archive schema and portable consumer are implemented under `.15.7.2.1`.
The consumer checks a separately pinned index and only its consecutive public
pages, preserving metadata positions, admitted context and failed outcomes.
It rejects changed bytes, gaps, wrong counts, foreign bindings, indirect files
and a page root on another volume. It does not read private capture inputs or
native state. The calibrated builder is implemented under `.15.7.2.2`: it
preserves every nonblank retained row, packs whole entries under both page
bounds, and rechecks raw inputs, source archives, calibration and producer bytes
before returning the index and page bytes. It performs no publication. The
retained failed capture reconstructs completely in memory, including late
progress and metadata, with its original failure intact. Exclusive publication
is implemented under `.15.7.2.3.2`; `.15.7.2.4` integrates the fixed callers.
The retained failed capture now has a separately recovered archive under
`.15.7.3.1`. Its index digest is
`686c1ecc7e5ff2e1d1a9cb350c206007fcadf7af2ef5cd1ef3bdc4a919d2ab53`.
Independent reconstruction preserves every retained row, metadata position and
late failed-target queue/start/wakeup record. Replay from public files alone
passes; changed or missing pages and a forged index reject. Original inputs,
source archives, the kernel sample and prior failure records are unchanged.
Recovery establishes artifact consistency while the original and campaign
remain failed. The `.15.7.3.2` audit matches the daemon image to the retained
logs and verifies that its scan work uses a serial queue. A preceding scan
for another project spans the failed fixture's recorded queue wait; the
fixture scan starts just after that scan finishes. This supports queue
contention, with exact timings and instruction evidence in the task tree.
It does not identify the native client request or explain the preceding
scan's duration. The sampled user address is outside the UUID-matched Perl
image, so it cannot establish a Perl function or inherit an earlier dyld
callsite attribution. The installed policy images also fail the sample's
architecture/UUID match. Startup qualification remains open; `.15.7.3.3`
owns a repository-local fixture repair selection preserving native failure
assertions and fixed bounds.

Shared evidence publication now anchors file creation, linking and temporary
cleanup to open directory descriptors. A controlled directory-replacement test
exposed an earlier writer returning the expected digest for replacement bytes;
it also removed a foreign temporary name. The repaired writer detects observed
directory, temporary-inode and published-byte changes, preserves existing final
files, and retains the primary failure if cleanup also fails. Complete earlier
artifacts remain on failure. These checks do not prevent arbitrary same-user
mutation after observation or make several files one atomic transaction;
consumers must still verify their separately retained digest. This repair is
shared by existing formats.

The archive library's `publish(target, calibrations, admitted)` takes the run,
separate calibration runs and their prospectively retained calibration snapshot.
It checks the complete prepared page set and rejects existing files anywhere in
the fixed archive namespace, including pages outside the new index's range.
It preserves one directory identity across publication, writes complete pages
exclusively, and consumes their actual bytes before writing `policy-archive.json`
last. It then rereads that index and consumes every page again. The return value
contains `index` and its `sha256`; preserve that digest separately. A later
error leaves earlier complete files and the failed outcome intact. An index's
presence alone does not prove success: its pinned consumption must pass.
There is no overwrite, automatic resume or compatibility alias to the older
manifest/report receipt. Portable `consume(index_bytes, sha256, root)` returns
the admitted index and ordered pages without private inputs or native APIs.

The archive requires at least one retained row, which can be metadata. A
header-only stream causes publication failure even when the original exits
successfully. The caller preserves that successful original result separately,
settles owned processes, and reports the publication failure; it never invents
a record or falls back to the older format. The legacy API retains its existing
empty-stream behavior. A valid archive may preserve a failed original, but a
completed sequence iteration requires exact successful original and collector
flags plus the admitted calibration and the current iteration's run.

For portable review, copy the index and all named pages at their relative paths,
then consume the index with its separately retained digest from the repo root:

```sh
scripts/run_with_ram_guard.sh -- python3 -B -c '
import json, sys
from pathlib import Path
sys.path.insert(0, "scripts")
import fixture_policy_archive as archive
root = Path.cwd()
raw = archive.analysis.read_local(root / sys.argv[1], root, archive.MAX_INDEX_BYTES)
checked = archive.consume(raw, sys.argv[2], root)
print(json.dumps(checked["index"]["context"]["original"], sort_keys=True))
' "$FSMGEN_POLICY_ARCHIVE_INDEX" "$FSMGEN_POLICY_ARCHIVE_SHA256"
```

This reads public files only. The output is retained original status, not a new
execution or a startup qualification. A changed page or index rejects.

Standard output begins with the relative sequence journal directory. On normal
completion it emits each validated `{"index": ..., "sha256": ...}` as a separate
JSON line, then
a closed JSON outcome. That outcome contains only reason, completed invocation
count, capture-received flag, `qualification: "not_claimed"` and
`unobserved_descendants: "unknown"`. All indexes are checked before any of that
completion output is printed: duplicate iterations, changed calibration, forged
counts/reasons/fields and failed original/collector outcomes reject. Preserve
index digests separately from their artifacts. The sequence journal stores each
index's schema, relative path and digest in an `iteration_publication` event; it
does not embed the full index. This keeps the existing journal event bound even
when a valid index is larger than one event.

| Exit | Meaning |
| --- | --- |
| `0` | A capture was received and the sequence settled |
| `2` | No capture; invocation limit or full-reserve exhaustion ended the sequence |
| `1` | Operational failure; consult retained evidence |
| `130` | Interrupted, including interruption followed by cleanup failure |

No-capture status emits no failure message. Failure output is fixed text without
private arguments/errors; a completed archive may still be emitted for a failed
original, whose failed status remains unchanged. Helper cleanup errors retain
interruption and any already completed archive. Failure before journal setup
still closes the admitted helper. A valid archive proves artifact consistency,
not original/observer qualification or complete descendant/log coverage.

Daemon sequencing pins one initial calibration identity and rechecks it before
each invocation. Because preflight consumes time, it checks helper readiness and
the complete existing launch/cleanup reserve again after preflight. If that
reserve no longer fits, it records a deferred iteration without launching a
collector or original. The existing Rust budget, invocation limit and original
deadline remain unchanged; publication time also counts toward the sequence
budget. A passing original cannot hide a budget overrun or publication failure.

Before another invocation, the controller independently reloads settled original,
selected-fixture and collector evidence with the exact daemon scope. It reads
the actual receipt file using the returned digest, verifies the public pair and
requires the current iteration path, initial calibration and original outcome
to agree. A previous valid receipt cannot stand in for the current invocation.
Each receipt has its own bounded journal event; the controller does not combine
all receipts into a potentially oversized event. First failure or received
capture still stops the sequence, and only the controller stops its helper.
Tests use actual held bodies and an unprivileged held helper, with calibration,
controller-clock changes and capture delivery explicitly modeled. They establish
controller behavior, not an authenticated sample or startup repair.

The standalone sealing CLI keeps its execution-context contract. The internal
`seal_daemon_capture` path supports the fixed caller. Its native calibration check uses a
clearly modeled daemon snapshot made from retained evidence, preserving every
original input. That check proves calibrated sealing and portable consumption,
not a new daemon capture or complete daemon-record delivery. Retained commands
support checkout paths containing spaces, quotes, backslashes and Unicode under
`.3.2.15.5.1.3.3`. The collector replaces only the exact JSON-quoted fixture-prefix
literal in its captured argv with the canonical `<repo>` literal; all other
command bytes remain unchanged. The reader constructs its canonical expectation
without repeating that normalization. Predicate widening, changed timeout
arguments and malformed unescaped paths remain visible and are rejected.
The older literal-root replacement both rejected valid escaped roots and could
make malformed unescaped predicates appear canonical; these are retained-metadata
defects, not evidence that the OS executed a different command. Held collectors
and the frozen offline command/header reader exercise the repaired boundary;
no live log collection is needed for those controls.
Offline disclosure controls pass under `.3.2.15.5.1.3.2.1`. Its broader band
exposed a timeout-control scope defect, repaired under `.3.2.15.5.1.3.2.2`:
the leader-only timeout test also started descendants that the passive census
might not admit before the deadline. The leader control now isolates its owned
child, retaining timeout, forced termination and consumed-wait assertions.
A separate controlled non-admission test observes live fixture births after
leader reaping, requires the census to report unobserved descendants as unknown,
then releases the fixtures through their own protocol and checks every recorded
birth has disappeared. Production signal ownership and deadlines are unchanged.
Future cleanup assertion failures retain the reported role and native identity.
The earlier failure remains recorded; its exact native identity was lost when
the temporary test workspace was removed, so the controlled reproduction cannot
recover that historical identity or establish complete descendant coverage.


A bounded historical query cannot recover even the failed run's already retained
queue events. Empty history therefore cannot establish that a scan never ran.
Preserve live records and the missing-delivery limitation.

Timestamp units do not establish a shared clock origin. Here Python's
`time.monotonic_ns()` uses Mach absolute time, while the Perl supervisor uses
POSIX `CLOCK_MONOTONIC`. Native brackets confirm the clocks differ. Inspect
the current APIs without launching a fixture:

```sh
python3 -B -c 'import time; print(time.get_clock_info("monotonic")); print(time.monotonic_ns(), time.clock_gettime_ns(time.CLOCK_MONOTONIC))'
```

Those sequential readings are diagnostic, not a historical conversion factor.
Native process birth is a calendar creation time preserved across exec; it is
not proof of fixture main entry. Use within-domain durations and explicit
entry witnesses; do not subtract arbitrary Python, Perl and policy timestamps.



Capture requests and helper results are published only after their complete
JSON has been written, so a concurrent reader cannot consume a partial record.
The hosted doctrine job discovers the fixture Python controls. Launcher
controls exercise real pipes, exec and wait; birth metadata is native on Darwin
and modeled on other platforms. Off-Darwin caller controls use real reported
child PIDs/parents with modeled birth, executable and command inspection.
Separate libproc controls are explicitly
Darwin-only. Legacy-specific authenticated capture and causal repair remain open
investigation steps. Run the focused unprivileged controls with:

```bash
bash scripts/run_with_ram_guard.sh -- python3 -B -m unittest discover \
  -s t/python -p 'test_fixture_*.py' -v
```

Default discovery excludes live system-log collection. Its native collector
controls require `FSMGEN_LIVE_POLICY_COLLECTOR_ORACLE=1`, checked again before
native admission; set this only when the owning task explicitly permits live
collection. Native Foundation predicate checks still evaluate synthetic records,
and held-child lifecycle controls still use controlled producers.

The earlier attribution and association qualification bands inadvertently ran
the previously ungated native collector controls: the direct collector and the policy-only
caller with a synthetic body. Both passed collector-reap checks; the direct
control also checked native disappearance. Those executions violated the
selected no-live-collector scope. Task
`.3.2.15.5.1.2.2` repairs the selection boundary; the historical audit in
`.3.2.15.5.1.2.3` identifies the affected logs and their owning restrictions.
It preserves earlier selected live qualification and regression outcomes
separately, including failed suites. None of the violating bands is treated as
collector-free. Their temporary raw streams and exact native births were removed
after cleanup. Retained log copies do not establish a unique execution count;
missing logs or other output formats remain outside this audit.

The shared adapter's quantitative statements above have three independent legs:

- Re-derive the direct callsites and selected constants from `t/1545`, both
  policy adapters, and the shared engine, then run the original doctrine test.
- Falsify the interpreter choice with the retained macOS `/bin/bash` replay,
  and exercise rejected paths/subcommands, nonzero exit, plus a TERM-resistant
  descendant in the focused watcher.
- Keep the result durable through decision `0087`, the owning task-tree,
  Knowledge Map card `test-subprocess-policy-adapters`, the focused watcher,
  and the work-unit Git commit.

The shared supervisor's cleanup proof covers its own process group. A bounded
nested-supervisor probe found an inner child still alive in a separate group
after the outer timeout reported its own group gone. That escaped group was
explicitly terminated and its disappearance verified. Whole nested-subtree
cleanup is therefore an open limitation; the neutral-verifier integration is
blocked on the owned containment repair in HIAL/VIAL task
`.19.2.3.1.2.2.5.5`. Do not treat an outer group's disappearance as proof that
independently supervised inner groups have stopped.

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

Content addressing alone does not make a resumed terminal payload
authoritative: an attacker could replace an object, repair the state summaries,
and rehash the complete chain. Resume therefore also requires every successor's
object descriptors to preserve the complete ordered predecessor prefix and
compares the sealed version bytes with the selected qualified Verilator
identity. Once runtime output exists, it re-extracts and validates the trace
from the sealed raw transcript and process result. It then regenerates the
normalized result and rebuilds either the complete public assembly or the
compact measurement descriptor. The stored trace, result, and assembly bytes
must equal those reconstructed values exactly. A canonical but foreign trace,
passing result, assembly, version, or earlier object history consequently fails
state admission before public or measurement finalization.

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
prove -Iperl t/1734-vial-verilator-terminal-resume-admission.t
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
