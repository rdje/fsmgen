# BACKEND-API-VALIDATION-FRONTIER: Backend, Validation, And Public API Frontier

## Metadata

- Tree ID: `BACKEND-API-VALIDATION-FRONTIER`
- Status: `proposed`
- Roadmap lane: `Backends And Validation` / `Embedding And Public APIs`
- Created: `2026-06-05`
- Last updated: `2026-06-05`
- Owner: repo-local workflow

## Goal

Own the backend, external-validation, embedding, and public-export backlog
items named in the 2026-06-05 remaining-work inventory.

## Non-Goals

- Do not implement backend or API behavior while this tree is proposed.
- Do not claim VHDL, GHDL, ABC, structured generation, or embedding API
  behavior as shipped without matching code, tests, and mdBook coverage.
- Do not leak unstable internal objects as public API surfaces.

## Acceptance Criteria

- Each backend/API backlog item has a leaf-level owner.
- When selected, the tree activates one executable leaf at a time.
- Public docs/mdBook and API contracts are synchronized for every shipped
  behavior.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `BACKEND-API-VALIDATION-FRONTIER`
  Status: `proposed`
  Goal: `Track backend, validation, embedding, and public API backlog directions.`
  Children: `BACKEND-API-VALIDATION-FRONTIER.1`,
    `BACKEND-API-VALIDATION-FRONTIER.2`,
    `BACKEND-API-VALIDATION-FRONTIER.3`,
    `BACKEND-API-VALIDATION-FRONTIER.4`,
    `BACKEND-API-VALIDATION-FRONTIER.5`,
    `BACKEND-API-VALIDATION-FRONTIER.6`,
    `BACKEND-API-VALIDATION-FRONTIER.7`,
    `BACKEND-API-VALIDATION-FRONTIER.8`

- ID: `BACKEND-API-VALIDATION-FRONTIER.1`
  Status: `pending`
  Goal: `Select the next executable backend/API leaf from evidence.`
  Acceptance: `One backend/API item is activated or explicitly blocked behind a prerequisite.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-API-VALIDATION-FRONTIER.2`
  Status: `pending`
  Goal: `Implement or explicitly scope the full VHDL backend frontier.`
  Acceptance: `One exact VHDL backend surface is selected, implemented or blocked, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-API-VALIDATION-FRONTIER.3`
  Status: `pending`
  Goal: `Add GHDL validation once VHDL lowering has an executable subset.`
  Acceptance: `A runnable GHDL validation subset exists or remains blocked behind VHDL backend support.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-API-VALIDATION-FRONTIER.4`
  Status: `pending`
  Goal: `Drive warning-clean external validation across historical samples.`
  Acceptance: `One exact historical sample family or tool gate is selected, cleaned or deferred, documented, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-API-VALIDATION-FRONTIER.5`
  Status: `pending`
  Goal: `Harden ABC mapping behavior.`
  Acceptance: `One exact ABC mapping edge is selected, implemented or deferred, documented, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-API-VALIDATION-FRONTIER.6`
  Status: `pending`
  Goal: `Broaden structured non-flattened generation.`
  Acceptance: `One exact non-flattened generation surface is selected, implemented or deferred, documented, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-API-VALIDATION-FRONTIER.7`
  Status: `pending`
  Goal: `Freeze the next programmatic embedding API surface.`
  Acceptance: `One exact embedding API surface is specified, implemented or deferred, documented, and regression-covered without exporting unstable internals.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-API-VALIDATION-FRONTIER.8`
  Status: `pending`
  Goal: `Broaden normalized semantic export.`
  Acceptance: `One exact normalized export field family is specified, implemented or deferred, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `BACKEND-API-VALIDATION-FRONTIER.1` | `pending` | Proposed owner only; not PNT-eligible until backend/API work is selected. |

## Decisions

- `2026-06-05`: Keep this tree proposed while the user-selected active focus is
  Composition/type.

## Open Questions

- None while proposed.

## Blockers

- VHDL-dependent leaves remain blocked until an executable VHDL backend subset
  is selected.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BACKEND-API-VALIDATION-FRONTIER.1` | `pending` | `pending` |

## Changelog

- `2026-06-05`: Created proposed backend/API frontier owner tree.
