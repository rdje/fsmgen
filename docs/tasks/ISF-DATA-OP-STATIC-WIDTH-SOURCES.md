# ISF-DATA-OP-STATIC-WIDTH-SOURCES: Data Operation Static Width Sources

## Metadata

- Tree ID: `ISF-DATA-OP-STATIC-WIDTH-SOURCES`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Allow ISF data-operation local width-evidence options to use actor-local
static scalar values when those values resolve to positive integers.

## Non-Goals

- Do not add a width option to `assemble`; this tree only widens existing
  `shift_left`, `shift_right`, and `extract` explicit width-evidence options.
- Do not infer multiple unknown `extract` fields or multiple unknown
  `assemble` parts.
- Do not reinterpret explicit width evidence as a cast, truncation, resize, or
  runtime assignment.
- Do not accept transaction parameters, runtime interface signals, unknown
  symbolic names, arbitrary expressions, zero-valued actor parameters,
  zero-valued actor constants, aggregate actor parameters, aggregate actor
  constants, or use-site override values as data-operation width evidence.
- Do not specialize data-operation widths through reusable-library use-site
  parameter overrides or generated-top respecialization.
- Do not change generated state timing, source-order-insensitive width fact
  collection, schedule-report key families, generated handoff naming, or
  activation binding semantics.

## Acceptance Criteria

- `(shift_left REG BIT (width NAME))` and
  `(shift_right REG BIT (width NAME))` lower when `NAME` names an actor-local
  scalar parameter default or actor-local constant that resolves to a positive
  integer.
- `(extract WORD as FIELD... (widths NAME...))` lowers when each symbolic
  width names an actor-local scalar parameter default or actor-local constant
  that resolves to a positive integer. Mixed positive literals and accepted
  symbolic widths are supported.
- Accepted static width sources lower exactly like equivalent positive integer
  literals in scheduled `.fsm`, width fact collection, schedule-report storage
  metadata, and generated HDL.
- Unsupported symbolic and expression-like width sources fail closed with
  targeted diagnostics. Existing positive literal behavior remains unchanged.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DATA-OP-STATIC-WIDTH-SOURCES`
  Status: `active`
  Goal: `Ship actor-local static value sources for data-operation width evidence.`
  Children: `ISF-DATA-OP-STATIC-WIDTH-SOURCES.1`,
  `ISF-DATA-OP-STATIC-WIDTH-SOURCES.2`

- ID: `ISF-DATA-OP-STATIC-WIDTH-SOURCES.1`
  Status: `done`
  Goal: `Select data-operation static width sources.`
  Acceptance: `Create the active task tree, record the accepted symbolic
  source boundary, preserve non-goals, and update roadmap/live docs without
  behavior changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `this commit`

- ID: `ISF-DATA-OP-STATIC-WIDTH-SOURCES.2`
  Status: `pending`
  Goal: `Implement and document static data-operation width sources.`
  Acceptance: `Positive actor scalar parameters and declared actor constants
  lower as shift/extract width evidence; unsupported sources fail closed;
  specs, book, public contract, downstream handoff, and focused tests are
  synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DATA-OP-STATIC-WIDTH-SOURCES.2` | `pending` | `Task tree ownership is now in place; implementation can widen the existing explicit data-operation width evidence surface.` |

## Decisions

- `2026-05-23`: Select operation-local width evidence as the next
  author-facing R14 ergonomics slice after literal, actor-parameter, and
  actor-constant support shipped for the main static dimension declarations.
- `2026-05-23`: Keep the source set actor-local and positive-integer only.
  Transaction parameters remain outside this tree because they are
  activation-specialized values, not actor-shell compile-time width evidence.
- `2026-05-23`: Reuse the existing explicit width-evidence semantics.
  Accepted symbolic values are assertions about static widths; they do not
  cast, truncate, resize, or move runtime data.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-DATA-OP-STATIC-WIDTH-SOURCES.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DATA-OP-STATIC-WIDTH-SOURCES.1` | `this commit: ISF-DATA-OP-STATIC-WIDTH-SOURCES.1: select static data op width sources` | `selects actor-local static value sources for data-operation width evidence` |
| `ISF-DATA-OP-STATIC-WIDTH-SOURCES.2` | `pending` | `pending` |

## Changelog

- `2026-05-23`: Created task tree and selected actor-local static value
  sources for data-operation explicit width evidence as the next bounded R14
  slice.
