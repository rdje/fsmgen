# ISF-STAGES-CONTRACTS: Transaction Stage And Temporal Contract Lowering

## Metadata

- Tree ID: `ISF-STAGES-CONTRACTS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Turn parsed transaction `(stage ...)` and `(contract ...)` clauses from
fail-closed metadata into documented, scheduled, testable behavior for the
covered stage and temporal-check domains.

## Non-Goals

- Do not define an unbounded temporal logic language.
- Do not make legacy `(handshake ...)` metadata semantic in this tree; that
  decision belongs to `ISF-COMPATIBILITY`.
- Do not bypass the reviewable scheduled `.fsm` artifact.

## Acceptance Criteria

- Current stage/contract parsing, preservation, and fail-closed lowering are
  inventoried.
- A first bounded stage model is specified, including valid/ready interaction
  if covered.
- A first bounded temporal contract model is specified, including generated
  check representation or explicit deferred subfamilies.
- Lowering emits reviewable scheduled artifacts and generated HDL/checks for
  the covered cases.
- Unsupported stage/contract shapes fail with targeted diagnostics.
- Schedule-report metadata, tests, ISF spec, public contract, mdBook, roadmap,
  and live docs agree.

## Task Tree

- ID: `ISF-STAGES-CONTRACTS`
  Status: `active`
  Goal: `Ship bounded transaction stage and temporal contract lowering.`
  Children: `ISF-STAGES-CONTRACTS.1`, `ISF-STAGES-CONTRACTS.2`,
  `ISF-STAGES-CONTRACTS.3`, `ISF-STAGES-CONTRACTS.4`,
  `ISF-STAGES-CONTRACTS.5`, `ISF-STAGES-CONTRACTS.6`

- ID: `ISF-STAGES-CONTRACTS.1`
  Status: `pending`
  Goal: `Inventory current stage/contract parse and fail-closed behavior.`
  Acceptance: `The task file lists accepted parsed forms, preservation points,
  current diagnostics, and the exact missing lowering hooks.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-STAGES-CONTRACTS.2`
  Status: `pending`
  Goal: `Specify first bounded transaction stage semantics.`
  Acceptance: `The tree records supported stage syntax, generated state/handshake
  behavior, ordering guarantees, and rejected stage shapes.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-STAGES-CONTRACTS.3`
  Status: `pending`
  Goal: `Specify first bounded temporal contract semantics.`
  Acceptance: `The tree records supported temporal assertions/checks,
  generated artifact shape, reset behavior, report metadata, and rejected
  contract forms.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-STAGES-CONTRACTS.4`
  Status: `pending`
  Goal: `Implement stage lowering.`
  Acceptance: `Covered stage forms lower into scheduled FSM, parse through
  the normal frontend, and generate HDL/check artifacts as specified.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-STAGES-CONTRACTS.5`
  Status: `pending`
  Goal: `Implement temporal contract lowering.`
  Acceptance: `Covered contract forms lower into generated checks or scheduled
  artifacts, while unsupported forms fail closed with targeted diagnostics.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-STAGES-CONTRACTS.6`
  Status: `pending`
  Goal: `Add reports, tests, and synchronized docs.`
  Acceptance: `Schedule reports, regressions, ISF spec, public contract,
  mdBook, and live docs describe the shipped stage/contract behavior.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-STAGES-CONTRACTS.1` | `pending` | Current fail-closed behavior must be inventoried before bounded semantics are selected. |

## Decisions

- `2026-05-14`: Stage lowering and temporal contract lowering are tracked in
  one tree because both are transaction-local scheduling/checking metadata that
  currently fail closed at lowering time.

## Open Questions

- What is the smallest useful stage model that can be emitted as reviewable
  `.fsm` without hiding handshake timing?
- Should temporal contracts initially emit simulation assertions, scheduled
  check states, or both?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-STAGES-CONTRACTS` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-STAGES-CONTRACTS` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |

## Changelog

- `2026-05-14`: Created the active ISF stage/contract task tree.
