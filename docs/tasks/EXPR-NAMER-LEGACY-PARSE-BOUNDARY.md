# EXPR-NAMER-LEGACY-PARSE-BOUNDARY: ExpressionNamer Legacy Parse Boundary

## Metadata

- Tree ID: `EXPR-NAMER-LEGACY-PARSE-BOUNDARY`
- Status: `proposed`
- Roadmap lane: `architecture backlog`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Make the `FSM::ExpressionNamer` legacy string/hash parser boundary explicit
before any caller cleanup changes behavior.

## Non-Goals

- Do not replace direct `CoreAST` parsing.
- Do not make `ExpressionNamer` hash ASTs public API.
- Do not rewrite backend factorization in this tree unless a later leaf proves
  it is necessary and behavior-preserving.

## Acceptance Criteria

- Every live `ExpressionNamer->parse_expression` caller is classified by
  whether it accepts blessed AST objects, legacy hash ASTs, or both.
- Focused tests guard the current accepted return shapes before cleanup.
- Any selected caller cleanup has its own leaf and verification plan.
- Live docs and roadmap status are updated when ownership status changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `EXPR-NAMER-LEGACY-PARSE-BOUNDARY`
  Status: `proposed`
  Goal: `Make ExpressionNamer legacy parse boundaries explicit.`
  Children: `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.1`,
  `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.2`

- ID: `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.1`
  Status: `proposed`
  Goal: `Audit parse_expression callers and accepted return forms.`
  Acceptance: `The task file lists every live caller and whether it expects
  blessed AST, legacy hash AST, string fallback, or mixed compatibility.`
  Verification: `pending`
  Commit: `pending`

- ID: `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.2`
  Status: `proposed`
  Goal: `Add focused guards for the accepted legacy parse boundary.`
  Acceptance: `Regression coverage locks the accepted caller behavior before
  any cleanup or conversion leaf is selected.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

This tree is proposed, not active. Activate it before changing
`FSM::ExpressionNamer` parse behavior or any caller that depends on its legacy
hash/string compatibility.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.1` | `proposed` | Caller classification must precede any parser or caller cleanup. |

## Decisions

- `2026-05-20`: Created from `IR-EXPRESSION-AST-OWNERSHIP.3` because
  `ExpressionNamer` deliberately supports object-AST naming but also owns
  private legacy hash/string parsing that must not become accidental compiler
  truth.

## Open Questions

- Which callers still need hash AST compatibility after the current backend
  factorization path is guarded?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.1` | `pending` | `pending` |

## Changelog

- `2026-05-20`: Created proposed follow-up task tree from
  `IR-EXPRESSION-AST-OWNERSHIP.3`.
