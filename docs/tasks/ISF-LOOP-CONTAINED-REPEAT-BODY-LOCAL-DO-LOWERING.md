# ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING: Enable Loop-Contained Repeat-Body Local `(do)` Lowering

## Metadata

- Tree ID: `ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-29`
- Last updated: `2026-05-29`
- Owner: repo-local workflow

## Goal

Allow a plain local `(do child)` inside a `(repeat N ...)` whose repeat is
directly contained in one `(while cond ...)` or `(until cond ...)` loop body
to lower cleanly, instead of failing closed with
`loop-contained repeat-body do remains deferred`. This is scheduler-frontier
item #1 (loop-contained repeat-body local-do lowering), user-confirmed after
the SPECFORGE enum↔type clarity slice.

The supported shape:

```text
(transaction parent
  (on start)
  (while cond
    (repeat loops
      (do worker)))
  (complete done))
```

## Ground truth (probed at `bin/fsmgen` HEAD, by reading the lowerer)

1. The fail-closed is **validator-only**. `_validate_repeat_body_spawn_subset`
   (`perl/FSM/Scheduler/ISF/LoweringIR.pm`) confesses
   `loop-contained repeat-body do remains deferred` at the `do` branch
   (~L6434-6441) when `_repeat_body_context_is_loop_contained($context_depths)`
   is true and the repeat is not top-level / when-body / switch-branch.
2. The **lowering already handles** a repeat-body `(do ...)`: `_ir_repeat`
   (~L8170) emits `repeat_init` → body states (including `_ir_do` for the
   `do`) → `repeat_check` (loops back to the first body state). This same
   code runs for loop bodies via `_expand_loop_body` (~L8114, called by
   `_ir_while`/`_ir_until`).
3. For a **plain local do** (`generated_child == 0`), `_repeat_do_ref_from_clause`
   (~L5388) builds `{child, activation_kind=>'do', generated_child=>0}` and the
   `$ordinal`/`$constant_values`/`$generated_children`/`$spawn_refs` arguments
   are only consumed inside the `if ($generated_child)` branch or for spawn.
   So the four trailing `_ir_repeat` parameters that `_expand_loop_body` does
   **not** thread (~L8146) are not needed for the local-do case; the existing
   loop-body lowering path produces a correct schedule for a plain local do.
   No lowering change is required — this is a validator gate relaxation only.
4. **Outer-loop semantics are unambiguous.** The while/until back-edge
   re-enters the loop body at `repeat_init`, which re-seeds the repeat counter
   each iteration. So `(while cond (repeat N (do child)))` means "while `cond`,
   run the repeat block (N child activations) once per loop iteration." No
   scheduling-semantics decision needs escalation.

## Scope (this tree)

- **Enable only a plain local `(do child)`** (no `(params ...)`, no
  `(bind ...)`, no `(domain ...)`, and `child` is not a generated child) inside
  a repeat that sits **directly** in a single `(while ...)`/`(until ...)` body
  (`context_depths` exactly `{while => 1}` or `{until => 1}`).
- Keep deferred (fail closed) in a loop-contained repeat:
  - `spawn` (unchanged: `loop-contained repeat-body spawn remains deferred`).
  - generated `do` (with `(params/bind/domain)` or a generated-child target):
    new targeted message `loop-contained repeat-body generated do remains
    deferred; only a plain local '(do child)' is supported inside a
    loop-contained repeat`.
  - deeper loop nesting (`while` depth > 1, or a loop combined with
    `when`/`switch`): unchanged `loop-contained repeat-body do remains
    deferred` / `deeper-nested repeat-body do remains deferred`.

## Non-Goals

- No `spawn`, generated `do`, `await_all`/`await_any`, or cross-domain support
  inside a loop-contained repeat (still deferred; separate future trees).
- No deeper-than-one loop nesting and no loop+branch combinations.
- No change to top-level / when-body / switch-branch repeat-body behavior.

## Acceptance Criteria

