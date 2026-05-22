# ISF-REPEAT-STATIC-ZERO-COUNT-POLICY: Repeat Static Zero-Count Policy

## Metadata

- Tree ID: `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY`
- Status: `completed`
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
  Status: `completed`
  Goal: `ship a bounded static zero-count policy for repeat counts`
  Children: `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.1`,
  `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.2`

- ID: `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.1`
  Status: `done`
  Goal: `select the repeat static zero-count policy task tree`
  Acceptance: `task-tree owner, source boundary, non-goals, and implementation leaf are recorded before code`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `0cddc548 ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.1: select repeat static zero policy`

- ID: `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.2`
  Status: `done`
  Goal: `implement and document static zero-count repeat rejection`
  Acceptance: `literal zero and zero-valued actor-constant repeat counts fail closed; existing positive and dynamic repeat behavior is preserved; docs and focused tests are synchronized`
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1202-isf-repeat-clause-boundary.t`; `prove -Iperl t/1202-isf-repeat-clause-boundary.t t/1102-isf-repeat-counter-widths.t t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check`
  Commit: `pending this commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.2` | `done` | Static zero-count repeat rejection is shipped and the tree is closed. |

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
| 2026-05-22 | `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.2` | syntax checks; focused repeat tests; public/doc audits; `mdbook build docs/book`; broad `./bin/ci-regression isf --no-book` with `Files=238, Tests=1591`; `git diff --check` | Pass |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.1` | `0cddc548 ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.1: select repeat static zero policy` | Selection commit. |
| `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.2` | `pending this commit: ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.2: ship repeat static zero policy` | Implementation commit. |

## Changelog

- `2026-05-22`: Created active R14 task tree for a bounded static
  zero-count repeat policy.
- `2026-05-22`: Shipped fail-closed static zero-count repeat rejection and
  closed the tree.
