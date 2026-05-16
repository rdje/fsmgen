# ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE: Extract Single Field Width Inference

## Metadata

- Tree ID: `ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Infer the one missing destination field width in an ISF `extract` clause when
the source word width and all sibling field widths are known.

## Non-Goals

- Inferring multiple unknown extract field widths from one source word.
- Changing source/field mismatch diagnostics where all field widths are already
  known.
- General expression-width inference outside the `extract` field-width path.

## Acceptance Criteria

- `(extract word as known_left inferred known_right)` infers `inferred` when
  `word`, `known_left`, and `known_right` provide enough positive width
  evidence.
- The inferred width is used for exact generated slice bounds and remains
  available as transaction-local width evidence.
- Multiple unknown extract fields still fail closed.
- Known sibling widths that leave no positive remaining width still fail
  closed with a targeted diagnostic.
- The ISF spec, downstream handoff, mdBook, and live docs describe the exact
  shipped boundary and remaining backlog.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE`
  Status: `done`
  Goal: `Close the single-missing-field extract width inference gap.`
  Children: `ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE.1`

- ID: `ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE.1`
  Status: `done`
  Goal: `Infer exactly one unknown extract field width from the known source width and known siblings.`
  Acceptance: `Lowering emits exact slices for the inferred field, preserves existing fail-closed cases, documents the boundary, and passes focused plus ISF regression gates.`
  Verification: `prove -l t/1101-isf-extract-slices.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check`; `./bin/ci-regression isf --no-book`
  Commit: `ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE.1: infer single extract field widths`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE.1` | `done` | Shipped in this tree; no remaining frontier. |

## Decisions

- `2026-05-16`: Infer only one missing field width. Two or more unknown fields are ambiguous and remain fail-closed.
- `2026-05-16`: Treat the inferred field width as normal transaction-local width evidence after the extract clause.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE.1` | `prove -l t/1101-isf-extract-slices.t t/1305-isf-book-feature-matrix-audit.t` | `PASS: Files=2, Tests=85` |
| `2026-05-16` | `ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE.1` | `git diff --check` | `PASS` |
| `2026-05-16` | `ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE.1` | `./bin/ci-regression isf --no-book` | `PASS: Files=214, Tests=935` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE.1` | `ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE.1: infer single extract field widths` | `Task-scoped commit subject for this completed leaf.` |

## Changelog

- `2026-05-16`: Created task tree and started the single-missing-field extract width inference leaf.
- `2026-05-16`: Shipped exactly-one-missing-field `extract` width inference,
  including assemble-derived source width coverage, fail-closed ambiguity
  diagnostics, spec/book/downstream/public-contract synchronization, and
  focused plus broad validation.
