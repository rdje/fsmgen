# ISF-REPEAT-ACTOR-PARAM-COUNTS: Repeat Actor-Parameter Counts

## Metadata

- Tree ID: `ISF-REPEAT-ACTOR-PARAM-COUNTS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Allow transaction `(repeat COUNT body...)` counts to use actor-local scalar
parameter defaults when those defaults resolve to positive integer literals.

## Non-Goals

- Do not support transaction parameters as repeat counts.
- Do not support expression-valued actor parameters, aggregate/list actor
  parameters, unknown names, or arbitrary expressions as static repeat counts.
- Do not change the shipped runtime scalar repeat count behavior, including
  runtime zero-count body bypass.
- Do not change the shipped static zero-count policy; actor-parameter defaults
  resolving to zero remain fail-closed.
- Do not specialize repeat counts through reusable-library use-site parameter
  overrides or generated-top respecialization.
- Do not widen repeat-body child activation, cross-domain repeat behavior, or
  repeat-body clause support.

## Acceptance Criteria

- `(repeat COUNT_PARAM body...)` lowers when `COUNT_PARAM` names an
  actor-local scalar parameter default whose resolved value is positive.
- Parameter-backed repeat counts use the resolved positive value for repeat
  counter width evidence and preserve the authored count token in the scheduled
  repeat counter load, matching actor-constant repeat counts.
- Non-scalar, zero-valued, unknown, transaction-parameter, malformed, and
  expression-valued repeat counts remain fail-closed with targeted
  diagnostics.
- Existing positive literal, positive actor-constant, and known-width runtime
  scalar repeat behavior remains unchanged.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-ACTOR-PARAM-COUNTS`
  Status: `done`
  Goal: `Ship actor-parameter-backed static repeat counts.`
  Children: `ISF-REPEAT-ACTOR-PARAM-COUNTS.1`,
  `ISF-REPEAT-ACTOR-PARAM-COUNTS.2`

- ID: `ISF-REPEAT-ACTOR-PARAM-COUNTS.1`
  Status: `done`
  Goal: `Select repeat actor-parameter counts.`
  Acceptance: `Create the active task tree, record the static actor-parameter
  source boundary, preserve non-goals, and update roadmap/live docs without
  behavior changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `6e51a0ba`

- ID: `ISF-REPEAT-ACTOR-PARAM-COUNTS.2`
  Status: `done`
  Goal: `Implement and document actor-parameter repeat counts.`
  Acceptance: `Positive actor scalar parameters lower as static repeat counts;
  unsupported repeat count sources fail closed; specs, book, public contract,
  downstream handoff, and focused tests are synchronized.`
  Verification: `syntax`; `focused repeat/public/doc tests`;
  `mdbook build docs/book`; `git diff --check`;
  `./bin/ci-regression isf --no-book`
  Commit: `this commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| | | | No remaining frontier; tree is closed. |

## Decisions

- `2026-05-22`: Select actor-local scalar parameter defaults only. They are
  compile-time static evidence in the current actor shell, matching the
  shipped actor-parameter wait, latency, contract, and watchdog source model,
  while use-site override specialization and transaction parameters remain
  deferred.
- `2026-05-22`: Preserve the authored repeat count token in the scheduled
  `.fsm` repeat load, matching actor-constant repeat counts, while using the
  resolved positive default only for counter width and static-zero policy.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-REPEAT-ACTOR-PARAM-COUNTS.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |
| `2026-05-22` | `ISF-REPEAT-ACTOR-PARAM-COUNTS.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1102-isf-repeat-counter-widths.t`; `perl -Iperl -c t/1202-isf-repeat-clause-boundary.t`; `prove -Iperl t/1102-isf-repeat-counter-widths.t t/1202-isf-repeat-clause-boundary.t t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check`; `./bin/ci-regression isf --no-book` | `passed; broad gate Files=238, Tests=1612` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-ACTOR-PARAM-COUNTS.1` | `6e51a0ba ISF-REPEAT-ACTOR-PARAM-COUNTS.1: select repeat actor-param counts` | `selects static actor-parameter repeat count support` |
| `ISF-REPEAT-ACTOR-PARAM-COUNTS.2` | `this commit: ISF-REPEAT-ACTOR-PARAM-COUNTS.2: ship repeat actor-param counts` | `ships static actor-parameter repeat count support` |

## Changelog

- `2026-05-22`: Created task tree and selected static actor-parameter repeat
  counts.
- `2026-05-22`: Shipped actor-local scalar parameter defaults as positive
  static repeat counts, closed unsupported count sources with targeted
  diagnostics, synchronized specs/book/live docs, and closed the task tree.
