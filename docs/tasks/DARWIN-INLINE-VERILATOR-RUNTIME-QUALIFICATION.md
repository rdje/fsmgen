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
  Status: `active`
  Goal: `Audit all tracked test-side Verilator compile/run paths and select one durable supervision and Darwin-qualification contract.`
  Acceptance: `Enumerate every direct and helper-mediated executable launch, prove the exact t/1515 pre-main/no-timeout mechanism and affected class, migrate and remove the exact off-volume sample residue, select central helper ownership plus timeout/guard/cleanup/failure semantics, and record the decision, Knowledge Map fact, mdBook boundary, and exact implementation migration set without changing behavior.`
  Verification: `Activation preserves the exact green-through-t1514/unbounded-t1515 frontier, records the 804/804 _dyld_start and no-timeout mechanism, completes copy/size/hash/use/delete/residue-census handling for the 1,072-byte off-volume sample, and leaves the complete callsite audit and contract selection active.`
  Commit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.1: activate legacy inline runtime audit`

- ID: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.2`
  Status: `pending`
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
| 1 | `.1` | `active` | A complete callsite census and selected central contract are required before changing any runtime test. |
| 2 | `.2` | `pending` | Implementation depends on the committed audit and selection. |
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

## Blockers

- None.

## Acceptance Checklist (enforced) — `.1` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — The RAM-guarded pre-push gate passes through `t/1514`, then `t/1515` blocks at line 157 in direct `IPC::Cmd::run(command => [$binary])` with no timeout. A live process census and exact one-second sample distinguish the pre-main mechanism: 804/804 frames remain at `_dyld_start`, with a 96-KiB footprint and no image map. `git log -S 'run(command => [$binary])' -- t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t` independently locates the unbounded launch at `7e5b9f248`.
- [x] **ADDRESSED (verified)** — This active tree owns the complete callsite audit, selected central contract, implementation, resumed CI, and push qualification before code changes. The exact 1,072-byte off-volume sample was copied to the repository volume, matched by size and SHA-256 `3c9716a12a84187fa95d07c80e5ffbb53a9c475d0f31232755fc65b8ec58b6db`, consumed, deleted at both exact paths, and censused absent.
- [x] **NO REGRESSION** — `mdbook test docs/book` reports `All tests successful`; task-tree, Memory, relative-path, rendered-book inspection, claim inventory/dispositions, live-document containment/reference authority, project-locality, and staged doctrine checks pass. Candidate counts remain 1,548 with zero open dispositions and no enforcement ceiling increases.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-08-26` | `.1` activation | pre-push CI prefix; live process census; one-second stack sample; timeout-source inspection | `t/01-t/1514 green; t/1515 has an unbounded direct launch and 804/804 _dyld_start frames; exact audit/selection now active` |
