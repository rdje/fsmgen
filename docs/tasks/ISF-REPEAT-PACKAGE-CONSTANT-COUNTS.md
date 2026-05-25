# ISF-REPEAT-PACKAGE-CONSTANT-COUNTS: Package Constants In Static Repeat Counts

## Metadata

- Tree ID: `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS`
- Status: `done`
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
  in the scheduled `.fsm` repeat-counter load while using the resolved
  positive integer as counter-width evidence.
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
  Status: `done`
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
  Status: `done`
  Goal: `Implement and document package scalar constants in static repeat counts`
  Acceptance: `Accepted package scalar constants resolve to positive static repeat counts, unsupported sources fail closed, and public docs/tests are synchronized`
  Verification: `syntax checks`; focused repeat/public/spec/book tests with `Files=10, Tests=386`; `./bin/ci-regression isf --no-book` with `Files=266, Tests=1717`; post-closure public/spec/book audits with `Files=7, Tests=374`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.2: support repeat package counts`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.2` | `done` | Closed: static repeats now accept qualified imported package scalar constants in the bounded positive integer surface. |

## Decisions

- `2026-05-25`: Select static transaction repeat counts as the next
  package-constant widening because the existing repeat path already has a
  concrete positive-count counter-width contract for literals, actor
  constants, and actor-local scalar parameter defaults.
- `2026-05-25`: Preserve static zero-count repeat behavior exactly. Package
  constants resolving to zero should fail closed before scheduled `.fsm`
  emission, matching literal zero, actor constants resolving to zero, and
  actor scalar parameters resolving to zero.
- `2026-05-25`: Keep repeat schedule-report shape unchanged. The public
  review surface for accepted package constants is the scheduled `.fsm`
  repeat-counter load plus the resolved counter width, not a new
  `transaction_loops[]` repeat-count field.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `passed`; audits `Files=3, Tests=364` |
| `2026-05-25` | `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.2` | syntax checks; `prove -Iperl t/1102-isf-repeat-counter-widths.t t/1202-isf-repeat-clause-boundary.t t/1360-isf-repeat-package-constant-counts.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/ci-regression isf --no-book`; post-closure public/spec/book audits; `mdbook build docs/book`; `git diff --check` | `passed`; focused audits `Files=10, Tests=386`; broad gate `Files=266, Tests=1717`; post-closure audits `Files=7, Tests=374` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.1` | `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.1: select repeat package counts` | Selection slice; no behavior change. |
| `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.2` | `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.2: support repeat package counts` | Implementation slice; package scalar constants in static repeat counts. |

## Changelog

- `2026-05-25`: Created task tree and selected
  `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.2` as the next implementation frontier.
- `2026-05-25`: Implemented qualified imported package scalar constants in
  static transaction repeat counts and closed the task tree.
