# ISF-LOOP-EARLY-EXIT: `(exit-when cond)` Mid-Loop Early Exit

## Metadata

- Tree ID: `ISF-LOOP-EARLY-EXIT`
- Status: `active`
- Roadmap lane: `R14` (ISF — high-level language richness)
- Created: `2026-06-01`
- Last updated: `2026-06-01`
- Owner: repo-local workflow

## Goal

Give ISF a first-class **mid-loop early exit** — `(exit-when cond)` — so a `while` /
`until` loop can terminate from inside its body the cycle a condition holds, instead
of only at the top/bottom condition test. This is the opening construct of
language-richness theme #3 ("new intent-capture constructs"; see the
`isf-language-richness-frontier` memory): loop early-exit is a universally
recognized high-level control-flow primitive that ISF lacks today, and it lowers to
a single conditional transition to the loop's already-computed exit target.

Reads like:

```lisp
(while busy
  (drive step)
  (sample status as s)
  (exit-when s)          ;; leave the loop the cycle `s` is high
  (drive more))
```

## Ground truth (investigated `2026-06-01`)

- ISF control flow today: `when`, `switch`, `while` (pre-test loop), `until`
  (post-test loop), `repeat` (counted). There is **no** `break` / `continue` /
  mid-body exit in any context — `while`/`until` can only exit at their condition
  decision state (`13d-control-flow.md`).
- `%SUPPORTED_TRANSACTION_CLAUSES` (`FSM/Scheduler/ISF/LoweringIR.pm` ~L14) has no
  `exit-when` keyword in any context.
- Loop lowering (`_ir_while` ~L7780, `_ir_until` ~L7827) builds a `loop_while`/
  `loop_until` decision state (entry and/or check) plus the body states from
  `_expand_loop_body` (~L8470). Each loop entry carries `loop_body_state_names`
  (all body states), `loop_decision_state_names`, and `loop_id`.
- **The clean hook:** `_link_states` (~L10354) computes, for each loop entry, the
  `loop_exit_target` = the state immediately after the loop's last state, and assigns
  it to the loop's decision states. `_link_loop_state` (~L10553) wires the decision
  state's false/true branch to `loop_exit_target`. So the exit target is already
  computed and is exactly what an `(exit-when)` body state must jump to — it just has
  to be resolved in the same pass (the target is not known at `_expand_loop_body`
  time, since it depends on the state after the whole loop).

## Design

- Parser/clause: accept `(exit-when <cond-expr>)` as a body clause in `while` and
  `until` bodies first (the natural home), then `when`/`switch` bodies that are
  themselves inside a loop (later sub-slice). Add `exit-when` to the relevant
  `%SUPPORTED_TRANSACTION_CLAUSES` contexts.
- Lowering: `_expand_loop_body` emits an `exit-when` decision state —
  `{ kind => 'loop_exit_when', condition => <cond>, loop_id => <enclosing loop id>,
  ... }` — with the normal sequential fall-through (cond FALSE → next body clause)
  added by the standard linker. The enclosing `loop_id` is threaded into
  `_expand_loop_body` (the `_ir_while`/`_ir_until` callers already own it).
- Late resolution: in `_link_states`' per-loop pass (~L10354, where `loop_exit_target`
  is computed), for each body state that is a `loop_exit_when` belonging to THIS loop,
  push the TRUE edge `{ target => loop_exit_target, condition => { expr => cond } }`
  ahead of its fall-through, so it renders `(?cond (=1 -> <loop exit>) (=0 ->
  <next body clause>))`.
- Watchdog/latency: an early exit just takes the loop's existing exit edge; the
  watchdog counts the cycles actually spent in the loop (no special handling).
- Fail-closed: `(exit-when)` outside a loop body (top-level, `repeat` body, or a
  `when`/`switch` not inside a loop) fails closed with a targeted diagnostic
  ("`(exit-when)` is only valid inside a `while`/`until` loop body").
- Report: extend the transaction-loop schedule metadata to record `exit_when` sites
  and their exit target (a later sub-slice once the lowering lands).

