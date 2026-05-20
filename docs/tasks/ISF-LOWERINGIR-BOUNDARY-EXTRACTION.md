# ISF-LOWERINGIR-BOUNDARY-EXTRACTION: Private LoweringIR Boundary Extraction

## Metadata

- Tree ID: `ISF-LOWERINGIR-BOUNDARY-EXTRACTION`
- Status: `proposed`
- Roadmap lane: `architecture backlog`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Reduce private ISF `LoweringIR` growth by identifying stable sub-boundaries
that can move into helper owners or typed private carriers while preserving
the current public contract: emitted `.fsm`, schedule JSON, generated
composition artifacts, and HDL behavior.

## Non-Goals

- Do not expose raw `LoweringIR` hashes as public API.
- Do not change schedule JSON schema, generated state naming, generated child
  artifact shape, or emitted HDL unless a later behavior-bearing leaf
  explicitly selects that change.
- Do not split `LoweringIR` only for line count. Each extraction must have a
  stable owner and invariant.

## Acceptance Criteria

- Stable `LoweringIR` subfamilies are inventoried with owners, invariants, and
  public projection points.
- At least one safe extraction or typed-private-carrier candidate is selected,
  or the tree records why no extraction is justified.
- Implementation leaves preserve schedule JSON/artifact behavior unless the
  selected leaf explicitly says otherwise.
- Focused ISF schedule/report tests and broader gates run when behavior-bearing
  code changes land.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-LOWERINGIR-BOUNDARY-EXTRACTION`
  Status: `proposed`
  Goal: `Extract stable private LoweringIR sub-boundaries where justified.`
  Children: `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.1`,
  `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.2`,
  `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.3`

- ID: `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.1`
  Status: `proposed`
  Goal: `Inventory stable LoweringIR subfamilies and projection points.`
  Acceptance: `Actor-network, domain/CDC, storage/provenance, activation
  handoff, and generated-composition subfamilies are mapped with invariants
  and report/artifact consumers.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.2`
  Status: `proposed`
  Goal: `Select one private extraction candidate.`
  Acceptance: `The selected candidate names its owner, inputs, outputs,
  invariants, unchanged public surfaces, and focused tests before code
  changes begin.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.3`
  Status: `proposed`
  Goal: `Implement the selected private LoweringIR extraction.`
  Acceptance: `The selected subfamily moves behind the new owner/carrier with
  unchanged public schedule/artifact behavior and passing focused gates.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

This tree is proposed, not active.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.1` | `proposed` | Stable subfamily inventory must precede private extraction. |

## Decisions

- `2026-05-20`: Selected as an actionable follow-up from
  `FSMGEN-IR-AUDIT.4` because `LoweringIR` is a legitimate private scheduler
  boundary but now owns enough stable feature families that helper-owner
  extraction should be considered deliberately.

## Open Questions

- Which `LoweringIR` subfamily is stable enough to extract first without
  widening public API?

## Blockers

- None while proposed.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `ISF-LOWERINGIR-BOUNDARY-EXTRACTION` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LOWERINGIR-BOUNDARY-EXTRACTION` | `pending` | `pending` |

## Changelog

- `2026-05-20`: Created proposed follow-up task tree from
  `FSMGEN-IR-AUDIT.4`.
