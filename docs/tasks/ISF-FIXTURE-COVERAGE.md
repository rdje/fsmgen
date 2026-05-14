# ISF-FIXTURES: Realistic Fixture And Strict-Mode Coverage

## Metadata

- Tree ID: `ISF-FIXTURES`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Broaden ISF confidence from focused construct tests into realistic protocol
fixtures, strict-mode checks, scheduled `.fsm` review artifacts, schedule JSON,
and generated HDL paths that prove user-facing ISF features work together.

## Non-Goals

- Do not add large fixtures without clear feature coverage value.
- Do not snapshot full backend output when stable structural assertions are
  enough.
- Do not use fixtures as a substitute for focused malformed-boundary tests.

## Acceptance Criteria

- Existing ISF fixtures and test bands are inventoried.
- A fixture matrix maps realistic protocols to ISF feature families,
  schedule-report assertions, strict-mode checks, and HDL generation paths.
- New fixtures are added only when they cover a feature interaction or risk not
  already covered by focused tests.
- Quick/ISF/full regression tier impact is documented.
- ISF spec, public contract, mdBook, roadmap, and live docs reference fixture
  coverage only where it supports shipped behavior.

## Task Tree

- ID: `ISF-FIXTURES`
  Status: `active`
  Goal: `Expand realistic ISF fixture and strict-mode coverage.`
  Children: `ISF-FIXTURES.1`, `ISF-FIXTURES.2`, `ISF-FIXTURES.3`,
  `ISF-FIXTURES.4`, `ISF-FIXTURES.5`

- ID: `ISF-FIXTURES.1`
  Status: `pending`
  Goal: `Inventory current ISF fixtures, tests, and regression tiers.`
  Acceptance: `The task file lists current ISF fixtures, 109x/11xx/12xx
  tests, quick/isf/full tier coverage, strict-mode checks, and gaps.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-FIXTURES.2`
  Status: `pending`
  Goal: `Define realistic fixture coverage matrix.`
  Acceptance: `The tree maps target fixtures to feature families, report
  assertions, generated HDL paths, and regression tier placement.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-FIXTURES.3`
  Status: `pending`
  Goal: `Add the next realistic fixture slice.`
  Acceptance: `One selected fixture exercises a documented feature
  interaction through scheduled `.fsm`, schedule JSON, strict mode where
  relevant, and HDL generation.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-FIXTURES.4`
  Status: `pending`
  Goal: `Broaden regression-tier and support-accounting coverage where warranted.`
  Acceptance: `The selected fixture coverage is placed in the appropriate
  quick/isf/full tier without making fast turnaround noisy.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-FIXTURES.5`
  Status: `pending`
  Goal: `Synchronize fixture documentation and close covered gaps.`
  Acceptance: `Docs and live status describe what realistic ISF behavior is
  fixture-backed and which feature interactions remain unclaimed.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-FIXTURES.1` | `pending` | Existing fixture and regression-tier coverage must be inventoried before adding new realistic cases. |

## Decisions

- `2026-05-14`: Fixture expansion is tracked separately so feature trees can
  stay focused while this tree owns cross-feature realism and regression-tier
  placement.

## Open Questions

- Which protocol fixture should be next after the existing APB/I2C coverage?
- Which fixtures belong in the quick `isf` tier versus broader gates?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-FIXTURES` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-FIXTURES` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |

## Changelog

- `2026-05-14`: Created the active ISF fixture-coverage task tree.
