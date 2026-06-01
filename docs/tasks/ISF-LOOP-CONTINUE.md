# ISF-LOOP-CONTINUE: `(continue-when cond)` Skip-To-Next-Iteration

## Metadata

- Tree ID: `ISF-LOOP-CONTINUE`
- Status: `active`
- Roadmap lane: `R14` (ISF — high-level language richness)
- Created: `2026-06-01`
- Last updated: `2026-06-01`
- Owner: repo-local workflow

## Goal

`(continue-when cond)` — the loop *continue* primitive, the companion to
`(exit-when cond)` (loop early-exit, `ISF-LOOP-EARLY-EXIT`). Directly inside a
`while`/`until` body, when `cond` holds it **skips the rest of the current iteration**
and jumps to the loop's tail condition check (which re-evaluates and either loops again
or exits); otherwise control falls through to the next body clause. Together,
`(exit-when)` + `(continue-when)` are the break/continue pair of a high-level loop.

```lisp
(while busy
  (sample din as s)
  (continue-when (== s 0))   ;; skip zero bytes, re-check the loop condition
  (call process s))
```

## Ground truth (from `ISF-LOOP-EARLY-EXIT`)

- `(exit-when cond)` already lowers to a `loop_exit_when` decision state whose TRUE
  edge takes the loop's `loop_exit_target` (computed in `_link_states`' per-loop pass)
  and whose FALSE edge continues to the next clause; the FSM emitter renders it like a
  loop decision (`Emitter/FSM.pm`). `(continue-when)` is the *same machinery* with a
  different TRUE target: the loop's **tail check** state instead of the exit.
- Each loop entry carries `loop_decision_state_names` (`_ir_while`: `[entry, back]`;
  `_ir_until`: `[check]`). The **tail check** — the decision reached after the body —
  is `loop_decision_state_names[-1]` (the `while_check` for `while`, the `until_check`
  for `until`). Jumping there re-evaluates the condition: exactly "continue".

## Design

- Allow-list: add `continue-when` to the `while`/`until` (and `when`, for a
  loop-nested `when`) clause contexts, mirroring `exit-when`.
- Lowering: emit a `loop_continue_when` decision state (kind shared with
  `loop_exit_when` rendering). In `_link_states`' per-loop pass, stamp the loop's tail
  check (`loop_decision_state_names[-1]`) as the continue target onto
  `loop_continue_when` body states (mirroring the `loop_exit_target` stamping); the
  main linker pushes TRUE → continue-target, FALSE → next clause.
- Reuse `(exit-when)`'s post-hoc safety: a `(continue-when)` not inside a loop fails
  closed.

## Slice plan

- `.1` select (this doc).
- `.2` `(continue-when cond)` in `while`/`until` bodies — the core lowering (mirror
  `exit-when`); golden `.fsm` + `--verify-hdl`; fail-closed outside a loop; `t/`.
- `.3` `(continue-when)` inside a `when` nested in a loop (mirror the exit-when
  when-nested slice) + docs (13d section/example).

## Non-Goals

- `continue` in `repeat` (counted) bodies (changes the counted contract — deferred).
- Multi-level continue.

## Acceptance Criteria

- `(continue-when cond)` in a `while`/`until` body lowers to a decision that jumps to
  the loop's tail check when `cond` holds and otherwise continues to the next clause,
  with golden `.fsm` + `--verify-hdl`; `(continue-when)` outside a loop fails closed;
  13d documents it with a runnable example; audits pass. Each leaf committed via
  `COMMIT.md`.

## Task Tree

- ID: `ISF-LOOP-CONTINUE`
  Status: `active`
  Goal: `(continue-when cond) skip-to-next-iteration in while/until bodies (companion to exit-when).`
  Children: `.1` (select), `.2` (core lowering), `.3` (when-in-loop + docs)

