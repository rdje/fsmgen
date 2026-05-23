# ISF-REPEAT-COUNT-SOURCE-BOUNDARY: Repeat Count Source Boundary

## Metadata

- Tree ID: `ISF-REPEAT-COUNT-SOURCE-BOUNDARY`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Make the accepted ISF `(repeat count body...)` count-source domain explicit
and fail closed for unsupported count sources before scheduled `.fsm`
emission.

## Current Supersession Note

This closed tree records the count-source boundary as it was shipped before
actor-parameter repeat counts. The current public surface additionally accepts
actor-local scalar parameter defaults that resolve to positive integer
literals, as shipped by
[ISF-REPEAT-ACTOR-PARAM-COUNTS](ISF-REPEAT-ACTOR-PARAM-COUNTS.md).
Transaction parameters, non-scalar actor parameters, arbitrary expressions,
unknown names, and generated-top repeat-count respecialization remain
fail-closed or deferred.

## Non-Goals

- Do not add actor-parameter or transaction-parameter repeat-count
  specialization.
- Do not add expression-valued repeat counts.
- Do not add generated-top repeat-count respecialization.
- Do not change positive literal, positive actor-constant, or known-width
  runtime scalar repeat behavior.
- Do not widen repeat-body child activation or cross-domain repeat behavior.

## Acceptance Criteria

- Repeat counts are accepted only when they are positive decimal literals,
  declared actor constants resolving to positive integers, or known-width
  runtime scalar names.
- Literal zero and actor constants resolving to zero keep the existing
  fail-closed diagnostic.
- Unknown names, actor parameters, malformed scalar tokens, and
  expression-valued counts fail closed with targeted diagnostics.
- Focused repeat boundary tests cover the newly rejected unsupported count
  sources.
- The ISF spec, downstream integration spec, public contract, mdBook
  transaction chapter, feature support matrix, and feature backlog describe
  the accepted domain and remaining deferrals.
- Live docs and roadmap status are updated where project state changed.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-COUNT-SOURCE-BOUNDARY`
  Status: `done`
  Goal: `Fail closed unsupported repeat count sources`
  Children: `ISF-REPEAT-COUNT-SOURCE-BOUNDARY.1`,
  `ISF-REPEAT-COUNT-SOURCE-BOUNDARY.2`

- ID: `ISF-REPEAT-COUNT-SOURCE-BOUNDARY.1`
  Status: `done`
  Goal: `Select the repeat count source boundary and define the first implementation leaf`
  Acceptance: `Task tree, roadmap status, and live docs identify the active frontier before implementation`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `e2fa900b`

- ID: `ISF-REPEAT-COUNT-SOURCE-BOUNDARY.2`
  Status: `done`
  Goal: `Reject unsupported repeat count sources with focused tests and synchronized docs`
  Acceptance: `Only positive literals, positive actor constants, and known-width runtime scalar names are accepted repeat count sources`
  Verification: `syntax`; `focused repeat tests`; `public/doc audits`; `mdbook build docs/book`; `git diff --check`; `./bin/ci-regression isf --no-book`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Unsupported repeat count sources now fail closed and the tree is closed. |

## Decisions

- `2026-05-22`: Unsupported repeat count sources should fail closed instead
  of falling back to an implicit 8-bit counter. That keeps repeat scheduling
  reviewable and avoids giving unknown names silent one-cycle or underflow
  behavior.
- `2026-05-22`: Actor and transaction parameter repeat counts remain
  deferred because supporting them correctly requires a generated-top
  specialization policy for counter width and zero-count behavior.

## Open Questions

- None for the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-REPEAT-COUNT-SOURCE-BOUNDARY.1` | `mdbook build docs/book`; `git diff --check` | `pass` |
| `2026-05-22` | `ISF-REPEAT-COUNT-SOURCE-BOUNDARY.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1202-isf-repeat-clause-boundary.t`; `prove -Iperl t/1202-isf-repeat-clause-boundary.t t/1102-isf-repeat-counter-widths.t t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check`; `./bin/ci-regression isf --no-book` | `pass; broad gate Files=238, Tests=1593` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-COUNT-SOURCE-BOUNDARY.1` | `e2fa900b ISF-REPEAT-COUNT-SOURCE-BOUNDARY.1: select repeat count source boundary` | Selection committed. |
| `ISF-REPEAT-COUNT-SOURCE-BOUNDARY.2` | `ISF-REPEAT-COUNT-SOURCE-BOUNDARY.2: ship repeat count source boundary` | Pending commit. |

## Changelog

- `2026-05-22`: Created and activated task tree.
- `2026-05-22`: Shipped unsupported repeat count source fail-closed boundary
  and closed task tree.
