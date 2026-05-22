# ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS: Temporal Contract Actor-Constant Windows

## Metadata

- Tree ID: `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Allow bounded eventual temporal-contract windows to use positive actor
constants anywhere the shipped literal `within` cycle count is accepted.

## Non-Goals

- Do not accept actor parameters, transaction parameters, runtime signals, or
  arbitrary expressions as temporal-contract windows.
- Do not add dynamic contract bounds, min/max windows, same-cycle checks,
  nested contracts, or multiple outstanding obligations.
- Do not change generated monitor timing, SystemVerilog assertion projection,
  or the public `temporal_contracts[]` schedule-report schema.

## Acceptance Criteria

- `(contract name (eventually signal (within CONST)))` lowers when `CONST` is
  a declared actor constant whose resolved value is positive.
- `(contract name (eventually signal within CONST))` lowers through the same
  path as the nested spelling.
- Schedule reports continue to expose `within_cycles` as the resolved positive
  integer, without adding an unstable source-token field.
- Unknown, zero-valued, parameter-backed, and dynamic window tokens remain
  fail-closed with targeted diagnostics.
- The ISF spec, mdBook, public contract guidance where relevant, roadmap
  status, task tree, and live docs are synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS`
  Status: `active`
  Goal: `ship positive actor constants as bounded eventual contract windows`
  Children: `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.1`,
  `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.2`

- ID: `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.1`
  Status: `done`
  Goal: `select the temporal-contract actor-constant window task tree`
  Acceptance: `task-tree owner, source boundary, non-goals, and implementation leaf are recorded before code`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `pending this commit`

- ID: `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.2`
  Status: `pending`
  Goal: `implement and document actor-constant temporal-contract windows`
  Acceptance: `positive actor constants lower as literal windows; unsupported window tokens fail closed; docs and focused tests are synchronized`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.2` | `pending` | The tree is selected; the implementation leaf owns the parser/lowerer, tests, and user-facing docs. |

## Decisions

- `2026-05-22`: Treat actor constants as static compile-time evidence for
  contract windows, matching the existing static-wait convention. Parameters
  remain out of scope because they are overrideable specialization values.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| 2026-05-22 | `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.1` | `mdbook build docs/book`; `git diff --check` | Pass |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.1` | `pending this commit: ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.1: select contract actor-constant windows` | Selection commit. |

## Changelog

- `2026-05-22`: Created active R14 task tree for positive actor constants in
  bounded eventual temporal-contract windows.
