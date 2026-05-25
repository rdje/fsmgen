# ISF-SCHEDULE-REPORT-EVOLUTION-POLICY: Schedule Report Evolution Policy

## Metadata

- Tree ID: `ISF-SCHEDULE-REPORT-EVOLUTION-POLICY`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Document the additive/deprecation policy for ISF schedule-report keys, value
families, and `schema_version` evolution.

## Non-Goals

- Do not freeze the whole schedule JSON schema.
- Do not change schedule JSON payloads, generated `.fsm`, or HDL output.
- Do not decide assignment provenance or multi-file child summary exposure.

## Acceptance Criteria

- ISF spec, downstream handoff, public contract doc, and mdBook describe which
  schedule-report changes are additive and which require a `schema_version`
  bump or deprecation/migration notice.
- The whole-schema freeze blocker list removes additive/deprecation policy as
  an open item while keeping assignment provenance, multi-file child summaries,
  and golden fixture matrix blockers intact.
- mdBook and diff hygiene validation pass.
- Live docs, task tree, changes, and development notes are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-SCHEDULE-REPORT-EVOLUTION-POLICY`
  Status: `done`
  Goal: `Document schedule-report additive/deprecation policy.`
  Children: `ISF-SCHEDULE-REPORT-EVOLUTION-POLICY.1`

- ID: `ISF-SCHEDULE-REPORT-EVOLUTION-POLICY.1`
  Status: `done`
  Goal: `Document schedule-report evolution rules.`
  Acceptance: `The public docs state additive and breaking schedule-report change rules, and freeze blockers are updated.`
  Verification: `mdBook build and diff hygiene passed.`
  Commit: `743f0ea3 ISF-SCHEDULE-REPORT-EVOLUTION-POLICY.1: document report evolution policy`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-SCHEDULE-REPORT-EVOLUTION-POLICY.1` | `done` | Completed; tree closed. |

## Decisions

- `2026-05-16`: Treat new optional keys and value-family members as additive
  only when the same slice updates public contract metadata, tests, and docs.
  Removing, renaming, or changing the shape of advertised keys is breaking and
  requires a schedule-report `schema_version` bump plus migration/deprecation
  documentation.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-SCHEDULE-REPORT-EVOLUTION-POLICY.1` | `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SCHEDULE-REPORT-EVOLUTION-POLICY.1` | `743f0ea3 ISF-SCHEDULE-REPORT-EVOLUTION-POLICY.1: document report evolution policy` | `completion commit` |

## Changelog

- `2026-05-16`: Created task tree and opened the first documentation leaf.
- `2026-05-16`: Completed the first leaf and closed the tree.
