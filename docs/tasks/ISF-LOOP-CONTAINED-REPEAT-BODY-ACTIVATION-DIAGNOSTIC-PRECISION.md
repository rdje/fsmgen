# ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION: Targeted Loop-Contained Repeat-Body Activation Diagnostic

## Metadata

- Tree ID: `ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-27`
- Last updated: `2026-05-27`
- Owner: repo-local workflow

## Goal

Improve diagnostic precision when a `(repeat ...)` clause nested inside a
`(while ...)` or `(until ...)` body contains `do` or `spawn` body
clauses. Currently the validator emits the generic "repeat-body do is
supported only for top-level repeat clauses, top-level when-body nested
repeat clauses, or top-level switch-branch nested repeat clauses"
(symmetric message for `spawn`). That message lists what IS supported
but does not name which deferral lane is blocking the author's case.
Authors who hit this with a loop-contained repeat cannot tell whether
the rejection is from loop containment specifically, deeper when
nesting, or some other case. This slice ships a targeted
`loop-contained repeat-body <do|spawn> remains deferred` diagnostic for
the loop-contained subset; the broader loop-contained implementation
remains backlog.

## Non-Goals

- Do not implement loop-contained repeat activation. The broader
  feature remains a separate future leaf of the same tree.
- Do not change validator behavior for other unsupported nested-repeat
  cases (deeper when nesting, when-inside-switch, etc.). They keep the
  existing generic diagnostic.
- Do not change accepted top-level/branch-contained repeat-body
  semantics.

## Acceptance Criteria

- When a `(repeat ...)` nested inside `(while ...)` or `(until ...)`
  body contains a `do` or `spawn` body clause, the validator emits a
  targeted diagnostic naming `loop-contained repeat-body do remains
  deferred` or `loop-contained repeat-body spawn remains deferred`
  (with the calling transaction name in the diagnostic prefix).
- Other unsupported nested-repeat cases (deeper when nesting,
  when-inside-switch, etc.) continue to emit the existing generic
  "supported only for top-level repeat clauses, top-level when-body
  nested repeat clauses, or top-level switch-branch nested repeat
  clauses" diagnostic.
- A new focused regression `t/1374-isf-loop-contained-repeat-body-activation-diagnostic.t`
  covers four cases: `(while ... (repeat ... (do ...)))`,
  `(until ... (repeat ... (do ...)))`,
  `(while ... (repeat ... (spawn ...)))`,
  `(until ... (repeat ... (spawn ...)))`, plus a negative-control
  deeper-when case confirming the generic message still fires.
- Doc surfaces in `docs/ISF_SPEC.md`,
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, and
  `docs/book/src/14-feature-backlog.md` note the new targeted
  diagnostic. The `ISF_SPEC.md` focused-tests list registers `t/1374`.
- mdBook builds clean; `git diff --check` clean; focused tests pass;
  `./bin/ci-regression isf --no-book` passes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION`
  Status: `pending`
  Goal: `Ship the targeted loop-contained repeat-body activation diagnostic without changing accepted behavior.`
  Children:
    `ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.1`,
    `ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.2`

- ID: `ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.1`
  Status: `pending`
  Goal: `Select the targeted loop-contained diagnostic slice; record scope, helper plan, regression target, and doc-sync targets.`
  Acceptance: `Task tree exists and is committed before any validator change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.2`
  Status: `pending`
  Goal: `Ship the targeted diagnostic at the two unsupported repeat-body subset entry points (do, spawn) plus regression t/1374 plus doc updates.`
  Acceptance: `Loop-contained repeat-body do/spawn now produces the targeted diagnostic; other unsupported nested-repeat cases unchanged; t/1374 passes; ISF CI passes.`
  Verification: `prove -Iperl t/1215 t/1374 t/1250; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Both leaves shipped. `.2` landed the targeted loop-contained diagnostic at the two repeat-body subset entry points (do, spawn), regression `t/1374`, and doc-surface updates. |

## Decisions

- `2026-05-27`: Picked from the Spawn Inside Repeat Bodies deferred
  list. Probed current behavior: `(while cond (repeat loops (do
  worker)))` currently emits the generic "repeat-body do is supported
  only for top-level repeat clauses, top-level when-body nested repeat
  clauses, or top-level switch-branch nested repeat clauses" message.
  The same generic message also fires for deeper when nesting and
  when-inside-switch — the author cannot tell which deferred lane is
  blocking their specific case. This slice ships a targeted
  `loop-contained repeat-body <do|spawn> remains deferred` message
  only for the loop-contained subset; the other unsupported cases
  keep the existing generic message because they may have their own
  diagnostic-precision lanes later.
- `2026-05-27`: New helper
  `_repeat_body_context_is_loop_contained($context_depths)` returns
  true when `while` or `until` has positive depth in the supplied
  `$context_depths` hash. The check fires at both repeat-body subset
  entry points (do at `LoweringIR.pm:6430`, spawn at
  `LoweringIR.pm:6362`) before the existing generic confess. Other
  unsupported nested-repeat contexts fall through to the generic
  message unchanged.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-27` | `ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.1` | `mdbook build docs/book`; `git diff --check` | `PASS`; selection-only commit |
| `2026-05-27` | `ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.2` | `prove -Iperl t/1215 t/1374` (Files=2, Tests=103); `./bin/ci-regression isf --no-book` (Files=280, Tests=2040); `mdbook build docs/book`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.1` | `9a7417f7 ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.1: select loop-contained repeat-body activation diagnostic precision` | Selection commit. |
| `ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.2` | `ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.2: ship loop-contained repeat-body activation diagnostic precision` | `pending commit hash` |

## Changelog

- `2026-05-27`: Created active R14 task tree for the targeted
  loop-contained repeat-body activation diagnostic precision slice.
  Loop-contained repeat activation itself remains deferred; this
  slice ships the user-visible diagnostic improvement and registers
  the broader implementation as a future leaf.
- `2026-05-27`: Shipped `.2`. Validator at
  `perl/FSM/Scheduler/ISF/LoweringIR.pm` now emits the targeted
  diagnostics `Transaction '<tn>': loop-contained repeat-body do
  remains deferred` and `... loop-contained repeat-body spawn remains
  deferred` at the two unsupported-repeat-body subset entry points
  when the validator detects positive `while` or `until` depth in
  `$context_depths`. New helper `_repeat_body_context_is_loop_contained`
  centralises the depth check. Other unsupported nested-repeat cases
  fall through to the existing generic message. New regression
  `t/1374` covers do×while, do×until, spawn×while, spawn×until and
  the negative-control deeper-when / when-inside-switch cases. Doc
  surfaces synchronized in `ISF_SPEC.md` (focused-tests),
  `ISF_DOWNSTREAM_INTEGRATION_SPEC.md` (loop-contained note in the
  nested subset paragraph), and `14-feature-backlog.md`
  (loop-contained sentence in Spawn Inside Repeat Bodies).