## Slice plan

- `.1` select (this doc) — scope, ground truth, design, slice plan.
- `.2` `(exit-when cond)` directly in a `while` / `until` body — the core lowering
  (clause vocab + `_expand_loop_body` emit + `_link_states` late resolution); golden
  `.fsm` + HDL; fail-closed outside a loop; `t/` lock.
- `.3` `(exit-when cond)` inside a `when` body that is itself inside a loop (the
  nested-decision case), if the late resolution generalizes; else document the
  boundary.
- `.4` schedule-report metadata for `exit-when` sites + doc-truth/feature-matrix
  sync.
- `.5` docs/examples consolidation (13d runnable example; feature matrix row).

## Non-Goals

- `(continue)` / loop-back-to-condition (a separate, smaller follow-up construct).
- Early exit from `repeat` (counted) bodies — `repeat` is a fixed-count loop; an
  early-exit there changes the counted-iteration contract and is deferred.
- Multi-level break (exit N enclosing loops at once).
- Cross-domain interactions (orthogonal; the loop early-exit is a same-module edge).

## Acceptance Criteria

- `(exit-when cond)` in a `while`/`until` body lowers to a decision state that exits
  the loop when `cond` holds and otherwise continues to the next body clause, with
  golden `.fsm` + HDL evidence; `(exit-when)` outside a loop body fails closed with a
  targeted diagnostic; the `13d` control-flow page documents it with a runnable
  example that lowers; feature-matrix/doc-truth audits pass. Each leaf committed via
  `COMMIT.md`.

## Task Tree

- ID: `ISF-LOOP-EARLY-EXIT`
  Status: `active`
  Goal: `(exit-when cond) mid-loop early exit for while/until bodies.`
  Children: `.1` (select), `.2` (core lowering), `.3` (when-in-loop), `.4` (report), `.5` (docs)

