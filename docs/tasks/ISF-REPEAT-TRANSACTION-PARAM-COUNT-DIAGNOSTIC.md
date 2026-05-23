# ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC: Repeat Transaction Parameter Count Diagnostic

## Metadata

- Tree ID: `ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Make transaction-parameter repeat counts fail closed with a targeted
diagnostic before scheduled `.fsm` emission.

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
  Status: `active`
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
  Status: `pending`
  Goal: `Ship the transaction-parameter repeat count diagnostic.`
  Acceptance: `Lowering rejects transaction-parameter repeat counts with a
  targeted diagnostic before counter emission; focused tests and live docs
  prove the boundary while existing repeat count behavior is preserved.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.2` | `pending` | The selected diagnostic hardening is the next bounded repeat-count source boundary leaf. |

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

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.1` | `this commit: ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.1: select repeat transaction parameter diagnostic` | `selects targeted transaction-parameter repeat-count diagnostic hardening` |
| `ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.2` | `pending` | `pending` |

## Changelog

- `2026-05-22`: Created task tree and selected the transaction-parameter
  repeat count diagnostic frontier.
