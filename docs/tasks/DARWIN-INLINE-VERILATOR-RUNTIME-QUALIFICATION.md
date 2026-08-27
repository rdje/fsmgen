# DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION: Bound and qualify legacy inline Verilator runtimes

## Metadata

- Tree ID: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION`
- Status: `active`
- Roadmap lane: `verification infrastructure / runtime qualification`
- Created: `2026-08-26`
- Last updated: `2026-08-27`
- Owner: repo-local workflow

## Goal

Make every tracked test-side Verilator executable launch deterministic,
deadline-bounded, and explicitly qualified on Darwin without weakening runtime
failure truth or changing product runtime behavior.

## Background / Finding

The required pre-push complete-CI gate passed through `t/1514` before
`t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t` blocked inside its
generated Verilator executable. The test invokes that executable directly with
`IPC::Cmd::run(command => [$binary])`, outside the shared lifecycle and without
a timeout. A live one-second macOS sample placed 804/804 main-thread frames at
`_dyld_start`; the process had a 96-KiB footprint and no image map. This is the
same retained pre-main host failure class governed by decisions `0084` and
`0085`, but `t/1515` is not covered by the explicit `t/1558` Darwin boundary
and cannot terminate itself. The exact pre-push frontier is green through
`t/1514`; `t/1515` is the first unresolved file and `t/1516` onward is untested
by that run.

## Non-Goals

- Do not retry a failed executable, relabel a timeout as passing, widen the
  product Runner deadline, or change generated RTL/runtime semantics.
- Do not disable macOS security, alter signatures or xattrs, kill unrelated
  workloads, or special-case only `t/1515` if the same unsafe launch pattern
  exists elsewhere.
- Do not make non-Darwin runtime integration opt-in merely because Darwin has
  a retained host-loader qualification boundary.
- Do not claim that `_dyld_start` identifies a deterministic operating-system
  root cause; it identifies the reached pre-main boundary.

## Acceptance Criteria

- Every tracked test-side Verilator compile/run callsite is inventoried by
  source path, helper, deadline, platform guard, cleanup, and failure behavior.
- One shared test-infrastructure contract owns executable supervision,
  timeout/failure truth, process-tree cleanup, and Darwin qualification; direct
  unbounded launches are mechanically rejected or absent.
- Standard Darwin CI cannot enter a known host-sensitive executable path
  without an explicit opt-in qualification guard, while non-Darwin behavior
  and explicit Darwin first-failure truth remain unchanged.
- Focused negative tests prove deadline termination, no retry, stable failure,
  cleanup, guard ordering before tool discovery, and no environment leakage.
- The complete CI resumes at `t/1515`, reaches the lexical tail, and combines
  with the already-green prefix before the due push and hosted qualification.
- Roadmap/task status, mdBook, Knowledge Map, decision records, claim evidence,
  and bounded Memory remain synchronized where their contracts change.

## Task Tree

- ID: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION`
  Status: `active`
  Goal: `Bound and explicitly qualify every legacy test-side Verilator runtime launch.`
  Children: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.1, DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.2, DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3`

- ID: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.1`
  Status: `done`
  Goal: `Audit all tracked test-side Verilator compile/run paths and select one durable supervision and Darwin-qualification contract.`
  Acceptance: `Enumerate every direct and helper-mediated executable launch, prove the exact t/1515 pre-main/no-timeout mechanism and affected class, migrate and remove the exact off-volume sample residue, select central helper ownership plus timeout/guard/cleanup/failure semantics, and record the decision, Knowledge Map fact, mdBook boundary, and exact implementation migration set without changing behavior.`
  Verification: `Activation preserves the exact green-through-t1514/unbounded-t1515 frontier, records the 804/804 _dyld_start and no-timeout mechanism, and completes copy/size/hash/use/delete/residue-census handling for the 1,072-byte off-volume sample. The tracked-source census then identifies 37 compile and 37 generated-runtime callsites across 34 affected legacy files: 36 runtime callsites are unbounded and the t1559 baseline has an alarm timeout without verified process-group cleanup. Independent compile/run file-set comparison agrees exactly. Decision 0086 selects one test-only supervisor, fixed 10/120/30-second and 65,536/8,388,608/67,108,864-byte stage bounds, a fail-closed pre-discovery Darwin guard, whole-group cleanup, closed evidence, and a mechanical direct-launch watcher without changing the existing VIAL lifecycle.`
  Commit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.1: activate legacy inline runtime audit; DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.1: select bounded test runtime supervision`

- ID: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.2`
  Status: `done`
  Goal: `Implement the selected central runtime supervision and migrate every affected tracked callsite.`
  Acceptance: `Use only the committed .1 selection; add one readable caller-safe helper, stable bounded diagnostics, process-tree cleanup, explicit Darwin opt-in before tool discovery, unchanged non-Darwin execution, exact environment restoration, hostile-input tests, and mechanical detection of newly introduced unbounded direct launches.`
  Verification: `FSM::Test::VerilatorRuntime implements sealed version/compile/runtime entrypoints, repository-root cwd and same-volume path admission, scalar argv, separate aggregate-bounded stdout/stderr, close-on-exec handoff evidence, monotonic timestamps, one process group, first-failure-preserving statuses, and verified TERM/KILL cleanup. A closed tracked manifest independently owns the exact 34-file/37-compile/37-runtime census. Every listed callsite uses the helper; no direct command => [$binary] launch remains, every affected file activates project-local temp storage and the pre-discovery Darwin guard, t1559 uses the sealed version path, and t1542's Icarus/vvp path remains separate. The focused watcher passes at Files=1/Tests=6, including guard ordering, environment preservation, invalid/symlink/exec/nonzero/signal failures, capture overflow, immediate surviving-descendant cleanup, a real ten-second TERM-resistant timeout, and the complete source census. All 34 migrated files compile syntactically; their ordinary Darwin run skips before discovery with the exact guard. An explicitly qualified t1515 run passes at Files=1/Tests=3 under the bounded helper.`
  Commit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.2: bound legacy Verilator test processes`

- ID: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3`
  Status: `active`
  Goal: `Qualify the migrated runtime surface, resume complete CI, and close the due push follow-up.`
  Children: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.1, DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2`
  Acceptance: `Pass focused helper/callsite/runtime tests, resume the RAM-guarded complete-CI suffix at t/1515 through the lexical tail, validate the mdBook build and repository locality/cleanup, push the exact clean revision at the standing cadence, and consume every expected hosted workflow/job to terminal success with durable URLs and conclusions.`
  Verification: `pending`
  Commit: `pending`

- ID: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.1`
  Status: `done`
  Goal: `Diagnose and bound the newly exposed task-acceptance fixture subprocess before resuming complete CI.`
  Acceptance: `Preserve the interrupted first-failure truth; migrate and remove the exact off-volume sample with verified identity and residue census; audit the t1545 command surface and history; select and implement bounded shell-free supervision with process-tree cleanup and no retry; prove hostile pre-exec timeout/cleanup behavior and unchanged fixture results; synchronize durable evidence.`
  Verification: `Decision 0087 extracts one private process mechanism behind sealed policy adapters. TaskAcceptanceFixtureRuntime restricts callers to the project-local fixture subtree and exact fixture-owned Git argument shapes, seals the canonical caller-selected Git and Bash executables at load time, and applies fixed 10-second plus 1,048,576/4,194,304-byte stage contracts. The original nine-subtest t1545 replay, same six-subtest Verilator watcher, and new four-subtest hostile/ownership watcher pass together under the RAM guard at Files=3/Tests=19; the watchers prove canonical-interpreter fixture execution, TERM/KILL descendant cleanup, and exactly two low-level policy owners. The failed /bin/bash 3.2 and generated-fixture env-handoff falsifications remain recorded, and no retry exists inside the adapter or tests.`
  Commit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.1: bound task-acceptance fixture processes`

- ID: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2`
  Status: `active`
  Goal: `Resume the complete-CI suffix after t1545 repair, then push and consume hosted qualification.`
  Children: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.1, DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2`
  Acceptance: `Restart the authoritative suffix at the exact failed t1545 frontier, combine it with the retained green t01-t1544 evidence, validate locality/cleanup, push at the standing cadence, and consume every expected hosted workflow/job to terminal success with durable URLs and conclusions.`
  Verification: `pending`
  Commit: `pending`

- ID: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.1`
  Status: `done`
  Goal: `Recover the host-pressure-interrupted t296 matrix without discarding completed work again.`
  Acceptance: `Preserve the first resumed-suffix guard interruption exactly; prove its host-wide rather than descendant-local cause; restart t296 at the same clean revision with the existing same-volume exact-revision checkpoint contract and unchanged RAM ceilings; consume the complete green t296 parent and lexical suffix through t999; then return to .3.2 push qualification without retrying any failed test unchanged.`
  Verification: `At clean revision 2dcfaa29715a, guarded checkpointed t296 recovery completed all 762 independently re-derived batches (287 pipeline/default, 94 CLI/default, 287 pipeline/strict, and 94 CLI/strict), then passed its parent at Files=1/Tests=10 in 22,210 wallclock seconds and self-cleared the exact-revision checkpoint. A separate guarded lexical selection independently derived 778 paths from t297 through t999 and passed all of them at Files=778/Tests=2,989 in 18,614 wallclock seconds. Neither run triggered a RAM-guard event; the checkpoint, test processes, and generated residue are absent. Together with the retained green t01-t1544 prefix and resumed green t1545-t295 evidence, this closes the complete-CI file set without relabeling either interruption as passing.`
  Commit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.1: activate checkpointed t296 recovery; DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.1: complete checkpointed t296 recovery`

- ID: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2`
  Status: `active`
  Goal: `Repair every exact first-push hosted failure without discarding the remaining job evidence.`
  Children: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2.1, DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2.2, DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2.3`
  Acceptance: `Consume every required job from exact pushed revision c7a222ac41db, partition each terminal failure by root cause, repair each under its own committed child with focused and routing oracles, preserve every green hosted result, and keep .3.2 active until an authorized exact repair revision is hosted-green.`
  Verification: `pending`
  Commit: `pending`

- ID: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2.1`
  Status: `done`
  Goal: `Give every default provider-backed OSVVM test explicit isolated hosted ownership.`
  Acceptance: `Audit the complete default provider-backed test set and its history; remove t1648 and t1650 from provider-empty ordinary shards; add isolated dedicated coordinates that materialize and verify exact OSVVM 2026.05 before either test; update the closed shard/inventory/workflow watcher; prove disjoint complete routing, exact prerequisites, focused provider-backed success, and no weakened skip or product claim.`
  Verification: `Decision 0088 refines the closed hosted contract to five explicit dedicated coordinates and Boolean prerequisite metadata. The tracked-test census derives 1,656 paths: 1,647 ordinary plus nine separate owners; all 16 ordinary shards are complete/disjoint and exclude the five dedicated tests. t1183 passes at Files=1/Tests=12; a guarded real-provider replay of t1598/t1648/t1650 passes at Files=3/Tests=22 against exact OSVVM root 2f7c391051dfb11890fa4bdbda9918d1db492250.`
  Commit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2.1: seal hosted OSVVM provider ownership`

- ID: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2.2`
  Status: `done`
  Goal: `Make Linux architecture-scale host logical-core discovery portable and deterministic.`
  Acceptance: `Replace the unavailable setup-Perl POSIX constant path with a bounded Linux authority, validate its parser on representative and hostile inputs, preserve Darwin behavior and closed host-profile evidence, and replay t1656 plus the hosted routing watcher without weakening recovery-safety assertions.`
  Verification: `Decision 0089 selects bounded sysfs online/kernel_max parsing plus an independently bounded procfs fallback. Exact parser oracles reject malformed, overlapping, descending, unsorted, ambiguous, out-of-range, duplicate, and missing authorities. t1656 and t1657 each pass at Files=1/Tests=6; hosted routing t1183 passes at Files=1/Tests=12; the host schema and Darwin branch are byte-unchanged.`
  Commit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2.2: make Linux core discovery portable`

- ID: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2.3`
  Status: `done`
  Goal: `Consume every remaining exact-push job and close the complete hosted failure partition.`
  Acceptance: `Wait for every required job in exact run 33023589424; preserve every green result; map each terminal failure to a committed repair root or create a new child before changing implementation; require the aggregate and all jobs terminal; record durable URLs/conclusions without retry, cancellation, or an unauthorized early push.`
  Verification: `Exact-SHA run 33023589424 is terminal-failure: 138/138 jobs, 133 success, four repaired file-shard failures, and aggregate 98398411364 failing only on perl-files. Provider jobs 98359601960/98359602065 map to .1; Linux jobs 98359602070/98359602123 map to .2. No retry, cancellation, new root, or early push occurred.`
  Commit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2.3: close exact-run failure partition`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | The exact callsite census and decision `0086` select the bounded test-only contract. |
| 2 | `.2` | `done` | The helper, hostile watcher, and exact 34-file migration are focused-green. |
| 3 | `.3` | `active` | Parent for complete-CI repair, due push, and hosted qualification. |
| 4 | `.3.1` | `done` | The shared mechanism and sealed fixture adapter make every t1545 subprocess finite and cleanup-safe. |
| 5 | `.3.2.1` | `done` | Exact-revision t296 recovery and the independently selected 778-file lexical tail are green; the checkpoint self-cleared and no guard event recurred. |
| 6 | `.3.2.2.1` | `done` | Five dedicated coordinates now give all three default OSVVM-backed tests exact isolated provider ownership; focused routing and real-provider proofs pass. |
| 7 | `.3.2.2.2` | `done` | Bounded kernel cpulist authority plus procfs fallback repairs both setup-Perl failures without schema or Darwin drift. |
| 8 | `.3.2.2.3` | `done` | All 138 jobs are terminal; four prerequisite failures map exactly to committed repairs and the aggregate adds no root cause. |
| 9 | `.3.2.2` | `active` | Retain the repairs until a standing-cadence exact repair push is hosted-green. |
| 10 | `.3.2` | `active` | Preserve complete-CI and green hosted evidence until an authorized exact repair revision is hosted-green. |

## Decisions

- `2026-08-27`: The added decision/card crosses rationale to 80.8% and Knowledge Map cards to 90.5% of target. Re-derive the exact predecessor rationale baseline,
  retain one declared ratchet step under the active containment owner, advance warning/rollover state, and compact the optional duplicate verification log; raise no ceiling.

- `2026-08-27`: Decision `0089` replaces the unavailable Perl POSIX constant with bounded Linux kernel cpulist authority and an independent procfs fallback;
  strict canonical parsing fails closed, while the host-profile schema and Darwin branch remain unchanged.

- `2026-08-27`: Decision `0088` refines decision `0063`: five dedicated coordinates carry explicit Boolean prerequisite metadata; exactly t1598, t1648,
  and t1650 receive immutable OSVVM 2026.05, while ordinary shards remain provider-free and complete.

- `2026-08-27`: Preserve exact push `c7a222ac41db` and all still-running jobs. Repair its provider-routing and Linux host-profile failures as separate `.3.2.2`
  children; do not retry, cancel, weaken provider qualification, or relabel the aggregate while any required job remains unconsumed.

- `2026-08-26`: Open a separate cross-cutting defect tree rather than append a
  one-off `t/1515` workaround to completed HIAL/VIAL child `.17.3.5.3.2`.
  The discovered mechanism is a legacy test-infrastructure boundary spanning
  potentially many inline runtime callsites, and the HIAL/VIAL task file is at
  its bounded containment ceiling.
- `2026-08-26`: Keep the interrupted complete-CI evidence exact: `t/01` through
  `t/1514` passed; `t/1515` reached an unbounded pre-main hang; later tests are
  not yet qualified. No interrupted or unrun file is classified as passing.
- `2026-08-26`: Decision `0086` selects a test-only supervisor rather than
  widening the private VIAL lifecycle. It reuses the qualified stage bounds,
  requires `FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1` before any affected Darwin
  tool discovery, preserves non-Darwin execution and first-failure truth, and
  mechanically rejects future unbounded direct launches.
- `2026-08-26`: Implement the helper as an independent test authority, not a
  wrapper around `IPC::Cmd` and not a new product lifecycle. The caller guard
  and the helper guard are deliberately redundant: TAP skips ordinary Darwin
  before discovery, while every entrypoint still refuses an unqualified
  fork/exec. The watcher freezes the complete migration and keeps Icarus/vvp
  outside this Verilator-only contract.
- `2026-08-26`: Store the exact migrated path and callsite census in the closed
  tracked `t/data/darwin_inline_verilator_runtime_manifest.json` producer. The
  hostile watcher consumes that manifest, freezes its cardinalities, and
  independently scans tracked tests, so published counts are re-derived,
  falsified, and kept durable by distinct evidence legs.
- `2026-08-26`: Split `.3` after the first post-repair suffix attempt exposed
  an independent unbounded subprocess in `t/1545`. Keep the failed attempt
  authoritative, repair it in child `.3.1`, and resume at the exact `t/1545`
  frontier in `.3.2`; do not retry or relabel the interrupted attempt.
- `2026-08-26`: Decision `0087` extracts the already hostile-tested process
  mechanism from the Verilator helper, while keeping bounds, command/path
  admission, schema, and platform behavior in sealed domain adapters. A
  watcher admits only `VerilatorRuntime` and `TaskAcceptanceFixtureRuntime` as
  low-level helper owners; the hostile oracle may call the mechanism directly.
- `2026-08-26`: Bypass the failed `/usr/bin/env` handoff by resolving the
  caller-selected Git and Bash from absolute `PATH` entries once and invoking
  their canonical executables directly. Do not substitute macOS `/bin/bash`: the
  retained falsification replay fails immediately because version 3.2 cannot
  execute the checker's empty-array loop under `set -u`. Git and Bash are explicit
  read-only host dependency; project-owned data remains repository-local.
- `2026-08-26`: The required rationale entry brings the largest root document
  (`DEVELOPMENT_NOTES.md`) to 975 of its 1,200-line health target, crossing the
  80% warning milestone. Declare `root_documents` as `warning_debt` without
  changing any health target or enforcement ceiling; the existing bounded
  rationale index and rotation contract remain the remediation authority.
- `2026-08-26`: Clean `.3.1` commit `d630261e6` authorizes `.3.2`; retain the
  earlier green/skipped prefix and restart only at exact `t/1545`.
- `2026-08-26`: Preserve the resumed suffix's first guard result: it reached
  the strict-CLI portion of `t/296`, then the unchanged RAM guard terminated
  the complete process group when host occupancy reported 88.1% against its
  88% cutoff. The active FSMGEN generator remained far below the independent
  4-GiB descendant ceiling. Do not retry the uncheckpointed command unchanged;
  child `.3.2.1` must use the existing exact-clean-HEAD, same-volume t296
  checkpoint contract while retaining both RAM ceilings.

## `.3.2.1` host-pressure interruption and recovery evidence

The resumed suffix passed `t/1545` through `t/295`, including the balanced portable and new process-supervision surfaces. `t/296` then ran isolated default
and strict pipeline/CLI batches for 4 hours 48 minutes before `scripts/run_with_ram_guard.sh` reported `host memory 88.1% reached cutoff 88%` and terminated
the exact process group. No 4,096-MiB descendant cutoff was reported: the last census measured generator/worker/t296 at 371,136/79,936/12,816 KiB, while a
sibling-project compiler held 5,587,968 KiB. After sibling pressure released, `memory_pressure -Q` reported 65% free; no FSMGEN process or VIAL recovery
residue remained, and Git stayed clean. Re-derivation is the guard readings plus live PID census; falsification is the absent descendant event, sub-4-GiB
descendant total, and sibling census; durability is this evidence and `docs/knowledge/darwin-inline-verilator-test-runtime.md`, with `prove -Iperl -It/lib
t/1597-t296-checkpoint.t` retaining the focused contract.

The interrupted command set no checkpoint, so none of its t296 batches is credited. Recovery therefore started t296 at the same clean revision with the safe
`.artifacts/t296/*.json` contract; only synced atomic exact-revision batches could resume, and the checkpoint could clear only after the complete parent passed.

Recovery completed at clean revision `2dcfaa29715a`. An independent list-only derivation counted 287 pipeline/default, 94 CLI/default, 287 pipeline/strict,
and 94 CLI/strict batches: 762 total. The guarded parent consumed those exact batches, reported `Files=1, Tests=10` and `Result: PASS` after 22,210 wallclock
seconds, and removed its checkpoint only after the parent succeeded. A separate lexical glob independently selected 778 paths from `t/297` through `t/999`;
its guarded `prove` run reported `Files=778, Tests=2989` and `Result: PASS` after 18,614 wallclock seconds. No host or descendant RAM cutoff occurred in either
recovery run, and the exact checkpoint, test-process tree, and runtime residue are absent.

The completion claim has three distinct legs. Re-derivation is the list-only matrix mode count and pre-run lexical path count. Falsification is each parent's
independent `prove` file/test summary, checkpoint self-removal only after all matrix batches and the parent pass, and the zero guard/process residue census.
Durability is this owning task-tree verification plus the exact completion commit. The retained t01-t1544 prefix, resumed t1545-t295 success, fresh t296
parent success, and fresh t297-t999 tail jointly cover the complete CI file set; neither interrupted attempt is itself credited as a pass.

## `.3.2.2` first hosted-push failure evidence

The due push transported exact revision `c7a222ac41db7b28d502accbb75fcdc6ed579754`; local HEAD, `origin/main`, and `git ls-remote` matched, and ahead count reset
to zero. Knowledge Map `33023589413` and Pages `33023589417` succeed. Regression `33023589424` is terminal: 138/138 jobs, 133 success, four repaired failures,
and aggregate `98398411364` failing only on `perl-files`; doctrines, book, dedicated, corpus, and dynamic succeed (runs under `https://github.com/rdje/fsmgen/actions/runs/`).

Regression jobs `98359601960` and `98359602065` fail only t1650 and t1648 respectively: both provider-empty ordinary shards return the same missing-provider
evidence, and history/routing census show those tests postdate the closed dedicated set. Jobs `98359602070` and `98359602123` fail only t1656 and
t1657 respectively: setup-Perl 5.32 cannot expose `POSIX::_SC_NPROCESSORS_ONLN`, so both abort at Linux host profiling before their intended oracles.
Re-derivation is the tracked triggers plus CI-driver inventory; falsification is the exact-SHA raw logs; durability is this evidence and the child commits.

## Acceptance Checklist — `.3.2.2.3` exact-run completion

- [x] **ROOT CAUSE (WHY + WHERE)** — All 138 jobs are terminal; only four prerequisites fail, matching two committed roots. Aggregate `98398411364` reports only `perl-files=failure`.
- [x] **ADDRESSED (verified)** — Provider jobs `98359601960/98359602065` map to `.1`; Linux jobs `98359602070/98359602123` map to `.2`; 133 jobs succeed and no new child is needed.
- [x] **NO REGRESSION** — No retry, cancellation, relabel, or early push occurred; run/job URLs, SHA, outcomes, repairs, and cadence requalification are durable.

## `.3` interrupted complete-CI evidence

The guarded 1,072-path suffix stayed green/skipped from `t/1515` through `t/1544`, then t1545 blocked in direct `IPC::Cmd::run(command => [$checker])`.
Its `/usr/bin/env bash .../scripts/check_task_acceptance.sh` descendant had no child after six minutes; a one-second sample placed 792/792 frames at
`_dyld_start`, with 96 KiB and no image map. The 887-byte sample has SHA-256 `6851c9f6909f5003815ce82e9cc316ef0ac39a53ae631906b47534839de8f34c`.
The process chain was terminated and absent. Copy/line/byte/hash/content verification used the repository-local diagnostic path before the exact `/tmp`
source, abandoned fixture repository, and consumed diagnostic copy were deleted and censused absent. This interrupted run credits no t1545-or-later pass.

## `.3.1` bounded task-acceptance fixture implementation

The exact surface is five fixture Git calls per repository plus one checker call per case; both direct `IPC::Cmd::run` launchers are removed.
`FSM::Test::ProcessSupervisor` owns scalar shell-free argv, repository/same-volume cwd, bounded streams, close-on-exec, monotonic timing, one process group,
and verified TERM/KILL cleanup. The adapter admits only its project-local fixture roots, exact init/config/add/commit shapes, and copied regular checker;
unsafe paths/global config fail pre-fork. Load-time canonical Git/Bash identity resists later `PATH` mutation; calls use ten-second and
1,048,576/4,194,304-byte bounds, while decision `0086` remains unchanged.

Direct `/bin/bash` made all nine cases fail honestly because macOS Bash 3.2 treats empty `CHANGE_PATTERNS` as unbound; resolving/canonicalizing the selected
Bash once restored t1545 (`Files=1, Tests=9`) with no retry. The watcher then exposed the same env pre-main boundary in generated env-Perl shebangs, so every
generated probe invokes canonical running Perl and a census permits an env shebang only on prove's watcher entrypoint. Final guarded t1545+t1668+t1669
passes `Files=3, Tests=19`, proving fixed values/failure truth, pre-fork rejection, direct Bash/nonzero behavior, TERM-resistant group cleanup, and exactly two
low-level policy owners.

## `.1` tracked launch audit

Two independent source censuses agree on the affected set. The compile census
finds 37 literal `verilator --binary` process callsites in 34 files. The
runtime census finds 36 unbounded `command => [$binary, ...]` callsites in 33
of those files plus the one 30-second inline `t/1559` baseline. Their file sets
are identical. `git log -S 'command => [$binary,' --
t/1498-ial2-ahb-requester-busy-insert.t` locates the pattern's origin at
`83aabe13b` and its later cardinality edit at `a4cabc875`; the installed
`IPC::Cmd` documentation states
that `run(timeout => ...)` uses `alarm()`, not the selected verified
process-group evidence contract.

Audit classes carry all required dimensions:

- **L1:** direct `IPC::Cmd::run`; compile/runtime deadline `none/none`; Darwin
  guard `none`; process cleanup `none` beyond eventual temp-directory cleanup;
  nonzero/signal truth remains failed; migrate both calls.
- **L2:** local `t/1559::run_command` over `IPC::Cmd`; deadline
  `120/30` (`10` for version); Darwin guard `none`; alarm only, with no verified
  descendant cleanup; failure remains failed; migrate version/compile/runtime.
- **P:** already protected by explicit opt-in and the shared VIAL lifecycle or
  dedicated macOS supervisor; fixed bounds, process-group cleanup, and no
  retry are already verified; retain unchanged.

| Source | Compile/runtime sites | Class | `.2` disposition |
| --- | ---: | --- | --- |
| `t/1498-ial2-ahb-requester-busy-insert.t` | `1/1` | L1 | migrated |
| `t/1499-ial2-axi-aw-driver.t` | `1/1` | L1 | migrated |
| `t/1500-ial2-axi-w-driver.t` | `1/1` | L1 | migrated |
| `t/1501-ial2-axi-b-response-acceptor.t` | `1/1` | L1 | migrated |
| `t/1502-ial2-axi-write-request-composition.t` | `1/1` | L1 | migrated |
| `t/1503-ial2-axi-write-transaction-composition.t` | `1/1` | L1 | migrated |
| `t/1504-ial2-axi-ar-driver.t` | `1/1` | L1 | migrated |
| `t/1505-ial2-axi-r-beat-acceptor.t` | `1/1` | L1 | migrated |
| `t/1506-ial2-axi-read-transaction-composition.t` | `1/1` | L1 | migrated |
| `t/1507-ial2-axi-read-burst4-transaction-composition.t` | `2/2` | L1 | migrated |
| `t/1508-ial2-axi-w-burst4-driver.t` | `1/1` | L1 | migrated |
| `t/1509-ial2-axi-write-burst4-request-composition.t` | `1/1` | L1 | migrated |
| `t/1510-isf-multibit-loop-predicate-truthiness.t` | `2/2` | L1 | migrated |
| `t/1511-ial2-ahb-requester-burst-completion.t` | `1/1` | L1 | migrated |
| `t/1513-ial2-ahb-paired-busy-composition.t` | `1/1` | L1 | migrated |
| `t/1514-ial2-ahb-paired-busy-composition-profile-alias.t` | `1/1` | L1 | migrated |
| `t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t` | `1/1` | L1 | migrated |
| `t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t` | `1/1` | L1 | migrated |
| `t/1517-ial2-ahb-requester-wrap-progression-audit.t` | `1/1` | L1 | migrated |
| `t/1519-ial2-ahb-pipelined-active-transfer-audit.t` | `2/2` | L1 | migrated |
| `t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t` | `1/1` | L1 | migrated |
| `t/1521-ial2-ahb-requester-two-busy-insert.t` | `1/1` | L1 | migrated |
| `t/1523-ial2-ahb-exact-two-paired-busy-composition.t` | `1/1` | L1 | migrated |
| `t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t` | `1/1` | L1 | migrated |
| `t/1528-ial2-ahb-requester-three-busy-insert.t` | `1/1` | L1 | migrated |
| `t/1530-ial2-ahb-interconnect-output-arbitration.t` | `1/1` | L1 | migrated |
| `t/1531-ial2-ahb-exact-three-paired-busy-composition.t` | `1/1` | L1 | migrated |
| `t/1533-ial2-ahb-two-subordinate-exact-three-paired-busy-composition.t` | `1/1` | L1 | migrated |
| `t/1535-ial2-ahb-requester-four-busy-insert.t` | `1/1` | L1 | migrated |
| `t/1537-ial2-ahb-exact-four-paired-busy-composition.t` | `1/1` | L1 | migrated |
| `t/1539-ial2-ahb-two-subordinate-exact-four-paired-busy-composition.t` | `1/1` | L1 | migrated |
| `t/1541-ial2-ahb-requester-generalized-busy-count-range.t` | `1/1` | L1 | migrated |
| `t/1542-isf-rule-transaction-named-drive-priority-readiness.t` | `1/1` | L1 | migrated Verilator only; `vvp` retained separately |
| `t/1559-vial-ahb-runtime-parity.t` direct baseline | `1/1` | L2 | migrated; public Runner path retained |

Protected test-side tool routes are excluded from migration, not from the
audit: `t/1558` (Darwin-explicit public Runner), `t/1663` (exact public-run
block), `t/1664` (exact shared-lifecycle traversal), `t/1665` (one-primary
macOS diagnostic), and `t/1667` (RAM-guarded shared-lifecycle measurement) are
class P. `t/1557` and `t/1666` inspect emission/evidence only and launch no
Verilator process.

## Blockers

- None.

## Acceptance Checklist (enforced) — `.1` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — The RAM-guarded pre-push gate passes through `t/1514`, then `t/1515` blocks at line 157 in direct `IPC::Cmd::run(command => [$binary])` with no timeout. A live process census and exact one-second sample distinguish the pre-main mechanism: 804/804 frames remain at `_dyld_start`, with a 96-KiB footprint and no image map. `git log -S 'run(command => [$binary])' -- t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t` independently locates the unbounded launch at `7e5b9f248`.
- [x] **ADDRESSED (verified)** — This active tree owns the complete callsite audit, selected central contract, implementation, resumed CI, and push qualification before code changes. The exact 1,072-byte off-volume sample was copied to the repository volume, matched by size and SHA-256 `3c9716a12a84187fa95d07c80e5ffbb53a9c475d0f31232755fc65b8ec58b6db`, consumed, deleted at both exact paths, and censused absent.
- [x] **NO REGRESSION** — `mdbook test docs/book` reports `All tests successful`; task-tree, Memory, relative-path, rendered-book inspection, claim inventory/dispositions, live-document containment/reference authority, project-locality, and staged doctrine checks pass. Candidate counts remain 1,548 with zero open dispositions and no enforcement ceiling increases.

## Acceptance Checklist (enforced) — `.1` contract selection

- [x] **ROOT CAUSE (WHY + WHERE)** — The compile/runtime source censuses converge on the same 34-file affected set: 37 compile and 37 runtime callsites, of which 36 are unbounded and the remaining `t/1559` alarm path lacks verified process-group cleanup. `git log -S 'command => [$binary,' -- t/1498-ial2-ahb-requester-busy-insert.t` locates the pattern's origin at `83aabe13b` and its later cardinality edit at `a4cabc875`.
- [x] **ADDRESSED (verified)** — Decision `0086`, the per-path table above, the Knowledge Map card, and the mdBook select one test-only closed supervisor with fixed stage bounds, close-on-exec handoff evidence, whole-group TERM/KILL cleanup, pre-discovery Darwin qualification, unchanged non-Darwin execution, no retry, and one exact 34-file migration plus watcher.
- [x] **NO REGRESSION** — `prove -Iperl t/1414-docs-relative-paths-audit.t` reports `All tests successful`; task-tree, Memory, decision-index, Knowledge Map, mdBook, live-document containment/reference authority, claim inventory/dispositions, locality, diff, and staged doctrine gates pass with zero enforcement ceiling increases.

## Acceptance Checklist (enforced) — `.2` bounded implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'command => [$binary,' -- t/1498-ial2-ahb-requester-busy-insert.t` locates the exact historical source pattern at `83aabe13b`; it still reached the generated executable directly in all 34 audited files and left 36 paths without any deadline plus one alarm-only path without group cleanup. Independent literal-compile and generated-runtime censuses both derive 37 callsites and the same file set.
- [x] **ADDRESSED (verified)** — `t/lib/FSM/Test/VerilatorRuntime.pm` owns the sealed stage bounds, qualification, path/cwd admission, split aggregate-bounded capture, exec handoff, monotonic evidence, process group, first-failure status, and verified cleanup. The closed tracked census manifest independently names all 34 affected files and both 37-call totals. `t/1668-darwin-inline-verilator-test-runtime.t` proves hostile outcomes and recomputes the exact migration: 37/37 helper-owned callsites, zero direct generated-binary IPC launches, pre-discovery guard and project-local temp activation everywhere, and unchanged separate Icarus/vvp ownership.
- [x] **NO REGRESSION** — All 34 migrated files report `syntax OK`; their ordinary Darwin run produces the exact pre-discovery skip for all 34 files; the hostile watcher passes at `Files=1, Tests=6`; explicitly qualified `t/1515` passes at `Files=1, Tests=3`; task-tree, Memory, Knowledge Map, mdBook, claim, live-document, locality, diff, and staged doctrine gates pass with no containment-ceiling increase.

## Acceptance Checklist (enforced) — `.3.1` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'run(command => [$checker])' -- t/1545-task-acceptance-doctrine.t` locates the unbounded fixture launch at `c636a458f`; live process inspection locates the blocked `/usr/bin/env bash` descendant, and its one-second sample derives 792/792 `_dyld_start` frames, a 96-KiB footprint, and no image map.
- [x] **ADDRESSED (verified)** — The same-tree `.3.1` leaf owns exact sample migration/cleanup, command-surface audit, bounded supervision, hostile testing, and the deterministic `t/1545` replay before complete CI can resume. The 887-byte repository-volume copy matched the source's 32 lines and SHA-256 before consumption; both copies, the failed process chain, and the abandoned fixture repository are absent, while the tracked evidence summary remains.
- [x] **NO REGRESSION** — `prove -Iperl t/1414-docs-relative-paths-audit.t` reports `All tests successful`; task-tree, Memory, claim, live-document, locality, diff, and staged doctrine gates pass with no containment-ceiling increase.

## Acceptance Checklist (enforced) — `.3.1` bounded implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'run(command => [$checker])' -- t/1545-task-acceptance-doctrine.t` identifies `c636a458f` as the source of the unbounded checker handoff; the retained 792/792-frame sample and first fixture replay localize it to `/usr/bin/env bash` before user code. The separate `/bin/bash` replay fails all nine top-level cases at checker line 52, proving that a 3.2 substitution changes checker semantics rather than repairing launch supervision. A later combined gate reached exec handoff for t1668's generated `#!/usr/bin/env perl` success fixture but no first output before the sealed 30-second wall, independently exposing the same hidden env boundary in the watcher itself.
- [x] **ADDRESSED (verified)** — Decision `0087` and `t/lib/FSM/Test/ProcessSupervisor.pm` establish one shared private mechanism; `TaskAcceptanceFixtureRuntime.pm` seals the fixture subtree, four Git operations, load-time canonical Git/Bash identity, direct Bash handoff, ten-second walls, two capture ceilings, closed result, and no retry. `t/1668` seals generated fixtures to the canonical running Perl interpreter and watches out env-shebang recurrence; `t/1669` proves TERM/KILL cleanup, mutable-`PATH` replacement resistance, path/command rejection, fixed values, first-failure truth, and exactly two policy-module owners.
- [x] **NO REGRESSION** — The final RAM-guarded combined focused command reports `All tests successful` and `Files=3, Tests=19` for the same nine-case `t/1545` oracle, six-case Verilator hostile/census watcher, and four-case shared-engine/fixture watcher; the repaired t1668 also passes alone at `Files=1, Tests=6`. mdBook, Knowledge Map, task-tree, Memory, claim, live-document, locality, diff, and staged doctrine gates pass with no ceiling increase.

## Acceptance Checklist — `.3.2` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — The authoritative suffix stopped at t1545's unbounded env handoff after retaining a green/skipped prefix through t1544; `.3.1` repaired that exact frontier without classifying later tests.
- [x] **ADDRESSED (verified)** — Commit `d630261e6` is clean, the final focused cluster is green, and this leaf alone owns the exact t1545 restart, suffix completion, due push, and hosted qualification.
- [x] **NO REGRESSION** — The activation changes only task-tree and bounded resume metadata; task-tree, Memory, diff, and doctrine checks must pass before its commit.

## Acceptance Checklist — `.3.2.1` checkpointed recovery activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `scripts/run_with_ram_guard.sh` reported the exact host-capacity event, `host memory 88.1% reached cutoff 88%`, while the last `ps` census measured the active strict-CLI generator at 371,136 KiB and found a concurrent sibling-project compiler at 5,587,968 KiB. No descendant-cutoff message occurred, and the guard removed the exact prove/t296/worker/generator PID tree. Independent `git log -S'FSMGEN_T296_CHECKPOINT' --oneline -- t/296-regression-corpus-supported-behavior.t t/lib/FSM/Test/T296Checkpoint.pm t/1597-t296-checkpoint.t` history recovery identifies commit `c990583ac` as the existing checkpoint mechanism's introduction.
- [x] **ADDRESSED (verified)** — Active child `.3.2.1` owns an exact-clean-HEAD restart of t296 with the existing safe `.artifacts/t296/*.json` checkpoint contract and unchanged 88% host/4,096-MiB descendant ceilings. The absent checkpoint is not invented, no interrupted batch is credited, and the full parent must still pass before its checkpoint is removed.
- [x] **NO REGRESSION** — The guarded focused checkpoint, relative-path, and task-tree tests pass; the corrected canonical project-locality test reports `Files=1, Tests=20`; Knowledge Map generation/check/query parity passes at 1,153 facts, 6,113 unique questions, 6,280 answer occurrences, and 136 bounded shards, with the recovery question resolving to the existing canonical runtime card. The first combined command stopped after its three existing tests passed because it named nonexistent `t/1330-project-data-locality.t`; only the unreached checks were run with canonical `t/1527-project-data-locality.t`. Diff and staged doctrine checks remain required before commit.

## Acceptance Checklist — `.3.2.1` checkpointed recovery completion

- [x] **ROOT CAUSE (WHY + WHERE)** — The first resumed suffix was terminated solely by the RAM guard's host-wide 88.1% cutoff while its active FSMGEN generator remained below the independent 4-GiB descendant ceiling; no test assertion failed. The prior uncheckpointed t296 work is deliberately uncredited, and recovery starts t296 from its exact clean revision rather than hiding the interruption.
- [x] **ADDRESSED (verified)** — The existing exact-revision repository-local checkpoint consumed all 762 independently counted t296 batches, the complete parent passed, and the checkpoint self-cleared. The separately derived 778-file lexical tail from t297 through t999 then passed, returning ownership to `.3.2` for locality, book, push, and hosted qualification.
- [x] **NO REGRESSION** — Guarded t296 reports `Files=1, Tests=10` and guarded t297-t999 reports `Files=778, Tests=2989`, both with `All tests successful` and `Result: PASS`. Neither guard fired; the checkpoint and test processes are absent; Git remained clean throughout. Combined with retained t01-t295 evidence, every complete-CI file is covered without retrying or reclassifying a failed assertion.

## Acceptance Checklist — `.3.2.2.1` hosted provider ownership

- [x] **ROOT CAUSE (WHY + WHERE)** — Exact-SHA job `98359601960` runs t1650 in provider-empty ordinary shard 8 and fails at `/dependency_root`; `git log -S 'HOSTED_DEDICATED_TEST_2' --oneline -- bin/ci-regression` identifies `ded0520c4` as the three-coordinate list's origin. The source/call-path census derives t1598, t1648, and t1650 as the complete default real-provider set while separating mocked, installed-tool-conditional, and explicit opt-in tests.
- [x] **ADDRESSED (verified)** — Decision `0088`, `bin/ci-regression`, and the workflow define five closed coordinates. Explicit matrix flags give only t1436 pinned HDL tools and exactly t1598/t1648/t1650 the immutable repository-local provider. The watcher independently closes all 1,656 tracked tests as 1,647 ordinary plus nine separate owners and rejects bad coordinates.
- [x] **NO REGRESSION** — `t/1183` reports `Files=1, Tests=12` PASS; the guarded exact-provider run of t1598/t1648/t1650 reports `Files=3, Tests=22` PASS in 331 seconds. Driver syntax, five dry-run coordinates, provider HEAD, mdBook, Knowledge Map, task/decision structure, locality, live-document, claim, diff, and staged doctrine gates are required green for commit.

## Acceptance Checklist — `.3.2.2.2` Linux logical-core authority

- [x] **ROOT CAUSE (WHY + WHERE)** — Exact-SHA jobs `98359602070` and `98359602123` both abort in `ArchitectureScaleMeasurement::_linux_logical_cores`; `git log -S 'POSIX::_SC_NPROCESSORS_ONLN'` locates the optional-constant dependency at `3946bf101`, while setup-Perl 5.32 does not export it.
- [x] **ADDRESSED (verified)** — Decision `0089` and the module use bounded `online`/`kernel_max` kernel authority with strict canonical cpulist parsing, then an independently bounded exact procfs-identity fallback; focused hostile cases reject overlap, ordering, ambiguity, range, duplicate, malformed, and missing evidence without changing schema or Darwin code.
- [x] **NO REGRESSION** — `t/1656` and `t/1657` each report `Files=1, Tests=6` PASS; `t/1183` reports `Files=1, Tests=12` PASS; mdBook, Knowledge Map, task/decision, locality, live-document, claim, diff, and doctrine checks pass with no ceiling increase.
