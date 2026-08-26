# DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION: Bound and qualify legacy inline Verilator runtimes

## Metadata

- Tree ID: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION`
- Status: `active`
- Roadmap lane: `verification infrastructure / runtime qualification`
- Created: `2026-08-26`
- Last updated: `2026-08-26`
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
  Children: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.1`
  Acceptance: `Restart the authoritative suffix at the exact failed t1545 frontier, combine it with the retained green t01-t1544 evidence, validate locality/cleanup, push at the standing cadence, and consume every expected hosted workflow/job to terminal success with durable URLs and conclusions.`
  Verification: `pending`
  Commit: `pending`

- ID: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.1`
  Status: `active`
  Goal: `Recover the host-pressure-interrupted t296 matrix without discarding completed work again.`
  Acceptance: `Preserve the first resumed-suffix guard interruption exactly; prove its host-wide rather than descendant-local cause; restart t296 at the same clean revision with the existing same-volume exact-revision checkpoint contract and unchanged RAM ceilings; consume the complete green t296 parent and lexical suffix through t999; then return to .3.2 push qualification without retrying any failed test unchanged.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | The exact callsite census and decision `0086` select the bounded test-only contract. |
| 2 | `.2` | `done` | The helper, hostile watcher, and exact 34-file migration are focused-green. |
| 3 | `.3` | `active` | Parent for complete-CI repair, due push, and hosted qualification. |
| 4 | `.3.1` | `done` | The shared mechanism and sealed fixture adapter make every t1545 subprocess finite and cleanup-safe. |
| 5 | `.3.2.1` | `active` | The exact t1545 suffix reached strict-CLI t296 before a host-wide 88.1% guard event; preserve it and use the existing exact-revision t296 checkpoint contract for bounded recovery. |
| 6 | `.3.2` | `active` | Consume `.3.2.1`, complete the lexical tail, and finish push plus hosted qualification. |

## Decisions

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

The resumed suffix passed `t/1545` through `t/295`, including the full balanced
portable composition, emission, runtime, measurement, portable-runtime, and
new hostile process-supervision tests. `t/296` then ran isolated default and
strict pipeline/CLI batches for 4 hours 48 minutes. During a strict-CLI AXI
batch, `scripts/run_with_ram_guard.sh` reported `host memory 88.1% reached
cutoff 88%` and terminated the exact prove/t296/worker/generator group. Its
termination output did not report the 4,096-MiB descendant cutoff. The last
pre-termination process census measured the active generator at 371,136 KiB;
the enclosing worker was 79,936 KiB and the t296 parent 12,816 KiB. A
post-cleanup host census found a sibling-project release compiler at 5,587,968
KiB plus concurrent sibling-project test compilers; after they released
pressure, `memory_pressure -Q` reported 65% free. The guard left no listed
FSMGEN process alive, Git remained clean at the exact revision, and the
repository-local VIAL recovery area was empty.

Claim verification is explicit. Re-derivation is the guard's own independent
host and descendant readings plus the live PID-tree census. Falsification is
the absence of a descendant-cutoff message together with a descendant total
far below 4 GiB and the separate sibling-process census. Durability is this
task evidence plus `docs/knowledge/darwin-inline-verilator-test-runtime.md`;
the focused contract remains re-runnable with `prove -Iperl -It/lib
t/1597-t296-checkpoint.t`.

The interrupted command did not set `FSMGEN_T296_CHECKPOINT`, and no checkpoint
file exists, so its completed t296 batches cannot be reconstructed or credited.
Recovery starts t296 again at the same clean revision with a safe
`.artifacts/t296/*.json` checkpoint path. Each completed isolated batch is
synced and atomically retained; a later guard interruption may resume only
those exact recorded batches. The full parent must still finish green before
the checkpoint clears and before the lexical suffix can continue.

## `.3` interrupted complete-CI evidence

The RAM-guarded suffix selected 1,072 lexical paths from `t/1515` through
`t/999`. It remained green or contractually skipped through `t/1544`.
`t/1545-task-acceptance-doctrine.t` then blocked in its first fixture's direct
`IPC::Cmd::run(command => [$checker])` call. The exact descendant was
`/usr/bin/env bash .../scripts/check_task_acceptance.sh`; after more than six
minutes it had no child process. A one-second sample placed 792/792 main-thread
frames at `_dyld_start`, reported a 96-KiB footprint, and had no binary-image
description. The sample is 887 bytes with SHA-256
`6851c9f6909f5003815ce82e9cc316ef0ac39a53ae631906b47534839de8f34c`.
The exact checker/test/prove chain was terminated and verified absent. The
sample was copied to the repository-volume diagnostic path
`.artifacts/diagnostics/darwin-inline-verilator-runtime-qualification/t1545-env-premain.sample.txt`,
matched by line count, byte count, SHA-256, and diagnostic content, then the
exact sampler-created `/tmp` source was deleted and censused absent. The exact
abandoned fixture repository was also deleted and censused absent. No
`t/1545` or later test is classified as passing by this interrupted run.
After the tracked hash, size, stack, and cleanup summary above became the
durable evidence, the repository-volume diagnostic copy was consumed, deleted,
and censused absent as well.

## `.3.1` bounded task-acceptance fixture implementation

