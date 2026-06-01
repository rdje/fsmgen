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
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design (this doc). |
| 2 | `.2` | `pending` | Core `(continue-when cond)` in `while`/`until` bodies — mirrors `exit-when`, low risk. |
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

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-LOOP-CONTINUE.1: select (continue-when) skip-to-next-iteration` | `ship commit (this slice)` |

## Changelog

- `2026-06-01`: Created as the companion to `ISF-LOOP-EARLY-EXIT` — `(continue-when
  cond)` skip-to-next-iteration, reusing the `loop_exit_when` decision machinery with
  the loop tail check as the continue target. Slice plan: `.2` core lowering, `.3`
  when-in-loop + docs.
