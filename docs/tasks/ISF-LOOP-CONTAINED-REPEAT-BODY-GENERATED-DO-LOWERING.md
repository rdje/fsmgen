# ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING: Enable Loop-Contained Repeat-Body Generated `(do)` Lowering

## Metadata

- Tree ID: `ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-29`
- Last updated: `2026-05-29`
- Owner: repo-local workflow

## Goal

Allow a **same-domain generated** `(do child ...)` — a `(do)` carrying static
`(params ...)` (optionally with `(bind ...)` / `(domain NAME)`), or targeting a
generated child — inside a `(repeat N ...)` that sits directly in one
`(while cond ...)` or `(until cond ...)` loop body to lower cleanly. This is
the second scheduler-frontier slice (after loop-contained local-do, shipped in
[[ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING]]). The user directed that
all frontier items ship, in any order.

## Ground truth (probed at `bin/fsmgen` HEAD)

1. After the local-do slice, a generated `do` in a loop-contained repeat fails
   closed with `loop-contained repeat-body generated do remains deferred`
   (added by the prior slice as the targeted message). spawn stays deferred.
2. The lowering of a repeat-body generated do is already implemented in
   `_ir_repeat` (`perl/FSM/Scheduler/ISF/LoweringIR.pm` ~L8189): it builds the
   generated-child instance via `_repeat_do_ref_from_clause` (ordinal-named
   `<tn>_<child>_repeat_do_<ord>`), pushes the clone onto `$spawn_refs` so the
   composition planner instantiates the child module, and emits a blocking-do
   state that asserts `<instance>_start` and awaits `<instance>_done`.
3. The gap is that `_expand_loop_body` (~L8157) calls `_ir_repeat` **without**
   the four trailing params `$spawn_refs`, `$constant_values`,
   `$generated_children`, `$repeat_do_ordinal_ref`. Unlike the local-do case
   (which does not consume them), a generated do needs all four:
   `$generated_children`/`$constant_values` to classify + resolve overrides,
   `$repeat_do_ordinal_ref` for a transaction-unique instance name, and
   `$spawn_refs` so the generated child is actually instantiated.
4. All four are in scope at the `while`/`until` dispatch in
   `_validate`/lower (`\@spc`, `$constant_values`, `$generated_children`,
   `\$repeat_do_ordinal`, LoweringIR.pm ~L4648/4656), so they can be threaded
   through `_ir_while`/`_ir_until` → `_expand_loop_body` → `_ir_repeat`.
5. Reference: a top-level `(repeat loops (do worker (params (W 8))))` lowers to
   three files (`parent.fsm`, `parent_top.fsm`, `worker.fsm`) with instance
   `parent_worker_repeat_do_0` and `..._start`/`..._done` ports.
6. **Semantics (non-blocking decision):** one lexical generated-do site is
   lowered once, so it produces **one** generated child instance, re-triggered
   on each loop/repeat iteration (identical reuse to the local-do worker and to
   the top-level generated-do). A blocking generated do is not a spawn; it
   needs no `await_all` drain and creates no pending-spawn obligation.

## Scope (this tree)

- Enable **same-domain** generated `(do child ...)` inside a repeat directly in
  a single `(while ...)`/`(until ...)` body (`context_depths` exactly
  `{while=>1}`/`{until=>1}`), including static `(params ...)`, and `(bind ...)`/
  `(domain NAME)` when paired with static `(params ...)` — mirroring the
  top-level repeat-body generated-do subset.
- Keep deferred: cross-domain generated do (`cross-domain repeat-body do
  remains deferred`), `spawn` (`loop-contained repeat-body spawn remains
  deferred`), bindings/domain without static params, and repeats reached
  through an extra branch/loop ancestor (`loop-contained repeat-body do
  remains deferred`).

## Non-Goals

- No `spawn` / `await_all` / `await_any` inside a loop-contained repeat.
- No cross-domain generated do (separate frontier item).
- No deeper loop/branch nesting.

## Acceptance Criteria

- A same-domain generated `(do child (params ...))` (and the `(bind)`/`(domain)`
  variants with params) inside a single `(while ...)`/`(until ...)`-contained
  repeat lowers, instantiates the generated child in the `_top` composition,
  and emits HDL (`--check-json` success + SystemVerilog emit).
- Cross-domain generated do, spawn, params-less bindings/domain, and
  extra-nesting cases still fail closed with their targeted diagnostics.
