# ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS: Temporal Contract Package-Constant Windows

## Metadata

- Tree ID: `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow bounded eventual temporal-contract `within` windows to use qualified
imported package scalar constants when those constants resolve to positive
integer scalar literals.

## Non-Goals

- Do not support unqualified package-constant lookup.
- Do not support package aggregate constants or package member/item paths as
  temporal-contract windows.
- Do not support transaction parameters, runtime interface signals, storage
  signals, arbitrary expressions, or package constants inside contract-window
  expressions.
- Do not specialize temporal-contract windows through reusable-library
  use-site parameter overrides or generated-top respecialization.
- Do not change monitor timing, sticky-fail behavior, reset behavior,
  SystemVerilog assertion projection, schedule-report key families, or
  generated HDL behavior beyond resolving one more static source kind before
  existing monitor lowering.
- Do not add dynamic contract bounds, min/max windows, same-cycle checks,
  nested contracts, expression operands, global `always` implication forms, or
  multiple outstanding obligations.

## Acceptance Criteria

- `(contract c (eventually done within PACKAGE.CONSTANT))` lowers when the
  token names a qualified imported package scalar constant whose resolved
  value is positive.
- The older nested `(eventually done (within PACKAGE.CONSTANT))` spelling
  lowers through the same accepted source path.
- Accepted package constants lower exactly like equivalent positive literal,
  actor-constant, and actor-local scalar-parameter temporal-contract windows.
- Unsupported window sources fail closed with targeted diagnostics: unknown
  package constants, unqualified package constants, aggregate package
  constants, package member/item paths, ambiguous local-enum/package-constant
  spellings, zero-valued constants, transaction parameters, runtime signals,
  arbitrary expressions, and package constants in unrelated value domains.
- Schedule reports continue to expose `within_cycles` as the resolved
  positive integer without adding a separate source-token field.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS`
  Status: `active`
  Goal: `Ship qualified package scalar constants as temporal-contract windows.`
  Children: `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.1`,
  `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.2`

- ID: `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.1`
  Status: `done`
  Goal: `Select temporal-contract package-constant windows.`
  Acceptance: `Create the active task tree, record the static package-constant
  source boundary, preserve non-goals, and update roadmap/live docs without
  behavior changes.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check`
  Commit: `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.1: select contract package windows`

- ID: `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.2`
  Status: `pending`
  Goal: `Implement and document package scalar constants in temporal-contract windows.`
  Acceptance: `Positive package scalar constants lower as literal contract
  windows; unsupported window tokens fail closed; specs, book, public
  contract, downstream handoff, and focused tests are synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.2` | `pending` | Temporal-contract windows already accept positive literals, actor constants, and actor-local scalar parameter defaults; qualified package scalar constants are the next bounded static value-domain widening. |

## Decisions

- `2026-05-25`: Select qualified imported package scalar constants only.
  Contract windows are static timing metadata, so accepted package constants
  should resolve before the existing temporal monitor lowering.
- `2026-05-25`: Preserve the existing positive-only contract-window policy.
  Package constants resolving to zero should fail closed, matching literal
  zero, actor constants resolving to zero, and actor scalar parameters
  resolving to zero.
- `2026-05-25`: Keep the schedule-report shape unchanged. Accepted package
  constants should publish only through resolved `temporal_contracts[].within_cycles`
  and normal package/import metadata, not through a new source-token field.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `passed`; audits `Files=3, Tests=364` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.1` | `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.1: select contract package windows` | Selection slice; no behavior change. |

## Changelog

- `2026-05-25`: Created task tree and selected
  `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.2` as the next implementation frontier.
