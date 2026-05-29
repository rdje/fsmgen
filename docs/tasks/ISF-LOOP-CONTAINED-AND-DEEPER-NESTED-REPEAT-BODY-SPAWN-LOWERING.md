# ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING: Enable Loop-Contained / Deeper-Nested Repeat-Body `spawn` (+ same-body drain)

## Metadata

- Tree ID: `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-29`
- Last updated: `2026-05-29`
- Owner: repo-local workflow

## Goal

Allow the basic `(spawn child as inst)` + same-body `(await_all done)` (and the
single-pending `(await_any done)`) subset inside a `(repeat N ...)` that sits in
a single `(while ...)`/`(until ...)` loop body, or is reached through deeper
branch nesting (`when⁺ → repeat`, `switch → when⁺ → repeat`). Fifth scheduler
-frontier slice. The complex spawn variations (multi-pending `await_any`,
spawn-after-do, await_any-as-observation) stay deferred.

## Ground truth (probed; some claims to re-verify in `.2`)

1. The spawn gate (`_validate_repeat_body_spawn_subset`, ~L6424) defers
   loop-contained / deeper-nested spawn. The four `_ir_repeat` params are
   already threaded through the loop-body and nested-branch recursions (prior
   slices). `_ir_repeat` already lowers spawn / await_all / await_any
   (`@spawn_done_ports` + `_ir_sync_all`/`_ir_sync_any`).
