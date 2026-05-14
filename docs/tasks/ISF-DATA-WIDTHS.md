# ISF-DATA-WIDTHS: Data Operation Width Inference

## Metadata

- Tree ID: `ISF-DATA-WIDTHS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Improve ISF data-operation width inference so `extract`, `shift_right`,
`shift_left`, `assemble`, and related scheduled expressions avoid placeholder
width/slice behavior whenever safe width evidence can be derived from
interface declarations, samples, storage metadata, explicit options, or
neighboring operations.

## Non-Goals

- Do not implement broad aggregate type inference for the whole `.fsm`
  language; that belongs to language/type backlog work.
- Do not guess widths when evidence is ambiguous.
- Do not silently change generated bit ordering for already-shipped explicit
  width forms.

## Acceptance Criteria

- Current data-operation width sources and fallback behavior are inventoried.
- A width-evidence priority model is documented for ISF data operations.
- Safe inference cases lower to exact scheduled `.fsm` slices/shifts/concats.
- Ambiguous or underconstrained cases fail explicitly or remain documented as
  deferred with clear rationale.
- Schedule-report storage metadata reflects inferred widths more accurately.
- Focused tests and docs cover inferred, explicit, ambiguous, and malformed
  cases.

## Task Tree

- ID: `ISF-DATA-WIDTHS`
  Status: `active`
  Goal: `Ship safer and broader ISF data-operation width inference.`
  Children: `ISF-DATA-WIDTHS.1`, `ISF-DATA-WIDTHS.2`,
  `ISF-DATA-WIDTHS.3`, `ISF-DATA-WIDTHS.4`, `ISF-DATA-WIDTHS.5`

- ID: `ISF-DATA-WIDTHS.1`
  Status: `pending`
  Goal: `Inventory current width inference and placeholder fallback behavior.`
  Acceptance: `The task file lists current width sources, explicit width
  options, unknown-width fallbacks, generated `.fsm` shapes, and report
  storage effects.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-DATA-WIDTHS.2`
  Status: `pending`
  Goal: `Specify width-evidence precedence and failure policy.`
  Acceptance: `The tree records which evidence sources win, which cases infer,
  which cases fail, and which cases remain deferred.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-DATA-WIDTHS.3`
  Status: `pending`
  Goal: `Implement inference for the first data-operation family.`
  Acceptance: `The selected operation family lowers exact widths without
  placeholders for documented safe cases and rejects ambiguous cases.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-DATA-WIDTHS.4`
  Status: `pending`
  Goal: `Extend inference across remaining covered data operations.`
  Acceptance: `The agreed extract, shift_right, shift_left, and assemble
  cases share the documented width-evidence model.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-DATA-WIDTHS.5`
  Status: `pending`
  Goal: `Add reports, tests, and synchronized docs.`
  Acceptance: `Schedule-report storage, focused regressions, ISF spec, public
  contract, mdBook, and live docs describe the shipped width behavior.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DATA-WIDTHS.1` | `pending` | Placeholder fallback behavior and existing width evidence must be inventoried before inference is widened. |

## Decisions

- `2026-05-14`: This tree owns ISF-specific data-operation width inference,
  not broad language-wide type inference.

## Open Questions

- Should ambiguous unknown-width data operations fail immediately once safer
  inference exists, or remain compatibility fallback in default mode?
- Which operation family is the highest-value first implementation slice?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-DATA-WIDTHS` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DATA-WIDTHS` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |

## Changelog

- `2026-05-14`: Created the active ISF data-width task tree.