- ID: `ISF-LOOP-CONTINUE.1`
  Status: `done`
  Goal: `Select; reuse the exit-when machinery with the loop tail-check as the continue target.`
  Acceptance: `Task tree committed before any code change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `629722d1`

- ID: `ISF-LOOP-CONTINUE.2`
  Status: `done`
  Goal: `(continue-when cond) in while/until bodies — skip to the loop tail check.`
  Acceptance: `continue-when added to the while/until/when clause allow-lists; _expand_loop_body/_expand_when emit a decision state of the shared kind loop_exit_when marked loop_continue_when; _link_states' per-loop pass stamps the loop tail check (loop_decision_state_names[-1]) as the TRUE target for continue-when states (vs the exit target for exit-when), reusing the same main-linker + emitter + not-in-a-loop safety path. (continue-when skip) in a while body -> (?skip (=1 -> <while_check>)(=0 -> <next clause>)); until likewise targets the until check; exit-when behavior unchanged. --check-json + verilator/yosys PASS; outside a while/until body fails closed. 13d gains a (continue-when) section; 13k row; ISF_SPEC registers t/1393.`
  Verification: `Spike: (while busy ...(continue-when skip)...) -> continue_when (?skip (=1 -> while_check)(=0 -> next)); until -> until_check; exit-when regress OK; top-level/repeat fail closed; --check-json SUCCESS; --verify-hdl PASS. prove -Iperl t/1393 (3 subtests) t/1389 t/1376 t/1305 t/1250 t/1304 t/1307 PASS; full ./bin/ci-regression isf --no-book PASS; perl -c; mdbook build; git diff --check`
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design (this doc). |
| 2 | `.2` | `done` | `(continue-when cond)` in `while`/`until` bodies — decision state (shared `loop_exit_when` kind, `loop_continue_when` marker) whose TRUE edge jumps to the loop tail check; FALSE → next clause. `--check-json`+verilator/yosys PASS. `t/1393`. |
| 3 | `.3` | `pending` | when-in-loop + docs. |

## Decisions

- `2026-06-01`: implement as the companion to `(exit-when)`, reusing the
  `loop_exit_when` decision machinery with the loop tail check
  (`loop_decision_state_names[-1]`) as the TRUE target instead of `loop_exit_target`.
  ISF/IAL1 desugar (one decision edge). Chosen as the next theme-#3 construct (per the
  user, after `ISF-REGISTER-RESET-VALUES.2`).

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-01` | `.1` | `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-06-01` | `.2` | Spike: while/until `(continue-when)` jumps to the loop tail check; exit-when unchanged; top-level/repeat fail closed; `--check-json` + verilator/yosys PASS. `prove -Iperl t/1393` (3 subtests) `t/1389 t/1376 t/1305 t/1250 t/1304 t/1307` PASS; full `./bin/ci-regression isf --no-book` PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-LOOP-CONTINUE.1: select (continue-when) skip-to-next-iteration` | `629722d1` |
| `.2` | `ISF-LOOP-CONTINUE.2: (continue-when cond) in while/until bodies` | `ship commit (this slice)` |

## Changelog

- `2026-06-01`: Created as the companion to `ISF-LOOP-EARLY-EXIT` — `(continue-when
  cond)` skip-to-next-iteration, reusing the `loop_exit_when` decision machinery with
  the loop tail check as the continue target. Slice plan: `.2` core lowering, `.3`
  when-in-loop + docs.
- `2026-06-01`: `.2` shipped — `(continue-when cond)` in `while`/`until` bodies. Added
  `continue-when` to the `while`/`until`/`when` clause-context allow-lists;
  `_expand_loop_body`/`_expand_when` emit a decision state of the shared kind
  `loop_exit_when` marked `loop_continue_when`. `_link_states`' per-loop pass stamps the
  loop's TAIL check (`loop_decision_state_names[-1]`) as the TRUE target for
  continue-when states (vs the exit target for exit-when), reusing the same main-linker,
  FSM-emitter, and not-in-a-loop safety path. So `(continue-when skip)` lowers to
  `(?skip (=1 -> <loop tail check>) (=0 -> <next clause>))` — jumping to the tail check
  re-evaluates the loop condition (continue), while exit-when's behavior is unchanged.
  Verified `--check-json` SUCCEEDS and `--verify-hdl` passes (verilator + yosys); a
  `(continue-when)` outside a `while`/`until` body fails closed. Book: `13d` gains a
  `(continue-when)` section; `13k` control-flow row lists it; `docs/ISF_SPEC.md`
  registers `t/1393`. With `(exit-when)` + `(continue-when)`, ISF loops have the full
  break/continue pair.