2. **Critical**: the mandatory-drain rule (~L6759, "top-level repeat-body spawn
   requires await_all") is gated on `$top_level_repeat` only; the when-body /
   switch-branch analogues (~L6753/6757) are gated on those flags. So adding
   `$loop_body_repeat`/`$deeper_nested_repeat` to the gate WITHOUT a matching
   drain-requirement rule would wrongly accept an undrained spawn (leaked
   children across iterations). `.2` MUST add the drain requirement for these
   contexts.
3. The complex spawn-sequencing rules (multi-pending await_any, spawn-after-do)
   are gated on `$when_body_repeat`/`$switch_branch_repeat` and skip loop/deeper
   contexts — so those variations are simply never validated-as-supported there
   (they fall to the drain-requirement / supported-subset rejection). Good.
4. Spawn instance naming uses the transaction name (no loop/iteration suffix) —
   the SAME as the already-shipped top-level repeat-body spawn. `.2` verified
   the loop-contained drain semantics match the proven top-level reference
   (await_all drains the child before repeat_check loops, and before the outer
   loop re-enters at repeat_init), with golden `.fsm` evidence.
5. **Important finding (corrects the original acceptance):** repeat-body spawn
   is a **lowering + composition-planning** feature, NOT full-HDL-clean — even
   at top level. `--check-json` fails for the already-shipped top-level
   `(repeat N (spawn w)(await_all done))` with `instance 'w0' has no port named
   'loops'` (the composition planner references the repeat-count / loop-condition
   parent inputs as child endpoints; see `docs/COMPOSITION_SCOPE.md`). The
   loop-contained case fails the SAME way (`... no port named 'cond'`). This is a
   pre-existing repeat-spawn composition limitation, out of scope for this slice;
   the slice's deliverable is lowering + composition parity with top-level
   repeat-spawn (correct drain schedule, child instantiated), not full HDL.

## Scope (this tree)

- Enable basic `(spawn child as inst)` + same-body `(await_all done)` (and
  single-pending `(await_any done)`) in a `$loop_body_repeat` or
  `$deeper_nested_repeat` repeat.
- Add the drain-requirement rule for these contexts (an undrained loop/deeper
  spawn fails closed).
- Keep deferred: multi-pending `await_any`, spawn-after-do, await_any-as
  -observation, cross-domain (separate lanes).

## Non-Goals

- No multi-pending await_any / spawn-after-do / await_any-observation variants
  in loop/deeper contexts.
- No cross-domain spawn.

## Acceptance Criteria

- `(while cond (repeat N (spawn w as i)(await_all done)))` and the until /
  deeper-nested (`when⁺`, `switch→when⁺`) forms lower, instantiate the child in
  the `_top` composition (3 files), and produce the correct drain schedule
  (`spawn → await_all → repeat_check`, draining before `repeat_check` loops and
  before the loop re-enters) — parity with the proven top-level repeat-spawn.
  Full-HDL `--check-json` is NOT required (the top-level repeat-spawn reference
  also fails it via the pre-existing composition-wiring limitation; out of
  scope).
- An UNDRAINED loop/deeper spawn (no same-body `await_all`/single `await_any`)
  fails closed with a targeted drain-requirement diagnostic.
- Multi-pending await_any / spawn-after-do in loop/deeper contexts still fail
  closed.
- New `t/1383-...` golden + updated `t/1374`/`t/1375` (their spawn-deferral
  cases) where the deferral is lifted.
- Book/spec docs synced; slice audit set + broad regression pass; mdBook clean;
  `git diff --check` clean.
- Each leaf committed via `COMMIT.md`.

## Task Tree

- ID: `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING`
  Status: `done`
  Goal: `Lower basic loop-contained/deeper-nested repeat-body spawn + same-body drain; keep complex variants deferred.`
  Children:
    `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING.1`,
    `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING.2`

- ID: `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING.1`
  Status: `done`
  Goal: `Select the slice; record probed ground truth incl. the drain-requirement gap.`
  Acceptance: `Task tree committed before any code/test/doc change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `2b0f788b`

- ID: `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING.2`
  Status: `done`
  Goal: `Gate relaxation + drain-requirement rule + multi-pending-await_any deferral; verify drain semantics vs top-level; add t/1383; sync docs; validate.`
  Acceptance: `Accept-path drains (lowering + composition parity with top-level repeat-spawn); undrained + multi-pending + cross-domain fail closed; audits green.`
  Verification: `prove -Iperl t/1383 t/1374 t/1375 t/1379 t/1380 t/1381 t/1382 t/1215 t/1304 t/1307 t/1305 t/1376 t/1332 t/1250 (Files=15, Tests=980, PASS); broad regression (123 files, 957) PASS; drain schedule golden-verified; mdbook build docs/book; git diff --check`
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING.1` | `done` | Selection commit `2b0f788b`. |
| 2 | `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING.2` | `done` | Gate + drain rule + multi-pending deferral + `t/1383` golden + doc sync shipped; tree closed. |

## Decisions

- `2026-05-29`: Scope to the basic spawn + same-body drain subset, mirroring the
  conservative path of the other frontier slices. The mandatory-drain rule must
  be added for loop/deeper contexts (the existing one is top-level-only) — this
  is the key non-obvious requirement from the spawn-validator probe.

## Open Questions

- None blocking. (Drain semantics across loop iterations to be confirmed by
  golden `.fsm` in `.2`; expected to match the proven top-level repeat-spawn.)

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-29` | `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING.1` | `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-05-29` | `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING.2` | `prove -Iperl t/1383 t/1374 t/1375 t/1379 t/1380 t/1381 t/1382 t/1215 t/1304 t/1307 t/1305 t/1376 t/1332 t/1250` (Files=15, Tests=980, PASS); broad regression (123 files, 957) PASS; drain schedule golden-verified; `mdbook build docs/book` (clean); `git diff --check` (clean) | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING.1` | `...1: select loop-contained/deeper-nested repeat-body spawn lowering` | `2b0f788b` |
| `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING.2` | `...2: ship loop-contained/deeper-nested repeat-body spawn lowering` | `ship commit (this slice)` |

## Changelog

- `2026-05-29`: Created. Fifth scheduler-frontier slice. Basic spawn + same-body
  drain in loop-contained / deeper-nested repeats; add the drain-requirement
  rule for these contexts; complex spawn variants stay deferred.
- `2026-05-29`: `.1` selection committed (`2b0f788b`).
- `2026-05-29`: `.2` shipped. Spawn gate admits `$loop_body_repeat`/
  `$deeper_nested_repeat`; added the drain-requirement rule + a multi-pending
  await_any deferral; no `_ir_repeat` change. Drain schedule golden-verified
  (spawn → await_all → repeat_check, drained before loop re-entry). Corrected
  the acceptance: repeat-body spawn is lowering + composition level (the
  top-level reference also fails full-HDL `--check-json` via a pre-existing
  composition-wiring limitation), so the slice delivers parity, not HDL. Added
  `t/1383`; repointed 7 test files' spawn-deferral assertions to the
  undrained-spawn drain-requirement. Audit set (15 files, 980) + broad
  regression (123 files, 957) PASS. Tree closed.
