# ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY: Repeat Runtime Zero-Count Policy

## Metadata

- Tree ID: `ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Ship a bounded runtime zero-count policy for ISF `(repeat count body...)`
when `count` is a runtime scalar name, so a zero value skips the repeat body
instead of silently executing one iteration.

## Non-Goals

- Do not change positive literal repeat behavior.
- Do not change positive actor-constant repeat behavior.
- Do not add actor-parameter or transaction-parameter repeat-count
  specialization.
- Do not add expression-valued repeat counts.
- Do not widen repeat-body child activation, generated-top
  respecialization, cross-domain repeat behavior, or outstanding-child
  semantics.
- Do not change runtime dynamic wait zero-bypass semantics; this tree is
  repeat-count specific.

## Acceptance Criteria

- Runtime scalar repeat counts that evaluate to zero bypass the repeat body
  and repeat check before scheduled `.fsm` emission reaches body states.
- Runtime scalar repeat counts that are nonzero preserve the existing repeat
  counter load, body sequencing, repeat check, and positive-count behavior.
- Literal zero and actor-constant zero counts keep the existing fail-closed
  policy.
- Focused repeat tests cover zero-bypass and preserved positive behavior.
- The ISF spec, downstream integration spec, public contract, mdBook
  transaction chapter, feature support matrix, and feature backlog describe
  the shipped policy and remaining deferrals.
- Broader ISF validation runs if the lowering transition shape changes.
- Live docs and roadmap status are updated where project state changed.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY`
  Status: `done`
  Goal: `Ship a bounded runtime zero-count skip policy for scalar repeat counts`
  Children: `ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.1`,
  `ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.2`

- ID: `ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.1`
  Status: `done`
  Goal: `Select the runtime repeat zero-count policy tree and define the first implementation boundary`
  Acceptance: `Task tree, roadmap status, and live docs identify the active frontier before implementation`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `d8d11c7f`

- ID: `ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.2`
  Status: `done`
  Goal: `Implement runtime scalar repeat zero-count body bypass with focused tests and synchronized docs`
  Acceptance: `Runtime scalar zero counts skip body execution while nonzero counts preserve existing repeat behavior; docs and public contracts are synchronized`
  Verification: `syntax`; `focused repeat tests`; `public/doc audits`; `mdbook build docs/book`; `git diff --check`; `./bin/ci-regression isf --no-book`
  Commit: `0f2500fc ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.2: ship runtime repeat zero policy`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Runtime scalar repeat zero-count bypass shipped and the tree is closed. |

## Decisions

- `2026-05-22`: The next slice is runtime scalar repeat zero-count bypass,
  not actor-parameter specialization or expression-valued repeat counts,
  because the shipped repeat surface already documents runtime scalar counts
  and currently needs a precise zero-value behavior.
- `2026-05-22`: Zero-count runtime repeats should skip the repeat body rather
  than fail closed. Static zero counts remain fail-closed because they are
  almost always authoring mistakes and were already selected as a policy.

## Open Questions

- None for the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.1` | `mdbook build docs/book`; `git diff --check` | `pass` |
| `2026-05-22` | `ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1202-isf-repeat-clause-boundary.t`; `prove -Iperl t/1202-isf-repeat-clause-boundary.t t/1102-isf-repeat-counter-widths.t t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check`; `./bin/ci-regression isf --no-book` | `pass; broad gate Files=238, Tests=1592` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.1` | `d8d11c7f ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.1: select runtime repeat zero policy` | Selection committed. |
| `ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.2` | `ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.2: ship runtime repeat zero policy` | Pending commit. |

## Changelog

- `2026-05-22`: Created and activated task tree.
- `2026-05-22`: Shipped runtime scalar repeat zero-count bypass and closed
  task tree.
