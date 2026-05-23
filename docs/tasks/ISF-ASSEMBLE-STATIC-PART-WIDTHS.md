# ISF-ASSEMBLE-STATIC-PART-WIDTHS: Assemble Static Part Widths

## Metadata

- Tree ID: `ISF-ASSEMBLE-STATIC-PART-WIDTHS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Give ISF `assemble` the same reviewable static width-evidence story as the
shipped `shift_left`, `shift_right`, and `extract` data operations, without
changing `assemble` state timing or generated concat shape.

The selected first slice is a narrow explicit-evidence surface:
`(assemble part... as target (widths N|PARAM|CONST...))` supplies the ordered
part widths. `PARAM` names an actor-local scalar parameter default that
resolves to a positive integer, and `CONST` names a declared actor constant
that resolves to a positive integer.

## Non-Goals

- Do not infer two or more unknown `assemble` part widths without explicit
  evidence.
- Do not accept transaction parameters, runtime interface signals, arbitrary
  expressions, unknown names, zero-valued actor parameters, zero-valued actor
  constants, or aggregate values as `assemble` part widths.
- Do not specialize part widths through activation-site overrides or generated
  tops.
- Do not change `assemble` scheduling, generated state count, concat emission,
  report key families, or generated handoff naming.
- Do not add new data-operation syntax beyond the optional `assemble`
  `(widths ...)` clause selected here.

## Acceptance Criteria

- `assemble` accepts one optional trailing `(widths ...)` clause after the
  target and requires the width count to match the part count.
- Literal, actor-parameter, and actor-constant part widths resolve to positive
  integers and feed the existing transaction-local width fact map.
- Accepted part widths lower like equivalent known part widths: target width
  evidence, later data-operation width consumers, schedule-report storage
  widths, and generated HDL all remain concrete.
- Unsupported width sources fail closed with targeted diagnostics.
- Existing `assemble part... as target` behavior remains unchanged, including
  single-unknown-part inference and multiple-unknown non-evidence concat
  lowering.
- ISF spec, downstream integration handoff, public contract metadata, mdBook,
  roadmap status, task-tree index, and live docs are synchronized.
- Focused validation covers positive, enum-resolved, malformed, and
  unsupported-source cases; broader ISF regression runs if the focused checks
  pass.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ASSEMBLE-STATIC-PART-WIDTHS`
  Status: `active`
  Goal: `Ship explicit static part-width evidence for assemble`
  Children: `ISF-ASSEMBLE-STATIC-PART-WIDTHS.1`,
  `ISF-ASSEMBLE-STATIC-PART-WIDTHS.2`

- ID: `ISF-ASSEMBLE-STATIC-PART-WIDTHS.1`
  Status: `done`
  Goal: `Select the bounded assemble static-width slice`
  Acceptance: `The active tree, frontier, acceptance criteria, non-goals, and
  live roadmap/docs identify the exact selected implementation boundary before
  any code changes.`
  Verification: `documentation-only selection review`
  Commit: `pending`

- ID: `ISF-ASSEMBLE-STATIC-PART-WIDTHS.2`
  Status: `pending`
  Goal: `Implement assemble optional static part widths`
  Acceptance: `Parser/lowerer handling, focused tests, public contract
  metadata, specs, mdBook, and live docs are updated and validated.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ASSEMBLE-STATIC-PART-WIDTHS.2` | `pending` | Completes the remaining explicit static width-evidence gap in shipped data-operation syntax. |

## Decisions

- `2026-05-23`: Select a trailing `(widths ...)` clause for `assemble`
  because it mirrors the shipped `extract` explicit-width spelling, keeps the
  existing part order visible, and does not disturb the canonical
  `(assemble part... as target)` concat source shape.
- `2026-05-23`: Keep transaction parameters out of scope because they are
  activation-specialized values; part-width evidence must be resolved before
  scheduled `.fsm` bit positions and storage metadata are finalized.

## Open Questions

- None for the selected leaf. Broader full-width inference for multiple
  unknown parts remains backlog and is not required to ship this slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-ASSEMBLE-STATIC-PART-WIDTHS.1` | documentation-only selection review | passed |
| `2026-05-23` | `ISF-ASSEMBLE-STATIC-PART-WIDTHS.2` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ASSEMBLE-STATIC-PART-WIDTHS.1` | `pending` | selection slice |
| `ISF-ASSEMBLE-STATIC-PART-WIDTHS.2` | `pending` | implementation slice |

## Changelog

- `2026-05-23`: Created and activated task tree; selected
  `ISF-ASSEMBLE-STATIC-PART-WIDTHS.2` as the implementation frontier.
