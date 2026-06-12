# ISF-MDBOOK-COVERAGE-AUDIT: Comprehensive mdBook Feature/Example Coverage Audit

## Metadata

- Tree ID: `ISF-MDBOOK-COVERAGE-AUDIT`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-27`
- Last updated: `2026-05-27`
- Owner: repo-local workflow

## Goal

Produce a comprehensive audit report identifying gaps between the
shipped FSMGen feature surface and the mdBook user-facing
documentation. The user has stated documentation is as important as
code — the mdBook is the only window through which a non-technical
user can understand what FSMGen does and how it does it.

This task tree ships *only the audit*. Fixes (chapter-by-chapter
example backfill, prose revisions, backlog status corrections) will
each be owned by separate downstream task trees driven from the
report's prioritized list.

## Non-Goals

- Do not modify book chapters in this slice. The audit is the
  deliverable.
- Do not change validator behavior or tests.
- Do not implement deferred feature lanes named in the report.

## Acceptance Criteria

- A persistent audit document at
  `docs/audits/ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md` records:
    * methodology used,
    * inventory of validator rejection paths (counts + families),
    * inventory of shipped accept-paths (per ISF clause family),
    * per-chapter coverage assessment for the ISF book chapters,
    * cross-cutting gap list (diagnostics without examples,
      features without prose, prose without examples),
    * backlog status accuracy spot-check findings,
    * prioritized list of downstream coverage slices.
- Live docs (MEMORY.md, ROADMAP_STATUS.md, CHANGES.md,
  DEVELOPMENT_NOTES.md, LIVE_ACHIEVEMENT_STATUS.md, README.md,
  docs/TASK_TREE.md) reflect the audit and the resulting
  recommended slice queue.
- mdBook builds clean; `git diff --check` clean.
- The slice is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-MDBOOK-COVERAGE-AUDIT`
  Status: `done`
  Goal: `Produce a comprehensive mdBook coverage audit report.`
  Children:
    `ISF-MDBOOK-COVERAGE-AUDIT.1`

- ID: `ISF-MDBOOK-COVERAGE-AUDIT.1`
  Status: `done`
  Goal: `Inventory the codebase rejection paths and accept paths, cross-reference against book chapters, and publish the audit report with a prioritized slice queue.`
  Acceptance: `Audit document exists at docs/audits/ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md and live docs are synchronized.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Audit report published at `docs/audits/ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md`. Eight gap categories (G1-G8) and a prioritized slice queue documented. |

## Decisions

- `2026-05-27`: Single-leaf task tree because the audit is a
  bounded one-shot artifact. Downstream coverage slices will each be
  their own task tree (per chapter or per family) driven from the
  audit's recommended queue.

## Open Questions

- The audit will surface "preferred prose density" judgement calls
  (how many examples is enough?). The report does not attempt to
  answer those; it lists candidate insertion points so the user
  can adjudicate.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-27` | `ISF-MDBOOK-COVERAGE-AUDIT.1` | `mdbook build docs/book`; `git diff --check` | `PASS`; audit report published with eight gap categories and a prioritized slice queue. |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-MDBOOK-COVERAGE-AUDIT.1` | `ISF-MDBOOK-COVERAGE-AUDIT.1: publish mdBook coverage audit` | `pending commit hash` |

## Changelog

- `2026-05-27`: Created the audit task tree after the user
  emphasized that mdBook coverage is as important as code. Audit is
  doc-only; downstream coverage slices will be owned by separate
  task trees.
- `2026-05-27`: Published the audit at
  `docs/audits/ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md`. Methodology
  combined validator confess-site inventory (1003 sites across the
  ISF stack), accept-path keyword frequency across 13*.md, per-chapter
  coverage metrics, and backlog status spot-check. Eight gap
  categories (G1-G8) identified, with the cookbook chapter's zero
  ISF recipes flagged as the highest-impact gap. The prioritized
  slice queue maps to ~10-12 downstream commits.
