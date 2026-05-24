# CI-FEATURE-BACKLOG-STATUS-AUDIT: Feature Backlog Status Audit CI Repair

## Metadata

- Tree ID: `CI-FEATURE-BACKLOG-STATUS-AUDIT`
- Status: `done`
- Roadmap lane: `project operations`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Repair the GitHub Perl regression failure caused by a stale mdBook feature
backlog status audit expectation.

## Non-Goals

- Do not change feature-backlog truth to satisfy a stale test.
- Do not change unrelated CI workflows.
- Do not push outside the configured 30-commit cadence unless explicitly
  requested.

## Acceptance Criteria

- `t/1256-feature-backlog-status-audit.t` expects the current mdBook truth for
  `Automatic Aggregate Growth From Usage`.
- Focused CI reproduction passes locally.
- The latest Pages deploy failure is triaged against current workflow runs.
- Live docs record the CI diagnosis and repair.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `CI-FEATURE-BACKLOG-STATUS-AUDIT`
  Status: `done`
  Goal: `Repair stale feature-backlog status audit expectation`
  Children: `CI-FEATURE-BACKLOG-STATUS-AUDIT.1`

- ID: `CI-FEATURE-BACKLOG-STATUS-AUDIT.1`
  Status: `done`
  Goal: `Update the stale feature-backlog status audit and document the CI triage`
  Acceptance: `The focused failing audit passes, live docs record the GitHub
  CI diagnosis, and the Pages deploy failure is identified as already resolved
  by a later successful run or otherwise escalated with evidence`
  Verification: `focused failing audit; live-doc audits; exact local CI script`
  Commit: `pending this commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `The stale audit expectation is repaired and validated locally.` |

## Decisions

- `2026-05-23`: Treat the Perl regression failure as repo-fixable because the
  failing local reproduction shows a stale test expectation, not a mdBook
  truth error.
- `2026-05-23`: Treat the earlier Pages deploy `Bad credentials` run as
  already resolved unless new evidence appears, because the next `Publish
  mdBook` workflow run on the same branch succeeded with the current workflow
  permissions.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `CI-FEATURE-BACKLOG-STATUS-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t` | `passed: Files=1, Tests=15` |
| `2026-05-23` | `CI-FEATURE-BACKLOG-STATUS-AUDIT.1` | `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t` | `passed: Files=2, Tests=25` |
| `2026-05-23` | `CI-FEATURE-BACKLOG-STATUS-AUDIT.1` | `git diff --check` | `passed` |
| `2026-05-23` | `CI-FEATURE-BACKLOG-STATUS-AUDIT.1` | `./bin/ci-regression` | `passed: Files=1346, Tests=9515; mdBook build passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `CI-FEATURE-BACKLOG-STATUS-AUDIT.1` | `pending this commit: CI-FEATURE-BACKLOG-STATUS-AUDIT.1: fix backlog status audit` | `implementation slice` |

## Changelog

- `2026-05-23`: Created and activated the task tree.
- `2026-05-23`: Reproduced and fixed the stale backlog status audit
  expectation; confirmed the earlier Pages deploy failure was followed by a
  successful `Publish mdBook` run with the same workflow.
- `2026-05-23`: Closed verification with full local `./bin/ci-regression`
  passing `Files=1346, Tests=9515`, followed by a successful mdBook build.
