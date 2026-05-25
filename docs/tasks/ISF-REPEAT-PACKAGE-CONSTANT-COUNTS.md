# ISF-REPEAT-PACKAGE-CONSTANT-COUNTS: Package Constants In Static Repeat Counts

## Metadata

- Tree ID: `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow static ISF transaction `(repeat PACKAGE.CONSTANT body...)` counts to use
qualified imported package scalar constants when the constant resolves to a
positive integer literal.

## Non-Goals

- Do not add unqualified package-constant lookup.
- Do not accept package aggregate constants, package member/item paths, or
  arbitrary package expressions as repeat counts.
- Do not accept transaction parameters as static repeat counts.
- Do not change runtime scalar repeat-count zero-bypass behavior.
- Do not change the shipped static zero-count policy; package constants
  resolving to zero remain fail-closed.
- Do not widen repeat-body child activation, cross-domain repeat behavior, or
  repeat-body clause support.
- Do not implement generated-top/use-site respecialization for repeat counts.

## Acceptance Criteria

- The selected task-tree owner and implementation frontier are recorded before
  any parser, scheduler, source, generated-artifact, or test change.
- `(repeat PACKAGE.CONSTANT body...)` resolves to a positive integer count
  when the owning actor imports `PACKAGE` and the package declares scalar
  constant `CONSTANT`.
- Accepted package-constant repeats lower through the same static repeat
  counter-width path as positive literals, actor constants, and actor-local
  scalar parameter defaults.
- Positive package constants preserve the authored `PACKAGE.CONSTANT` token
  where the scheduled `.fsm` and schedule report expose the repeat count
  source, while using the resolved positive integer as counter-width evidence.
- Zero-valued package constants fail closed with the existing static
  zero-count repeat policy.
- Unsupported repeat-count sources fail closed with targeted diagnostics.
- The ISF spec, downstream integration spec, public contract, mdBook, task
  tree, roadmap/live docs, and public contract metadata are synchronized with
  the shipped behavior and explicit non-claims.
- Focused repeat/report/parser/public tests pass, and the broader ISF gate
  runs when the implementation blast radius warrants it.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS`
  Status: `active`
  Goal: `Qualified package scalar constants in static transaction repeat counts`
  Children: `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.1`,
  `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.2`

- ID: `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.1`
  Status: `done`
  Goal: `Select the bounded R14 implementation frontier and record the task-tree owner`
  Acceptance: `Task tree and live status docs identify the selected repeat-count package-constant boundary before implementation`
  Verification: `mdbook build docs/book`; feature-backlog/live-book/book-matrix audits with `Files=3, Tests=364`; `git diff --check`
  Commit: `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.1: select repeat package counts`

- ID: `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.2`
  Status: `pending`
  Goal: `Implement and document package scalar constants in static repeat counts`
  Acceptance: `Accepted package scalar constants resolve to positive static repeat counts, unsupported sources fail closed, and public docs/tests are synchronized`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.2` | `pending` | Static repeats already accept positive literals, actor constants, and actor-local scalar parameter defaults; package scalar constants are the next bounded static value-domain widening for repeat counts. |

## Decisions

- `2026-05-25`: Select static transaction repeat counts as the next
  package-constant widening because the existing repeat path already has a
  concrete positive-count counter-width contract for literals, actor
  constants, and actor-local scalar parameter defaults.
- `2026-05-25`: Preserve static zero-count repeat behavior exactly. Package
  constants resolving to zero should fail closed before scheduled `.fsm`
  emission, matching literal zero, actor constants resolving to zero, and
  actor scalar parameters resolving to zero.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `passed`; audits `Files=3, Tests=364` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.1` | `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.1: select repeat package counts` | Selection slice; no behavior change. |

## Changelog

- `2026-05-25`: Created task tree and selected
  `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.2` as the next implementation frontier.
