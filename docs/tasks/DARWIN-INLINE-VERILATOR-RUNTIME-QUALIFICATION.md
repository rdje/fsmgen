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
  Status: `active`
  Goal: `Implement the selected central runtime supervision and migrate every affected tracked callsite.`
  Acceptance: `Use only the committed .1 selection; add one readable caller-safe helper, stable bounded diagnostics, process-tree cleanup, explicit Darwin opt-in before tool discovery, unchanged non-Darwin execution, exact environment restoration, hostile-input tests, and mechanical detection of newly introduced unbounded direct launches.`
  Verification: `pending`
  Commit: `pending`

- ID: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3`
  Status: `pending`
  Goal: `Qualify the migrated runtime surface, resume complete CI, and close the due push follow-up.`
  Acceptance: `Pass focused helper/callsite/runtime tests, resume the RAM-guarded complete-CI suffix at t/1515 through the lexical tail, validate the mdBook build and repository locality/cleanup, push the exact clean revision at the standing cadence, and consume every expected hosted workflow/job to terminal success with durable URLs and conclusions.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | The exact callsite census and decision `0086` select the bounded test-only contract. |
| 2 | `.2` | `active` | Implement the selected helper, watcher, and exact 34-file migration. |
| 3 | `.3` | `pending` | Complete-CI and push qualification depend on the migrated runtime surface. |

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
| `t/1498-ial2-ahb-requester-busy-insert.t` | `1/1` | L1 | migrate |
| `t/1499-ial2-axi-aw-driver.t` | `1/1` | L1 | migrate |
| `t/1500-ial2-axi-w-driver.t` | `1/1` | L1 | migrate |
| `t/1501-ial2-axi-b-response-acceptor.t` | `1/1` | L1 | migrate |
| `t/1502-ial2-axi-write-request-composition.t` | `1/1` | L1 | migrate |
| `t/1503-ial2-axi-write-transaction-composition.t` | `1/1` | L1 | migrate |
| `t/1504-ial2-axi-ar-driver.t` | `1/1` | L1 | migrate |
| `t/1505-ial2-axi-r-beat-acceptor.t` | `1/1` | L1 | migrate |
| `t/1506-ial2-axi-read-transaction-composition.t` | `1/1` | L1 | migrate |
| `t/1507-ial2-axi-read-burst4-transaction-composition.t` | `2/2` | L1 | migrate |
| `t/1508-ial2-axi-w-burst4-driver.t` | `1/1` | L1 | migrate |
| `t/1509-ial2-axi-write-burst4-request-composition.t` | `1/1` | L1 | migrate |
| `t/1510-isf-multibit-loop-predicate-truthiness.t` | `2/2` | L1 | migrate |
| `t/1511-ial2-ahb-requester-burst-completion.t` | `1/1` | L1 | migrate |
| `t/1513-ial2-ahb-paired-busy-composition.t` | `1/1` | L1 | migrate |
| `t/1514-ial2-ahb-paired-busy-composition-profile-alias.t` | `1/1` | L1 | migrate |
| `t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t` | `1/1` | L1 | migrate |
| `t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t` | `1/1` | L1 | migrate |
| `t/1517-ial2-ahb-requester-wrap-progression-audit.t` | `1/1` | L1 | migrate |
| `t/1519-ial2-ahb-pipelined-active-transfer-audit.t` | `2/2` | L1 | migrate |
| `t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t` | `1/1` | L1 | migrate |
| `t/1521-ial2-ahb-requester-two-busy-insert.t` | `1/1` | L1 | migrate |
| `t/1523-ial2-ahb-exact-two-paired-busy-composition.t` | `1/1` | L1 | migrate |
| `t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t` | `1/1` | L1 | migrate |
| `t/1528-ial2-ahb-requester-three-busy-insert.t` | `1/1` | L1 | migrate |
| `t/1530-ial2-ahb-interconnect-output-arbitration.t` | `1/1` | L1 | migrate |
| `t/1531-ial2-ahb-exact-three-paired-busy-composition.t` | `1/1` | L1 | migrate |
| `t/1533-ial2-ahb-two-subordinate-exact-three-paired-busy-composition.t` | `1/1` | L1 | migrate |
| `t/1535-ial2-ahb-requester-four-busy-insert.t` | `1/1` | L1 | migrate |
| `t/1537-ial2-ahb-exact-four-paired-busy-composition.t` | `1/1` | L1 | migrate |
| `t/1539-ial2-ahb-two-subordinate-exact-four-paired-busy-composition.t` | `1/1` | L1 | migrate |
| `t/1541-ial2-ahb-requester-generalized-busy-count-range.t` | `1/1` | L1 | migrate |
| `t/1542-isf-rule-transaction-named-drive-priority-readiness.t` | `1/1` | L1 | migrate Verilator only; keep `vvp` separate |
| `t/1559-vial-ahb-runtime-parity.t` direct baseline | `1/1` | L2 | migrate; retain public Runner path |

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

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-08-26` | `.1` activation | pre-push CI prefix; live process census; one-second stack sample; timeout-source inspection | `t/01-t/1514 green; t/1515 has an unbounded direct launch and 804/804 _dyld_start frames; exact audit/selection now active` |
| `2026-08-26` | `.1` selection | literal compile census; independent runtime census; exact file-set comparison; IPC timeout documentation; decision/card/book/task/doctrine checks | `37 compile + 37 runtime sites in 34 affected files; decision 0086 accepted; .2 active` |
