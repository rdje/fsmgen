# IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE: Direct Backend Structural IR Convergence

## Metadata

- Tree ID: `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE`
- Status: `proposed`
- Roadmap lane: `architecture backlog`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Move the direct single-module generation path toward the same clean
`StructuralRTLIR -> backend emitter` shape that composition already uses,
without changing emitted HDL semantics or destabilizing existing direct-root
debuggability.

## Non-Goals

- Do not rewrite the whole direct backend in one slice.
- Do not change public HDL output without focused and broad regression gates.
- Do not disturb composition's existing structural-IR emission path unless a
  selected slice explicitly proves shared benefit.
- Do not treat this tree as active until it is selected by the roadmap/PNT
  workflow.

## Acceptance Criteria

- Direct-root backend residues that still bypass `StructuralRTLIR` are
  inventoried with owners and consumers.
- The first behavior-preserving convergence slice is selected before code
  changes begin.
- Any implementation leaf has focused direct-root HDL/semantic checks plus a
  broader regression gate when the blast radius warrants it.
- Book/live-doc updates are made if user-visible inspection, generated output,
  or embedding surfaces change.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE`
  Status: `proposed`
  Goal: `Converge direct-root backend emission toward StructuralRTLIR where safe.`
  Children: `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.1`,
  `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.2`,
  `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.3`

- ID: `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.1`
  Status: `proposed`
  Goal: `Map direct-root backend residues that still bypass StructuralRTLIR.`
  Acceptance: `The task file lists direct-root emission/metadata owners,
  current StructuralRTLIR inputs, remaining bypasses, and a smallest safe
  convergence candidate.`
  Verification: `pending`
  Commit: `pending`

- ID: `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.2`
  Status: `proposed`
  Goal: `Select the first behavior-preserving convergence slice.`
  Acceptance: `The selected slice names the files, expected no-op behavior,
  focused tests, broad gate, and rollback boundary before implementation.`
  Verification: `pending`
  Commit: `pending`

- ID: `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.3`
  Status: `proposed`
  Goal: `Implement the selected direct-root structural convergence slice.`
  Acceptance: `Direct-root generation consumes the selected StructuralRTLIR
  boundary without behavior drift, and all selected gates pass.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

This tree is proposed, not active.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.1` | `proposed` | Factual residue mapping must precede any direct-backend refactor. |

## Decisions

- `2026-05-20`: Selected as an actionable follow-up from
  `FSMGEN-IR-AUDIT.4` because the architecture snapshot still identifies the
  direct single-module path as not fully converged on the forward
  `StructuralRTLIR -> backend emitter` spine.

## Open Questions

- Which direct-root HDL family is the smallest behavior-preserving candidate
  for the first convergence slice?

## Blockers

- None while proposed.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE` | `pending` | `pending` |

## Changelog

- `2026-05-20`: Created proposed follow-up task tree from
  `FSMGEN-IR-AUDIT.4`.