- ID: `ISF-LOOP-EARLY-EXIT.1`
  Status: `done`
  Goal: `Select; record ground truth (no early-exit today; loop_exit_target hook) + design + slice plan.`
  Acceptance: `Task tree committed before any code change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `6c6db3d6`

- ID: `ISF-LOOP-EARLY-EXIT.2`
  Status: `done`
  Goal: `Core (exit-when cond) lowering directly inside while/until bodies.`
  Acceptance: `exit-when added to the while/until clause-context allow-lists; _expand_loop_body emits a 'loop_exit_when' decision state (condition => cond); _link_states' per-loop pass stamps the loop's loop_exit_target onto the exit-when body states, and the main linker pushes the TRUE edge (loop_branch 1 -> loop_exit_target) + FALSE edge (loop_branch 0 -> next clause); the FSM emitter renders 'loop_exit_when' like the loop decision states. (exit-when go) in a while body lowers to (?go (=1 -> loop exit)(=0 -> next clause)) and continues/exits correctly; (exit-when) outside a while/until body (top-level, repeat, when, switch) fails closed with "unsupported '(exit-when ...)' clause in <ctx>"; a bare (exit-when) without a condition fails closed; --check-json + verilator/yosys PASS; 13d documents it with a runnable example; 13k row + ISF_SPEC focused-test index updated; t/1389 locks it.`
  Verification: `Spike: (while busy (update ...)(exit-when go)(update ...)) lowers to main_exit_when_N (?go (=1 -> loop exit)(=0 -> next)); until lowers; top-level/repeat/when defer; bare exit-when defers; --check-json SUCCESS; --verify-hdl verilator_lint+yosys_synthesis PASS. prove -Iperl t/1389 (5 subtests) t/1250 t/1376 (42) t/1305 t/1304 t/1307 t/1303 PASS; full ./bin/ci-regression isf --no-book PASS; perl -c (LoweringIR + Emitter/FSM); mdbook build; git diff --check`
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design (this doc). |
| 2 | `.2` | `done` | `(exit-when cond)` lowers in `while`/`until` bodies to a `loop_exit_when` decision (true → loop exit target, false → next clause); fails closed elsewhere; `--check-json` + verilator/yosys PASS. `t/1389`. |
| 3 | `.3`–`.5` | `pending` | when-in-loop exit-when; schedule-report metadata; docs/examples consolidation. |

## Decisions

- `2026-06-01`: theme #3 (new intent-capture constructs) opens with loop early-exit
  because it is the most bounded high-value gap: ISF has no mid-loop exit, the
  `loop_exit_target` is already computed in `_link_states`, and the construct lowers
  to a single conditional edge. Chosen over `(for (i N) ...)` indexed loops (needs a
  loop-local variable scope model) and inline sub-transactions (needs new
  definition-site grammar + expression templating) as the first slice.

## Open Questions

- `.3`: whether a `(exit-when)` inside a `when` body nested in a loop can reuse the
  same late-resolution (the `when` body states are part of the loop's
  `loop_body_state_names`), or whether the `when` selector's exit interacts with the
  loop exit. Resolve empirically in `.3`.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-01` | `.1` | `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-06-01` | `.2` | Spike: while/until `(exit-when)` lowers (`?cond` decision: true→loop exit, false→next clause); top-level/repeat/when/bare defer; `--check-json` SUCCESS; `--verify-hdl` verilator_lint+yosys_synthesis PASS. `prove -Iperl t/1389` (5 subtests) `t/1250 t/1376` (42) `t/1305 t/1304 t/1307 t/1303` PASS; full `./bin/ci-regression isf --no-book` PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-LOOP-EARLY-EXIT.1: select loop early-exit (exit-when)` | `6c6db3d6` |
| `.2` | `ISF-LOOP-EARLY-EXIT.2: (exit-when cond) mid-loop early exit in while/until bodies` | `ship commit (this slice)` |

## Changelog

- `2026-06-01`: Created as the opening slice of language-richness theme #3 (new
  intent-capture constructs). Selected `(exit-when cond)` mid-loop early exit as the
  first construct (bounded, high-value, clean `loop_exit_target` hook). Recorded
  ground truth (no early-exit today; loop lowering + `_link_states` exit-target
  computation) and the slice plan (`.2` core lowering, `.3` when-in-loop, `.4`
  report, `.5` docs).
- `2026-06-01`: `.2` shipped — `(exit-when cond)` mid-loop early exit now lowers
  directly inside `while`/`until` bodies. Added `exit-when` to the `while`/`until`
  clause-context allow-lists (`%SUPPORTED_TRANSACTION_CLAUSES`). `_expand_loop_body`
  emits a `loop_exit_when` decision state (`condition => cond`) with a malformed-clause
  guard. In `_link_states`, the per-loop pass (which already computes each loop's
  `loop_exit_target` = the state after the loop) now also stamps that target onto the
  loop's `loop_exit_when` body states; the main linker then pushes the TRUE edge
  (`loop_branch` 1 → `loop_exit_target`) and the FALSE edge (`loop_branch` 0 → the
  next body clause). The FSM emitter (`Emitter/FSM.pm`) renders `loop_exit_when` like
  the `loop_while`/`loop_until` decision states, so a `(exit-when go)` lowers to
  `(?go (=1 (-> <loop exit>)) (=0 (-> <next clause>)))`. Verified end-to-end: the
  exit edge reuses the loop's natural exit target, the false edge continues the body,
  `--check-json` SUCCEEDS, and `--verify-hdl` passes (verilator_lint + yosys_synthesis).
  `(exit-when)` outside a `while`/`until` body (top-level, `repeat`, `when`/`switch`)
  fails closed with `unsupported '(exit-when ...)' clause in <ctx>`, and a bare
  `(exit-when)` without a condition fails closed. Book: `13d` gains a dedicated
  `(exit-when)` section with a runnable example; the `13k` "Transaction control flow"
  row lists it; `docs/ISF_SPEC.md` registers `t/1389`. `t/1389` (5 subtests) locks
  while/until lowering, the loop-exit/continue edges, HDL-shape (one true + one false
  edge), and all four fail-closed contexts.
