# R10-CLI-QUIET-BANNER-CLEANUP: CLI Quiet Banner Cleanup

## Metadata

- Tree ID: `R10-CLI-QUIET-BANNER-CLEANUP`
- Status: `done`
- Roadmap lane: `R10`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Make `bin/fsmgen --quiet` consistently suppress informational CLI banner text
while preserving diagnostics and machine-readable report modes.

## Non-Goals

- Do not change generated HDL, parser behavior, scheduler behavior, or public
  JSON schemas.
- Do not alter non-quiet banner/summary output except where required to keep
  quiet mode isolated.
- Do not change machine JSON stdout behavior; those modes already suppress the
  interactive banner.

## Acceptance Criteria

- `--quiet` no longer prints the `=== FSM HDL Generator ===` banner on success
  or failure.
- Human diagnostics still print on stderr when generation fails outside
  machine JSON modes.
- Non-quiet CLI behavior remains unchanged.
- Focused CLI regression coverage proves quiet/non-quiet behavior for at least
  one successful source and one failure source.
- mdBook/live docs are synchronized if user-facing CLI behavior changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R10-CLI-QUIET-BANNER-CLEANUP`
  Status: `done`
  Goal: `Align quiet CLI banner behavior with the documented quiet option.`
  Children: `R10-CLI-QUIET-BANNER-CLEANUP.1`,
    `R10-CLI-QUIET-BANNER-CLEANUP.2`

- ID: `R10-CLI-QUIET-BANNER-CLEANUP.1`
  Status: `done`
  Goal: `Activate the R10 quiet-banner cleanup task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to the quiet-banner implementation boundary.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R10-CLI-QUIET-BANNER-CLEANUP.1: select quiet banner cleanup`

- ID: `R10-CLI-QUIET-BANNER-CLEANUP.2`
  Status: `done`
  Goal: `Suppress the interactive CLI banner when --quiet is active.`
  Acceptance: `Quiet success and quiet failure runs omit the informational banner while preserving stderr diagnostics and generated output behavior; non-quiet runs still print the banner; mdBook/live docs describe the quiet-mode behavior.`
  Verification: `passed: syntax checks, focused CLI quiet/banner tests, feature-backlog audit, mdBook build, and diff check`
  Commit: `R10-CLI-QUIET-BANNER-CLEANUP.2: suppress quiet CLI banner`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R10-CLI-QUIET-BANNER-CLEANUP.2` | `done` | `--quiet` now suppresses the interactive banner on success and failure while non-quiet output keeps it. |

## Decisions

- `2026-05-24`: Select a narrow quiet-banner cleanup after the empty
  source-file diagnostic slice. The issue is bounded to CLI presentation:
  `bin/fsmgen --quiet` suppresses the processing line but still prints
  `=== FSM HDL Generator ===`, including on failures. The implementation
  should gate that banner on both non-machine JSON mode and non-quiet mode.
- `2026-05-24`: Close the tree after `.2`. `bin/fsmgen --quiet` now suppresses
  the interactive banner and processing line on success and failure, while
  non-quiet output still prints the banner and machine JSON modes remain
  JSON-only.

## Open Questions

- None. `.2` owns the quiet banner implementation and docs sync.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R10-CLI-QUIET-BANNER-CLEANUP.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `R10-CLI-QUIET-BANNER-CLEANUP.2` | `perl -c bin/fsmgen`; `perl -Iperl -c t/1347-cli-quiet-banner-boundary.t`; `prove -Iperl t/1347-cli-quiet-banner-boundary.t t/250-cli-entrypoint-file-context.t t/246-cli-error-output-cleanup.t t/384-public-json-trace-stdout-boundary-audit.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused CLI quiet/banner tests Files=4, Tests=12; feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R10-CLI-QUIET-BANNER-CLEANUP.1` | `R10-CLI-QUIET-BANNER-CLEANUP.1: select quiet banner cleanup` | `selection slice` |
| `R10-CLI-QUIET-BANNER-CLEANUP.2` | `R10-CLI-QUIET-BANNER-CLEANUP.2: suppress quiet CLI banner` | `implementation close-out slice` |

## Changelog

- `2026-05-24`: Created active `R10` quiet-banner cleanup tree and selected
  `.2` as the implementation frontier.
- `2026-05-24`: Completed `.2` and closed the tree. Quiet CLI runs now
  suppress the interactive banner.
