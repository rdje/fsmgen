# ISF-REPEAT-STATIC-ZERO-COUNT-POLICY: Repeat Static Zero-Count Policy

## Metadata

- Tree ID: `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Define and enforce a bounded static zero-count policy for transaction
`(repeat count body...)` clauses before repeat lowering can silently schedule
one body iteration for a count that is statically known to be zero.

## Non-Goals

- Do not implement the fully general dynamic repeat zero-count skip path.
- Do not change positive literal, positive actor-constant, sampled, or other
  runtime dynamic repeat count behavior.
- Do not add parameterized repeat specialization or generated-top
  respecialization.
- Do not widen repeat-body clause support.

## Acceptance Criteria

- Literal zero repeat counts fail closed with a targeted diagnostic before
  scheduled `.fsm` emission.
- Actor constants that resolve to zero fail closed with the same static
  zero-count policy.
- Positive literal repeat counts, positive actor constants, sampled/runtime
  dynamic repeat counts, and existing repeat-body lowering remain unchanged.
- The ISF spec, downstream integration handoff, public contract where
  relevant, mdBook, roadmap status, task tree, and live docs are synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY`
  Status: `active`
  Goal: `ship a bounded static zero-count policy for repeat counts`
  Children: `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.1`,
  `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.2`

- ID: `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.1`
  Status: `done`
  Goal: `select the repeat static zero-count policy task tree`
  Acceptance: `task-tree owner, source boundary, non-goals, and implementation leaf are recorded before code`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `pending this commit`

- ID: `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.2`
  Status: `pending`
  Goal: `implement and document static zero-count repeat rejection`
  Acceptance: `literal zero and zero-valued actor-constant repeat counts fail closed; existing positive and dynamic repeat behavior is preserved; docs and focused tests are synchronized`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.2` | `pending` | The selection leaf is complete; implementation owns the lowerer, tests, and user-facing docs. |

## Decisions

- `2026-05-22`: Select fail-closed static zero-count handling rather than
  zero-iteration skip lowering for this bounded slice. Static zero counts are
  author-visible mistakes under the current runtime-counter repeat lowering,
  while dynamic zero-count skip semantics need their own entry-path rewrite
  and pending-sample policy.

## Open Questions

- Should a future dynamic repeat leaf define zero-count as "skip the body" for
  runtime counts? This does not block the static fail-closed frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| 2026-05-22 | `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.1` | `mdbook build docs/book`; `git diff --check` | Pass |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.1` | `pending this commit: ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.1: select repeat static zero policy` | Selection commit. |

## Changelog

- `2026-05-22`: Created active R14 task tree for a bounded static
  zero-count repeat policy.
