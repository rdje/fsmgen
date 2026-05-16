# ISF-RULE-RESOURCE-FIXTURE-PROMOTION: Rule Resource Fixture Promotion

## Metadata

- Tree ID: `ISF-RULE-RESOURCE-FIXTURE-PROMOTION`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Promote a checked-in rule/resource arbitration ISF fixture to file-backed
schedule JSON, scheduled `.fsm`, strict-mode, and HDL reachability coverage.

## Non-Goals

- Widening resource kinds or arbiter semantics.
- Changing rule priority, conflict suppression, or resource gating behavior.
- Adding the fixture to the quick/smoke tier.
- Snapshotting full generated HDL or full schedule JSON.

## Acceptance Criteria

- The fixture covers a rule-over-transaction priority resolution, a
  `rule_slot`/`priority` resource with two rule users, lower-priority rule
  suppression by a higher-priority rule, and ordinary transaction completion.
- A file-backed regression proves scheduled `.fsm` structure, schedule-report
  metadata, strict schedule JSON parity, and plain plus strict HDL generation.
- Public `tested_by` metadata, the ISF spec, downstream handoff, public
  contract, mdBook, fixture matrix, live docs, README, roadmap board, and task
  tree stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-RULE-RESOURCE-FIXTURE-PROMOTION`
  Status: `done`
  Goal: `Promote rule/resource arbitration to file-backed schedule/strict/HDL coverage.`
  Children: `ISF-RULE-RESOURCE-FIXTURE-PROMOTION.1`

- ID: `ISF-RULE-RESOURCE-FIXTURE-PROMOTION.1`
  Status: `done`
  Goal: `Add fixture and regression coverage for rule/resource arbitration.`
  Acceptance: `The new fixture and regression prove in-process and CLI behavior, public metadata/docs are synchronized, and focused plus ISF regression gates pass.`
  Verification: `prove -l t/1316-isf-rule-resource-fixture-coverage.t t/1218-isf-rule-slot-resource-arbitration.t t/1220-isf-arbitration-schedule-report.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`
  Commit: `ISF-RULE-RESOURCE-FIXTURE-PROMOTION.1: promote rule resource fixture coverage`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The rule/resource fixture now has file-backed schedule/report/strict/HDL coverage. |

## Decisions

- `2026-05-16`: Treat the fixture as bounded resource-arbitration coverage, not
  as a claim for deferred resource kinds or arbiters.
- `2026-05-16`: Keep the fixture in the broader `isf` regression tier, not
  the curated quick/smoke tier.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-RULE-RESOURCE-FIXTURE-PROMOTION.1` | `prove -l t/1316-isf-rule-resource-fixture-coverage.t t/1218-isf-rule-slot-resource-arbitration.t t/1220-isf-arbitration-schedule-report.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t` | `PASS: Files=7, Tests=106` |
| `2026-05-16` | `ISF-RULE-RESOURCE-FIXTURE-PROMOTION.1` | `./bin/ci-regression isf --no-book` | `PASS: Files=222, Tests=975` |
| `2026-05-16` | `ISF-RULE-RESOURCE-FIXTURE-PROMOTION.1` | `mdbook build docs/book` | `PASS` |
| `2026-05-16` | `ISF-RULE-RESOURCE-FIXTURE-PROMOTION.1` | `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-RULE-RESOURCE-FIXTURE-PROMOTION.1` | `ISF-RULE-RESOURCE-FIXTURE-PROMOTION.1: promote rule resource fixture coverage` | `Task-scoped commit subject for this completed leaf.` |

## Changelog

- `2026-05-16`: Created task tree and started the rule/resource fixture
  promotion leaf.
- `2026-05-16`: Added `isf/rule_resource_arbiter.isf`, file-backed
  schedule/report/strict/HDL coverage, synchronized public metadata and docs,
  and closed the task tree.
