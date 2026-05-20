# GLOBAL-AST-MANAGER-BOUNDARY: Legacy Global AST Manager Boundary

## Metadata

- Tree ID: `GLOBAL-AST-MANAGER-BOUNDARY`
- Status: `proposed`
- Roadmap lane: `architecture backlog`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Resolve the ownership status of `FSM::GlobalASTManager` against the live
SystemVerilog factorization owners without changing generated behavior
accidentally.

## Non-Goals

- Do not replace the live `FSM::HDL::FlattenedDT::Backend::SystemVerilog`
  factorization support in this tree without a separate behavior-selected
  leaf.
- Do not expose `GlobalASTManager` as a public API.
- Do not remove tests or source files until their live/runtime role is proven.

## Acceptance Criteria

- Static and focused runtime evidence establish whether `GlobalASTManager` is
  runtime-owned, test-only compatibility, or dead residue.
- The module header and docs no longer claim broad ownership if the live owner
  is elsewhere.
- Any retirement, shim, or guard change is split into its own leaf.
- Focused validation covers the chosen boundary.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `GLOBAL-AST-MANAGER-BOUNDARY`
  Status: `proposed`
  Goal: `Classify and resolve GlobalASTManager ownership.`
  Children: `GLOBAL-AST-MANAGER-BOUNDARY.1`,
  `GLOBAL-AST-MANAGER-BOUNDARY.2`

- ID: `GLOBAL-AST-MANAGER-BOUNDARY.1`
  Status: `proposed`
  Goal: `Prove current runtime reachability and supported boundary.`
  Acceptance: `The task file records imports, direct callers, tests, and
  whether the module is runtime-owned or compatibility-only.`
  Verification: `pending`
  Commit: `pending`

- ID: `GLOBAL-AST-MANAGER-BOUNDARY.2`
  Status: `proposed`
  Goal: `Implement the selected boundary cleanup or guard.`
  Acceptance: `The selected retirement, shim, or documentation guard is
  implemented with focused validation and no generated behavior drift.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

This tree is proposed, not active. Activate it before changing
[perl/FSM/GlobalASTManager.pm](../../perl/FSM/GlobalASTManager.pm) or its
compatibility tests.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `GLOBAL-AST-MANAGER-BOUNDARY.1` | `proposed` | Reachability evidence must precede retirement or shim decisions. |

## Decisions

- `2026-05-20`: Created from `IR-EXPRESSION-AST-OWNERSHIP.3` because static
  search found no runtime import outside the module itself and compatibility
  tests, while the live backend factorization owner appears to be the
  SystemVerilog backend support family.

## Open Questions

- Should this module be removed, renamed as compatibility support, or kept
  with corrected documentation and guards?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `GLOBAL-AST-MANAGER-BOUNDARY.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `GLOBAL-AST-MANAGER-BOUNDARY.1` | `pending` | `pending` |

## Changelog

- `2026-05-20`: Created proposed follow-up task tree from
  `IR-EXPRESSION-AST-OWNERSHIP.3`.
