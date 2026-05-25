# ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS: Package Constants In Data Operation Width Evidence

## Metadata

- Tree ID: `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow explicit ISF data-operation width evidence to use qualified imported
package scalar constants when the constant resolves to a positive integer.
The initial implementation surface is the shipped explicit-width family:
`shift_left` and `shift_right` `(width ...)`, plus `assemble` and `extract`
`(widths ...)`.

## Non-Goals

- Do not add unqualified package-constant lookup.
- Do not accept package aggregate constants, package member/item paths, or
  arbitrary package expressions as width evidence.
- Do not accept runtime signals, transaction parameters, enum values, or
  non-scalar actor values as data-operation width evidence.
- Do not change existing literal, actor-constant, or actor-local scalar
  parameter width evidence behavior.
- Do not add new data operations or change data-operation scheduling beyond
  resolving accepted package scalar constants to the existing positive integer
  width path.
- Do not implement generated-top/use-site respecialization for data-operation
  width evidence.

## Acceptance Criteria

- The selected task-tree owner and implementation frontier are recorded before
  any parser, scheduler, source, generated-artifact, or test change.
- `shift_left` and `shift_right` explicit `(width PACKAGE.CONSTANT)` options
  resolve to positive integer widths when the owning actor imports `PACKAGE`
  and the package declares scalar constant `CONSTANT`.
- `assemble` and `extract` explicit `(widths PACKAGE.CONSTANT ...)` lists
  resolve accepted package scalar constants through the same static width
  path as literals, actor constants, and actor-local scalar parameters.
- Unsupported width sources fail closed with targeted diagnostics that do not
  silently fall through to runtime signal or expression handling.
- The ISF spec, downstream integration spec, public contract, mdBook, task
  tree, roadmap/live docs, and public contract metadata are synchronized with
  the shipped behavior and explicit non-claims.
- Focused parser/lowering/report/HDL tests pass, and the broader ISF gate runs
  when the implementation blast radius warrants it.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS`
  Status: `active`
  Goal: `Qualified package scalar constants in explicit data-operation width evidence`
  Children: `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.1`,
  `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.2`

- ID: `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.1`
  Status: `done`
  Goal: `Select the bounded R14 implementation frontier and record the task-tree owner`
  Acceptance: `Task tree and live status docs identify the selected data-operation width package-constant boundary before implementation`
  Verification: `mdbook build docs/book`; feature-backlog/live-book/book-matrix audits with `Files=3, Tests=364`; `git diff --check`
  Commit: `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.1: select data op package widths`

- ID: `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.2`
  Status: `pending`
  Goal: `Implement and document package scalar constants in explicit data-operation width evidence`
  Acceptance: `Accepted package scalar constants resolve to positive integer widths for shift/assemble/extract explicit width evidence, unsupported sources fail closed, and public docs/tests are synchronized`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.2` | `pending` | Implementation follows the selected R14 public-facing package-constant width frontier. |

## Decisions

- `2026-05-25`: Select explicit data-operation width evidence as the next
  package-constant widening because actor interface widths, actor-owned
  scalar storage widths, actor-owned bank widths/depths, transaction-local
  port widths, and actor/static parameter defaults already resolve through
  concrete positive integer publication paths. Keeping this slice on explicit
  `(width ...)` / `(widths ...)` evidence avoids broad inference changes while
  improving author-facing reuse of imported package constants.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `passed`; audits `Files=3, Tests=364` |
| `2026-05-25` | `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.2` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.1` | `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.1: select data op package widths` | Selection slice; no behavior change. |
| `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.2` | `pending` | `pending` |

## Changelog

- `2026-05-25`: Created task tree and selected
  `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.2` as the next implementation
  frontier.