- New `t/1380-isf-loop-contained-repeat-body-generated-do.t` golden-verifies
  the accept path (schedule + child instantiation) and the still-deferred
  cases. `t/1374`/`t/1379` updated where they asserted the generated-do
  deferral that is now lifted.
- Book/spec docs synced (13d, 13k, 14, 13h, 13b, ISF_SPEC + focused-test
  index, downstream/contract/SPECFORGE response).
- `prove -Iperl t/1380 t/1379 t/1374 t/1375 t/1304 t/1307 t/1305 t/1376 t/1332
  t/1250` passes; repeat/loop + do/spawn/activation/lowering regression passes;
  mdBook clean; `git diff --check` clean.
- Each leaf committed via `COMMIT.md`.

## Task Tree

- ID: `ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING`
  Status: `done`
  Goal: `Lower same-domain loop-contained repeat-body generated (do); keep cross-domain/spawn deferred.`
  Children:
    `ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING.1`,
    `ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING.2`

- ID: `ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING.1`
  Status: `done`
  Goal: `Select the slice; record probed ground truth, threading plan, and scope.`
  Acceptance: `Task tree committed before any code/test/doc change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `3aafad9d`

- ID: `ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING.2`
  Status: `done`
  Goal: `Thread the 4 params through _ir_while/_ir_until/_expand_loop_body; add loop-body discovery to the generated-child collector; relax the validator for same-domain generated do; add t/1380; sync docs; validate.`
  Acceptance: `Accept-path lowers + instantiates child + emits HDL; deferred cases still fail closed; audits green.`
  Verification: `prove -Iperl t/1380 t/1379 t/1374 t/1375 t/1304 t/1307 t/1305 t/1376 t/1332 t/1250 (Files=11, Tests=870, PASS); broad regression (103 files, 933) PASS; --check-json + 3-module SV emit; mdbook build docs/book; git diff --check`
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING.1` | `done` | Selection commit `3aafad9d`. |
| 2 | `ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING.2` | `done` | Threading + collector discovery + validator relaxation + `t/1380` golden + doc sync shipped; tree closed. |

## Decisions

- `2026-05-29`: Unlike the local-do slice, thread the four trailing
  `_ir_repeat` parameters through the loop-body lowering path — a generated do
  genuinely consumes them (instance naming, override resolution, and child
  instantiation via `$spawn_refs`).
- `2026-05-29`: Keep cross-domain generated do and spawn deferred; this slice
  is same-domain blocking generated `do` only, mirroring the top-level subset.
- `2026-05-29`: One generated child instance per lexical do site, re-triggered
  each loop iteration (the only sensible blocking-do reuse; matches top-level).

## Open Questions

- None blocking.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-29` | `ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING.1` | `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-05-29` | `ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING.2` | `prove -Iperl t/1380 t/1379 t/1374 t/1375 t/1372 t/1304 t/1307 t/1305 t/1376 t/1332 t/1250` (Files=11, Tests=870, PASS); broad regression (103 files, 933) PASS; `--check-json` success + 3-module SV emit; `mdbook build docs/book` (clean); `git diff --check` (clean) | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING.1` | `ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING.1: select loop-contained repeat-body generated-do lowering` | `3aafad9d` |
| `ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING.2` | `ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING.2: ship loop-contained repeat-body generated-do lowering` | `ship commit (this slice)` |

## Changelog

- `2026-05-29`: Created. Second scheduler-frontier slice. Same-domain generated
  `(do)` inside a single while/until-contained repeat; thread the four
  `_ir_repeat` params through the loop-body path; cross-domain and spawn stay
  deferred.
- `2026-05-29`: `.1` selection committed (`3aafad9d`).
- `2026-05-29`: `.2` shipped. Threaded the four params through
  `_ir_while`/`_ir_until`/`_expand_loop_body`; added the `while`/`until`→repeat
  branch to `_child_action_refs_from_transaction_clauses` (the real blocker —
  generated children activated only from a loop were not being discovered);
  extended the validator `do` gate + bindings/domain-require-params for
  `$loop_body_repeat`; removed the obsolete generated-do deferral message.
  Verified `--check-json` + 3-module SV emit with the child instantiated using
  the `(W 8)` override. Added `t/1380`; updated `t/1374`/`t/1379`; synced
  book/spec docs (13d count 34→35). All validation green; tree closed.