The exact command surface is five fixture-setup Git invocations per repository
plus one checker invocation per case, with later `git add` calls routed through
the same helper. `t/1545` had two source-level direct `IPC::Cmd::run` sites:
the common Git launcher and checker launcher. Both are removed.

`FSM::Test::ProcessSupervisor` now contains the formerly Verilator-local
mechanism: scalar shell-free argv, repository/same-volume cwd admission,
separate aggregate-bounded streams, close-on-exec control, monotonic timing,
one process group, and verified TERM/KILL cleanup. The Verilator adapter
retains decision `0086` unchanged. The task-acceptance adapter admits only
`.artifacts/tmp/task-acceptance-tests/fsmgen-*` repositories, exact fixture-
owned init/local-config/relative-add/baseline-commit argument shapes, and the
copied regular checker. Global config and unsafe paths fail before process
creation. Git and Bash are canonicalized at adapter load, so later `PATH`
mutation cannot replace either admitted executable. Git/checker calls have fixed ten-second walls and
1,048,576/4,194,304-byte aggregate capture ceilings.

The first post-edit replay using `/bin/bash` was finite but honestly failed all
nine top-level subtests: macOS Bash 3.2 treated the empty `CHANGE_PATTERNS`
array as unbound at checker line 52. The adapter was then corrected to resolve
the environment-selected Bash binary once from absolute `PATH` entries,
canonicalize it, and execute that binary directly. The next exact RAM-guarded
`t/1545` run passed at `Files=1, Tests=9`; no retry was added to the test or
adapter. The new hostile watcher initially reproduced the env pre-main
boundary through its own shebang, so its mechanism probe now invokes the
already-running absolute Perl interpreter and cannot confuse host-loader
behavior with supervision behavior.

A later combined gate honestly failed the Verilator watcher's nominal success
fixture at its fixed 30-second wall after exec handoff but before first output.
That fixture still generated `#!/usr/bin/env perl`, reproducing the same hidden
env boundary. No retry occurred. Every generated Verilator-watcher program now
uses a shebang containing the canonical already-running Perl interpreter, and
the census subtest proves that only the prove-invoked watcher entrypoint retains
an env shebang.

The final combined RAM-guarded focused gate passes
`t/1545`, `t/1668`, and `t/1669` at `Files=3, Tests=19`. The new watcher proves
fixed adapter values and failure truth, rejects non-fixture paths and an
unregistered Git command/global config before process creation, exercises
direct Bash handoff and nonzero exit, kills a TERM-resistant
leader/descendant group, and recomputes exactly two policy-module owners of
the low-level mechanism.

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

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-08-26` | `.1` activation | pre-push CI prefix; live process census; one-second stack sample; timeout-source inspection | `t/01-t/1514 green; t/1515 has an unbounded direct launch and 804/804 _dyld_start frames; exact audit/selection now active` |
| `2026-08-26` | `.1` selection | literal compile census; independent runtime census; exact file-set comparison; IPC timeout documentation; decision/card/book/task/doctrine checks | `37 compile + 37 runtime sites in 34 affected files; decision 0086 accepted; .2 active` |
| `2026-08-26` | `.2` bounded implementation | closed census manifest; 34-file syntax gate; hostile helper/watcher; standard Darwin guard run; explicitly qualified original t1515; independent source scan | `37 compile + 37 runtime sites helper-owned; direct generated-binary IPC=0; Files=1/Tests=6 watcher and Files=1/Tests=3 qualified t1515 pass; .3 active` |
| `2026-08-26` | `.3` interrupted suffix | RAM-guarded lexical t1515-tail run; live process tree; one-second sample; exact termination/residue census | `green/skipped through t1544; t1545 first fixture blocked in unbounded /usr/bin/env bash pre-main path with 792/792 _dyld_start frames; .3.1 active` |
| `2026-08-26` | `.3.1` bounded implementation | exact command/history audit; direct /bin/bash falsification; shared-engine extraction; sealed adapter; hostile ownership watcher; RAM-guarded combined regression | `two direct IPC sites removed; Files=3/Tests=19 pass; TERM-resistant group gone; exactly two low-level policy owners; .3.2 next after clean commit` |
| `2026-08-26` | `.3.1` watcher env falsification | combined RAM-guarded gate; exec-handoff/first-output evidence; generated-fixture source census; zero process residue | `t1545 and t1669 pass; t1668 nominal env-Perl fixture times out honestly after handoff; all generated fixtures switched to canonical Perl with recurrence watcher; no retry` |
| `2026-08-26` | `.3.1` watcher env repair | focused repaired t1668; final three-file RAM-guarded cluster | `t1668 Files=1/Tests=6 pass; final t1545+t1668+t1669 Files=3/Tests=19 pass; generated env-Perl recurrence count held to entrypoint only` |
| `2026-08-26` | `.3.2` activation | clean-tree census; committed repair identity; frontier alignment | `d630261e6 clean; retained prefix through t1544; exact t1545 restart active` |
| `2026-08-26` | `.3.2.1` host-pressure recovery activation | authoritative suffix; RAM-guard output; live PID/RSS census; post-cleanup process/memory/residue census; checkpoint-contract audit; focused t1597/t1414/t1549/t1527 and Knowledge Map checks | `green through t295; t296 interrupted after 4h48m by host 88.1% cutoff, not descendant 4-GiB cutoff; no checkpoint existed; exact-revision checkpointed recovery active; focused recovery checks pass` |
