# ISF-LOOP-AND-DEEPER-REPEAT-BODY-MULTI-PENDING-AWAITANY-LOWERING: Enable Loop/Deeper Repeat-Body Multi-Pending `(await_any done)` + Later Drain

## Metadata

- Tree ID: `ISF-LOOP-AND-DEEPER-REPEAT-BODY-MULTI-PENDING-AWAITANY-LOWERING`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-30`
- Last updated: `2026-05-30`
- Owner: repo-local workflow

## Goal

Allow a multi-pending `(await_any done)` (an `await_any` observing two or more
outstanding spawned children) followed by a same-body `(await_all done)` drain
inside a `(repeat ...)` that sits in a single `(while ...)`/`(until ...)` body
or is reached through deeper branch nesting (`when⁺ → repeat`, `switch → when⁺ →
repeat`). Sixth scheduler-frontier slice.

## Ground truth (probed at HEAD)

1. Multi-pending `await_any` + later `await_all` is already supported at
   top-level (`(repeat N (spawn a)(spawn b)(await_any done)(await_all done))`
   ACCEPTED) and in when-body / switch-branch. The spawn slice (#5,
   [[ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING]])
   explicitly DEFERRED it for loop/deeper, scoping that slice to the basic
   single-pending subset, via two confesses at the `await_any` site
   (`@pending_spawns > 1` → `loop-contained`/`deeper-nested repeat-body
   multi-pending '(await_any done)' remains deferred`).
2. So this is a clean nesting extension: remove those two confesses. The
   end-of-validator drain-requirement rule (added in #5) still rejects an
   undrained multi-pending `await_any` (no later `await_all` → `@pending_spawns`
   non-empty at repeat end → drain-requirement confess). The when/switch-specific
   spawn-after / do-after sequencing rules are gated on `$when_body_repeat`/
   `$switch_branch_repeat` and skip loop/deeper — matching the top-level
   behavior, which also has no such restrictions.
3. Reachable shapes/lowering reuse `_ir_repeat`'s `_ir_sync_any`/`_ir_sync_all`
   (no `_ir_repeat` change).

## Scope

- Remove the two `$loop_body_repeat`/`$deeper_nested_repeat` multi-pending
  `await_any` deferral confesses so the observation + later `await_all` drain
  lowers in loop/deeper contexts, consistent with top-level.
- Keep the drain-requirement (undrained still fails closed) and cross-domain
  deferred.

## Non-Goals

- No cross-domain repeat-body `do` (deferred at all nesting levels; net-new CDC
  feature, separate roadmap effort).

## Acceptance Criteria

- `(while cond (repeat N (spawn a)(spawn b)(await_any done)(await_all done)))`
  and the until / deeper-nested forms lower (parity with top-level).
- An undrained multi-pending `await_any` (no later `await_all`) still fails
  closed with the drain-requirement diagnostic.
- New `t/1384-...` golden + (if needed) updates to tests asserting the lifted
  multi-pending deferral.
- Book/spec docs synced; slice audit set + broad regression pass; mdBook clean;
  `git diff --check` clean.
- Each leaf committed via `COMMIT.md`.

## Task Tree

- ID: `ISF-LOOP-AND-DEEPER-REPEAT-BODY-MULTI-PENDING-AWAITANY-LOWERING`
  Status: `done`
  Goal: `Lower loop/deeper repeat-body multi-pending await_any + later drain.`
  Children: `.1`, `.2`

- ID: `ISF-LOOP-AND-DEEPER-REPEAT-BODY-MULTI-PENDING-AWAITANY-LOWERING.1`
  Status: `done`
  Goal: `Select; record probed ground truth.`
  Acceptance: `Task tree committed before any code/test/doc change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `a8805eeb`

- ID: `ISF-LOOP-AND-DEEPER-REPEAT-BODY-MULTI-PENDING-AWAITANY-LOWERING.2`
  Status: `done`
  Goal: `Remove the two multi-pending await_any deferral confesses; add t/1384; sync docs; validate.`
  Acceptance: `Accept-path lowers; undrained still fails closed; audits green.`
  Verification: `prove -Iperl t/1384 t/1383 t/1304 t/1307 t/1305 t/1376 t/1332 t/1250 (Files=8, Tests=859, PASS); broad regression (72 files, 767) PASS; mdbook build docs/book; git diff --check`
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `....1` | `done` | Selection commit `a8805eeb`. |
| 2 | `....2` | `done` | Two deferral confesses removed + `t/1384` + doc sync shipped; tree closed. |

## Decisions

- `2026-05-30`: This completes the nesting frontier (extend top-level/when/switch
  repeat-body activation subsets to loop-contained + deeper-nested). Cross-domain
  repeat-body `do` is explicitly NOT part of this frontier — it is deferred at
  top-level too, so it is net-new CDC lowering, tracked separately.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-30` | `....1` | `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-05-30` | `....2` | `prove -Iperl t/1384 t/1383 t/1304 t/1307 t/1305 t/1376 t/1332 t/1250` (Files=8, Tests=859, PASS); broad regression (72 files, 767) PASS; `mdbook build docs/book`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `....1` | `...1: select loop/deeper multi-pending await_any lowering` | `a8805eeb` |
| `....2` | `...2: ship loop/deeper multi-pending await_any lowering` | `ship commit (this slice)` |

## Changelog

- `2026-05-30`: Created. Sixth scheduler-frontier slice; completes the
  repeat-body-activation nesting frontier. Cross-domain `do` excluded (net-new
  CDC, separate effort).
- `2026-05-30`: `.1` selection committed (`a8805eeb`).
- `2026-05-30`: `.2` shipped. Removed the two multi-pending await_any deferral
  confesses; multi-pending await_any + later await_all now lowers in
  loop/deeper (the drain-requirement still rejects undrained). Added `t/1384`;
  updated `t/1383`. Audit set (8 files, 859) + broad regression (72 files, 767)
  PASS. **Nesting frontier complete.** Tree closed.
