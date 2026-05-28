# ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION: Targeted Deeper-Nested Repeat-Body Activation Diagnostic

## Metadata

- Tree ID: `ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION`
- Status: `pending`
- Roadmap lane: `R14`
- Created: `2026-05-27`
- Last updated: `2026-05-27`
- Owner: repo-local workflow

## Goal

Complete the diagnostic-precision split at the two unsupported
repeat-body subset entry points
(`_validate_repeat_body_spawn_subset`/`_validate_repeat_body_do_subset`).
After the prior loop-contained slice landed, the remaining unsupported
contexts that reach the existing generic "repeat-body do/spawn is
supported only for top-level repeat clauses, top-level when-body nested
repeat clauses, or top-level switch-branch nested repeat clauses"
message are all *deeper-nested* shapes — deeper when-in-when nesting
and when-inside-switch nesting. Emit a targeted
`deeper-nested repeat-body <do|spawn> remains deferred` diagnostic for
those cases, keeping the generic message as a safety-net fallback for
any future shape not yet classified.

## Non-Goals

- Do not implement deeper-nested repeat activation. The broader
  feature remains a separate future leaf of the same tree.
- Do not change loop-contained handling (the prior slice's targeted
  diagnostic still fires first).
- Do not change accepted top-level/when-1/switch-1 repeat semantics.
- Do not change the existing "unsupported '(switch ...)' clause in
  when/switch body" diagnostics that already fire for
  switch-inside-when or switch-inside-switch.

## Acceptance Criteria

- When a `(repeat ...)` with a `do` or `spawn` body clause is nested
  inside a non-loop deeper context (more than one `when` ancestor, or
  a `when` ancestor inside a `switch` branch), the validator emits a
  targeted diagnostic naming `deeper-nested repeat-body do remains
  deferred` or `deeper-nested repeat-body spawn remains deferred`
  (with the calling transaction name in the diagnostic prefix).
- Loop-contained cases still fire their existing targeted
  `loop-contained repeat-body <do|spawn> remains deferred` diagnostic.
- The original generic "supported only for top-level repeat clauses,
  top-level when-body nested repeat clauses, or top-level switch-branch
  nested repeat clauses" message remains as a safety-net fallback.
- Existing focused regression `t/1215-isf-spawn-parameter-binding.t`
  expectations are refreshed for the three deeper-nested cases (lines
  10399, 10471, 10487) that previously matched the generic message.
- A new focused regression
  `t/1375-isf-deeper-nested-repeat-body-activation-diagnostic.t`
  covers the four deeper-nested cases (do×deeper-when,
  do×when-inside-switch, spawn×deeper-when, spawn×when-inside-switch)
  plus a negative-control loop-contained case confirming the
  loop-contained diagnostic still fires first.
- Doc surfaces in `docs/ISF_SPEC.md`,
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, and
  `docs/book/src/14-feature-backlog.md` note the new targeted
  diagnostic. The `ISF_SPEC.md` focused-tests list registers
  `t/1375`.
- mdBook builds clean; `git diff --check` clean; focused tests pass;
  `./bin/ci-regression isf --no-book` passes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION`
  Status: `pending`
  Goal: `Ship the targeted deeper-nested repeat-body activation diagnostic without changing accepted behavior.`
  Children:
    `ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.1`,
    `ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.2`

- ID: `ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.1`
  Status: `pending`
  Goal: `Select the targeted deeper-nested diagnostic slice; record scope, helper plan, regression target, and doc-sync targets.`
  Acceptance: `Task tree exists and is committed before any validator change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.2`
  Status: `pending`
  Goal: `Ship the targeted diagnostic at the two repeat-body subset entry points plus t/1375 plus t/1215 refresh plus doc updates.`
  Acceptance: `Deeper-nested repeat-body do/spawn produces the targeted diagnostic; loop-contained unchanged; t/1375 passes; ISF CI passes.`
  Verification: `prove -Iperl t/1215 t/1374 t/1375; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.1` | `pending` | Selection commit must land before the validator change so the slice is owned through `COMMIT.md`. |
| 2 | `ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.2` | `pending` | Ship the targeted diagnostic plus regression plus doc sync. |

## Decisions

- `2026-05-27`: Picked from the Spawn Inside Repeat Bodies deferred
  list as the follow-on to the loop-contained slice. After
  loop-contained is caught first, the only remaining unsupported
  cases reaching the generic "supported only..." message are
  deeper-when and when-inside-switch. Both will collapse under one
  targeted `deeper-nested repeat-body <do|spawn> remains deferred`
  diagnostic; the generic message remains as a safety-net fallback.
- `2026-05-27`: Reuse `_context_depths_match_exactly` rather than
  introducing a new helper. The deeper-nested check is essentially
  "after loop-contained excluded, the remaining unsupported cases":
  `!$top_level_repeat && !$when_body_repeat && !$switch_branch_repeat
  && !_repeat_body_context_is_loop_contained($context_depths)`. We
  capture that with an inline test rather than a third helper.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-27` | `ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.1` | `mdbook build docs/book`; `git diff --check` | `pending` |
| `2026-05-27` | `ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.2` | `prove -Iperl t/1215 t/1374 t/1375`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.1` | `ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.1: select deeper-nested repeat-body activation diagnostic precision` | `pending commit hash` |
| `ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.2` | `ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.2: ship deeper-nested repeat-body activation diagnostic precision` | `pending commit hash` |

## Changelog

- `2026-05-27`: Created active R14 task tree for the targeted
  deeper-nested repeat-body activation diagnostic precision slice
  as the follow-on to the loop-contained slice. Deeper-nested repeat
  activation itself remains deferred; this slice ships only the
  diagnostic improvement.
