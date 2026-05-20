# MODULE-INFO-PROJECTION-GUARD: Module Info Projection Guard

## Metadata

- Tree ID: `MODULE-INFO-PROJECTION-GUARD`
- Status: `proposed`
- Roadmap lane: `architecture backlog`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Keep `module_info` honest as a compatibility/result projection by auditing the
remaining mirrors, public contract keys, and mutation boundaries that could
make it look like a second canonical compiler IR.

## Non-Goals

- Do not remove `module_info`; existing embedders rely on it.
- Do not freeze every nested `module_info` field as stable public API.
- Do not duplicate normalized semantic JSON contracts inside `module_info`.
- Do not change caller-visible result shape without explicit compatibility
  planning.

## Acceptance Criteria

- `module_info` forward-IR mirrors, composition mirrors, and bounded contract
  keys are audited against the named canonical IR/projection owners.
- Any missing mutation/aliasing guard or misleading public-contract wording is
  split into executable leaves before code changes begin.
- Public docs/book text stays clear that `module_info` is a compatibility
  projection, not compiler truth.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `MODULE-INFO-PROJECTION-GUARD`
  Status: `proposed`
  Goal: `Guard module_info as a bounded compatibility projection.`
  Children: `MODULE-INFO-PROJECTION-GUARD.1`,
  `MODULE-INFO-PROJECTION-GUARD.2`, `MODULE-INFO-PROJECTION-GUARD.3`

- ID: `MODULE-INFO-PROJECTION-GUARD.1`
  Status: `proposed`
  Goal: `Audit module_info mirrors and contract key families.`
  Acceptance: `Direct, composition, generated-child, and semantic forward-IR
  mirrors are mapped to their canonical owner or report projection.`
  Verification: `pending`
  Commit: `pending`

- ID: `MODULE-INFO-PROJECTION-GUARD.2`
  Status: `proposed`
  Goal: `Select missing guard or wording fixes.`
  Acceptance: `Only concrete aliasing, contract, or documentation risks are
  selected as follow-up leaves, with tests/docs scoped before code changes.`
  Verification: `pending`
  Commit: `pending`

- ID: `MODULE-INFO-PROJECTION-GUARD.3`
  Status: `proposed`
  Goal: `Implement selected module_info projection guards.`
  Acceptance: `Selected guards land with focused contract/mutation tests and
  unchanged compatibility shape unless explicitly planned.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

This tree is proposed, not active.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `MODULE-INFO-PROJECTION-GUARD.1` | `proposed` | Mirror and contract inventory must precede any guard implementation. |

## Decisions

- `2026-05-20`: Selected as an actionable follow-up from
  `FSMGEN-IR-AUDIT.4` because `module_info` is useful and compatibility-bound
  but overlaps forward IR and normalized report projections enough to require
  periodic guard coverage.

## Open Questions

- Which remaining `module_info` mirrors need additional mutation or contract
  guards beyond the existing coverage?

## Blockers

- None while proposed.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `MODULE-INFO-PROJECTION-GUARD` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `MODULE-INFO-PROJECTION-GUARD` | `pending` | `pending` |

## Changelog

- `2026-05-20`: Created proposed follow-up task tree from
  `FSMGEN-IR-AUDIT.4`.
