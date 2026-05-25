# ISF-WAIT-PACKAGE-CONSTANT-COUNTS: Package Constants In Static Wait Counts

## Metadata

- Tree ID: `ISF-WAIT-PACKAGE-CONSTANT-COUNTS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow static ISF transaction `(wait PACKAGE.CONSTANT)` counts to use qualified
imported package scalar constants when the constant resolves to a
non-negative integer literal.

## Non-Goals

- Do not add unqualified package-constant lookup.
- Do not accept package aggregate constants, package member/item paths, or
  arbitrary package expressions as wait counts.
- Do not accept transaction parameters as static wait counts.
- Do not change runtime dynamic wait counters, runtime wait expression
  semantics, generated wait-state timing, zero-count no-op behavior, or
  pending-sample routing.
- Do not implement generated-top/use-site respecialization for wait counts.

## Acceptance Criteria

- The selected task-tree owner and implementation frontier are recorded before
  any parser, scheduler, source, generated-artifact, or test change.
- `(wait PACKAGE.CONSTANT)` resolves to a non-negative integer count when the
  owning actor imports `PACKAGE` and the package declares scalar constant
  `CONSTANT`.
- Accepted package-constant waits lower through the same static wait path as
  literals, actor constants, and actor-local scalar parameter defaults.
- Zero-valued package constants remain transparent no-ops with no wait state
  and no `transaction_waits[]` report entry.
- Positive package constants emit fixed scheduled wait-state chains and
  publish `transaction_waits[]` entries with `count_kind: static`, integer
  `cycles`, and the authored `PACKAGE.CONSTANT` token in `count_source`.
- Unsupported wait-count sources fail closed with targeted diagnostics.
- The ISF spec, downstream integration spec, public contract, mdBook, task
  tree, roadmap/live docs, and public contract metadata are synchronized with
  the shipped behavior and explicit non-claims.
- Focused wait/report/parser/public tests pass, and the broader ISF gate runs
  when the implementation blast radius warrants it.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-WAIT-PACKAGE-CONSTANT-COUNTS`
  Status: `active`
  Goal: `Qualified package scalar constants in static transaction wait counts`
  Children: `ISF-WAIT-PACKAGE-CONSTANT-COUNTS.1`,
  `ISF-WAIT-PACKAGE-CONSTANT-COUNTS.2`

- ID: `ISF-WAIT-PACKAGE-CONSTANT-COUNTS.1`
  Status: `done`
  Goal: `Select the bounded R14 implementation frontier and record the task-tree owner`
  Acceptance: `Task tree and live status docs identify the selected wait-count package-constant boundary before implementation`
  Verification: `mdbook build docs/book`; feature-backlog/live-book/book-matrix audits with `Files=3, Tests=364`; `git diff --check`
  Commit: `ISF-WAIT-PACKAGE-CONSTANT-COUNTS.1: select wait package counts`

- ID: `ISF-WAIT-PACKAGE-CONSTANT-COUNTS.2`
  Status: `pending`
  Goal: `Implement and document package scalar constants in static wait counts`
  Acceptance: `Accepted package scalar constants resolve to static wait counts, unsupported sources fail closed, and public docs/tests are synchronized`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-WAIT-PACKAGE-CONSTANT-COUNTS.2` | `pending` | Static waits already accept literals, actor constants, and actor-local scalar parameter defaults; package scalar constants are the next bounded static value-domain widening. |

## Decisions

- `2026-05-25`: Select static transaction wait counts as the next
  package-constant widening because the existing wait path already has a
  concrete static publication contract for positive counts, zero counts, and
  `transaction_waits[]` report metadata.
- `2026-05-25`: Preserve static wait timing exactly. Package constants should
  resolve before wait-state construction, so accepted positive counts reuse
  fixed wait-state chains and accepted zero counts remain transparent no-ops.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-WAIT-PACKAGE-CONSTANT-COUNTS.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `passed`; audits `Files=3, Tests=364` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-WAIT-PACKAGE-CONSTANT-COUNTS.1` | `ISF-WAIT-PACKAGE-CONSTANT-COUNTS.1: select wait package counts` | Selection slice; no behavior change. |

## Changelog

- `2026-05-25`: Created task tree and selected
  `ISF-WAIT-PACKAGE-CONSTANT-COUNTS.2` as the next implementation frontier.
