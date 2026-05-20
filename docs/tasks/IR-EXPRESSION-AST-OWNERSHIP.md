# IR-EXPRESSION-AST-OWNERSHIP: Expression AST Ownership Audit

## Metadata

- Tree ID: `IR-EXPRESSION-AST-OWNERSHIP`
- Status: `proposed`
- Roadmap lane: `architecture backlog`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Rationalize expression representation ownership across direct `CoreAST`
expressions, legacy/backend `FSM::AST::*` nodes, and structural
`ConnectionExpr` nodes so each representation has an explicit phase role,
conversion owner, and public/private boundary.

## Non-Goals

- Do not collapse source-level expressions, backend factoring expressions, and
  structural connection expressions into one universal node type merely for
  naming uniformity.
- Do not change expression semantics before the conversion/ownership map is
  complete.
- Do not expose private expression nodes as downstream APIs.

## Acceptance Criteria

- Every live expression representation has a phase role and owner.
- Conversion points between expression representations are listed.
- Any redundant conversion or unsafe ownership ambiguity is split into
  behavior-preserving implementation leaves before code changes begin.
- Public docs/contracts are updated only when downstream-visible expression
  reporting changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IR-EXPRESSION-AST-OWNERSHIP`
  Status: `proposed`
  Goal: `Rationalize expression AST ownership and conversion boundaries.`
  Children: `IR-EXPRESSION-AST-OWNERSHIP.1`,
  `IR-EXPRESSION-AST-OWNERSHIP.2`, `IR-EXPRESSION-AST-OWNERSHIP.3`

- ID: `IR-EXPRESSION-AST-OWNERSHIP.1`
  Status: `proposed`
  Goal: `Inventory expression representations and conversion sites.`
  Acceptance: `The task file lists direct CoreAST expressions, backend
  FSM::AST nodes, structural ConnectionExpr nodes, and conversion/reporting
  sites with owners and consumers.`
  Verification: `pending`
  Commit: `pending`

- ID: `IR-EXPRESSION-AST-OWNERSHIP.2`
  Status: `proposed`
  Goal: `Classify deliberate versus accidental expression duplication.`
  Acceptance: `Each representation is marked deliberate phase separation or
  actionable duplication, with no behavior-bearing refactor selected without
  a follow-up leaf.`
  Verification: `pending`
  Commit: `pending`

- ID: `IR-EXPRESSION-AST-OWNERSHIP.3`
  Status: `proposed`
  Goal: `Create implementation leaves for actionable expression ownership fixes.`
  Acceptance: `Only concrete redundant conversions or unsafe ownership gaps
  become executable follow-up leaves with verification plans.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

This tree is proposed, not active.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IR-EXPRESSION-AST-OWNERSHIP.1` | `proposed` | Conversion-site inventory must precede any expression ownership decision. |

## Decisions

- `2026-05-20`: Selected as an actionable follow-up from
  `FSMGEN-IR-AUDIT.4` because the audit found overlapping expression
  representations whose phase boundaries are legitimate but not yet recorded
  in one ownership map.

## Open Questions

- Which conversions are deliberate phase handoffs, and which are redundant
  implementation residue?

## Blockers

- None while proposed.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `IR-EXPRESSION-AST-OWNERSHIP` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IR-EXPRESSION-AST-OWNERSHIP` | `pending` | `pending` |

## Changelog

- `2026-05-20`: Created proposed follow-up task tree from
  `FSMGEN-IR-AUDIT.4`.
