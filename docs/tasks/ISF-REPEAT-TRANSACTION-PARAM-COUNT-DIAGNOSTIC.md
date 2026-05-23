# ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC: Repeat Transaction Parameter Count Diagnostic

## Metadata

- Tree ID: `ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Make transaction-parameter repeat counts fail closed with a targeted
diagnostic before scheduled `.fsm` emission.

## Current Supersession Note

This closed tree records the transaction-parameter diagnostic as shipped
before actor-parameter repeat counts. The current public surface additionally
accepts actor-local scalar parameter defaults that resolve to positive integer
literals, as shipped by
[ISF-REPEAT-ACTOR-PARAM-COUNTS](ISF-REPEAT-ACTOR-PARAM-COUNTS.md).
Transaction parameters remain deferred and keep the targeted diagnostic,
including when they shadow an actor parameter of the same name.

## Non-Goals

- Do not implement actor-parameter or transaction-parameter repeat-count
  specialization.
- Do not change positive literal, positive actor-constant, known-width runtime
  scalar, static zero, or runtime zero-bypass repeat behavior.
- Do not add generated-top repeat-count respecialization.
- Do not widen expression-valued repeat counts or cross-domain repeat
  behavior.

## Acceptance Criteria

- A repeat count that names a transaction parameter reports that transaction
  parameter repeat counts remain deferred.
- Unknown names, actor parameters, malformed tokens, positive actor constants,
  positive literals, and known-width runtime scalar names keep their shipped
  behavior.
- Focused repeat tests cover the transaction-parameter diagnostic.
- ISF spec, downstream handoff, public contract, mdBook, roadmap, task index,
  and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC`
  Status: `done`
  Goal: `Harden the repeat count source boundary for transaction parameters.`
  Children: `ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.1`,
  `ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.2`

- ID: `ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.1`
  Status: `done`
  Goal: `Select the transaction-parameter repeat count diagnostic slice.`
  Acceptance: `Create the task tree, document the exact deferred boundary,
  set the implementation frontier, and update roadmap/live docs without
  behavior changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `pending commit`

- ID: `ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.2`
  Status: `done`
  Goal: `Ship the transaction-parameter repeat count diagnostic.`
  Acceptance: `Lowering rejects transaction-parameter repeat counts with a
  targeted diagnostic before counter emission; focused tests and live docs
  prove the boundary while existing repeat count behavior is preserved.`
  Verification: LoweringIR/test syntax; focused repeat/public/doc tests;
  broad `./bin/ci-regression isf --no-book`; `mdbook build docs/book`;
  `git diff --check`
  Commit: `pending commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| | | | No remaining frontier; tree is closed. |

## Decisions

- `2026-05-22`: Select diagnostic hardening before repeat-parameter
  specialization. Parameterized repeat-count support needs a separate
  generated-top/counter-width policy, but the current fail-closed boundary can
  already be made precise for transaction parameters.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |
| `2026-05-22` | `ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1202-isf-repeat-clause-boundary.t`; `prove -Iperl t/1202-isf-repeat-clause-boundary.t t/1102-isf-repeat-counter-widths.t t/1244-isf-wait-clause-lowering.t t/1112-isf-public-interface-contract.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/ci-regression isf --no-book`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check` | `focused checks passed with Files=6, Tests=366; broad ISF gate passed with Files=238, Tests=1601; final public/doc audits and mdBook/diff checks passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.1` | `this commit: ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.1: select repeat transaction parameter diagnostic` | `selects targeted transaction-parameter repeat-count diagnostic hardening` |
| `ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.2` | `this commit: ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.2: harden repeat transaction parameter diagnostic` | `ships the targeted generated child transaction-parameter repeat-count diagnostic` |

## Changelog

- `2026-05-22`: Created task tree and selected the transaction-parameter
  repeat count diagnostic frontier.
- `2026-05-22`: Shipped the targeted transaction-parameter repeat-count
  diagnostic and closed the tree.
