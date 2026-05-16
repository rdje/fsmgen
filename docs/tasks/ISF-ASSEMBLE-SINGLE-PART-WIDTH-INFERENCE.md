# ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE: Assemble Single Part Width Inference

## Metadata

- Tree ID: `ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Infer one missing `assemble` part width when the target width and all sibling
part widths are known.

## Non-Goals

- Inferring two or more unknown `assemble` part widths from one target width.
- Changing the emitted concat expression shape for accepted `assemble` source.
- Turning unknown `assemble` part widths into a hard error when the target
  width does not prove exactly one missing part.

## Acceptance Criteria

- `(assemble known_left inferred known_right as target)` infers `inferred`
  when `target`, `known_left`, and `known_right` provide enough positive width
  evidence.
- The inferred part width becomes transaction-local evidence for later data
  operations in the same transaction.
- Multiple unknown `assemble` parts remain accepted as non-evidence concat
  operands.
- Known sibling widths that leave no positive remaining width for the one
  unknown part fail closed with a targeted diagnostic.
- The ISF spec, downstream handoff, mdBook, live docs, and backlog boundary
  describe the exact shipped behavior and remaining backlog.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE`
  Status: `done`
  Goal: `Close the single-missing-part assemble width inference gap.`
  Children: `ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE.1`

- ID: `ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE.1`
  Status: `done`
  Goal: `Infer exactly one unknown assemble part width from the known target width and known sibling parts.`
  Acceptance: `Lowering records the inferred part width, preserves existing concat behavior and multi-unknown acceptance, documents the boundary, and passes focused plus ISF regression gates.`
  Verification: `prove -l t/1200-isf-assemble-clause-boundary.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check`; `./bin/ci-regression isf --no-book`
  Commit: `ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE.1: infer single assemble part widths`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE.1` | `done` | Shipped in this tree; no remaining frontier. |

## Decisions

- `2026-05-16`: Infer only one missing part width. Two or more unknown parts
  remain non-evidence concat operands.
- `2026-05-16`: Treat a non-positive remainder for the one unknown part as a
  hard width contradiction.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE.1` | `prove -l t/1200-isf-assemble-clause-boundary.t t/1305-isf-book-feature-matrix-audit.t` | `PASS: Files=2, Tests=85` |
| `2026-05-16` | `ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE.1` | `git diff --check` | `PASS` |
| `2026-05-16` | `ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE.1` | `./bin/ci-regression isf --no-book` | `PASS: Files=214, Tests=943` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE.1` | `ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE.1: infer single assemble part widths` | `Task-scoped commit subject for this completed leaf.` |

## Changelog

- `2026-05-16`: Created task tree and started the single-missing-part
  assemble width inference leaf.
- `2026-05-16`: Shipped exactly-one-missing-part `assemble` width inference,
  including transaction-local inferred part evidence, multi-unknown
  non-evidence preservation, non-positive remainder diagnostics, spec/book/
  downstream/public-contract synchronization, and focused plus broad
  validation.