- A plain local `(do child)` inside a single `(while ...)`/`(until ...)`
  -contained `(repeat ...)` lowers cleanly to a schedule with `loop_while`/
  `loop_until` entry/check states wrapping `repeat_init` → blocking-do →
  `repeat_check`, and the schedule round-trips (`--check-json` / HDL emit).
- Loop-contained repeat-body `spawn` and generated `do` still fail closed with
  their targeted diagnostics.
- New `t/1379-isf-loop-contained-repeat-body-local-do.t` golden-verifies the
  accept-path schedule and the still-deferred cases.
- `t/1374` (loop-contained activation diagnostic) updated: the local-do
  while/until cases that now lower are replaced by the generated-do deferral;
  the spawn and deeper-nested subtests are unchanged.
- Book/spec docs synced: `13d-control-flow.md` gains a runnable `lisp`
  accept example for loop-contained local do (gated by `t/1376`) and keeps a
  `text` deferral example for spawn/generated do; `13k`, `14`, `13h`, `13b`,
  `ISF_SPEC.md`, `ISF_DOWNSTREAM_INTEGRATION_SPEC.md`,
  `ISF_PUBLIC_INTERFACE_CONTRACT.md`, `SPECFORGE_FEEDBACK_RESPONSE.md` updated.
- `prove -Iperl t/1379 t/1374 t/1375 t/1307 t/1305 t/1376 t/1332 t/1250`
  passes; broader repeat/loop regression passes; mdBook clean; `git diff
  --check` clean.
- Each leaf committed via `COMMIT.md`.

## Task Tree

- ID: `ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING`
  Status: `active`
  Goal: `Lower loop-contained repeat-body plain local (do); keep spawn/generated-do deferred.`
  Children:
    `ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING.1`,
    `ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING.2`

- ID: `ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING.1`
  Status: `pending`
  Goal: `Select the slice; record probed ground truth, scope, and the validator-only plan.`
  Acceptance: `Task tree committed before any code/test/doc change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING.2`
  Status: `pending`
  Goal: `Relax the validator gate for plain local do; add t/1379 golden + update t/1374; sync docs; validate.`
  Acceptance: `Accept-path lowers + round-trips; deferred cases still fail closed; audits green.`
  Verification: `prove -Iperl t/1379 t/1374 t/1375 t/1307 t/1305 t/1376 t/1332 t/1250; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING.1` | `pending` | Selection commit before any code/test/doc change. |
| 2 | `ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING.2` | `pending` | Ship the validator relaxation + golden + doc sync. |

## Decisions

- `2026-05-29`: Scope to **plain local `(do)` only**, matching the user's
  "loop-contained repeat-body local-do lowering" framing and the conservative
  precedent set by the when-body/switch-branch enablement (start with the
  cleanest sub-case, keep spawn/generated-do/await-sync deferred).
- `2026-05-29`: Implement as a **validator gate relaxation, not a lowering
  change** — the lowering path already produces a correct schedule for a plain
  local do; only the deferral confess blocks it. This keeps the blast radius
  minimal and verifiable.
- `2026-05-29`: Restrict to a repeat **directly** in a single loop body
  (`context_depths` exactly `{while=>1}`/`{until=>1}`) to mirror the
  exactly-depth-1 rule used for when-body/switch-branch repeats; deeper
  nesting stays deferred.

## Open Questions

- None blocking. (Outer-loop counter re-seed semantics are unambiguous; see
  Ground truth #4.)

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-29` | `ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING.1` | `mdbook build docs/book`; `git diff --check` | `pending` |
| `2026-05-29` | `ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING.2` | `prove -Iperl t/1379 t/1374 t/1375 t/1307 t/1305 t/1376 t/1332 t/1250`; `mdbook build docs/book`; `git diff --check` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING.1` | `ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING.1: select loop-contained repeat-body local-do lowering` | `pending commit hash` |
| `ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING.2` | `ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING.2: ship loop-contained repeat-body local-do lowering` | `pending commit hash` |

## Changelog

- `2026-05-29`: Created. Scheduler-frontier #1, user-confirmed. Validator-only
  enablement of plain local `(do)` inside a single while/until-contained
  repeat; spawn and generated-do stay deferred.
