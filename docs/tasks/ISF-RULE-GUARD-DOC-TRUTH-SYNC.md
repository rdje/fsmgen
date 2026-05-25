# ISF-RULE-GUARD-DOC-TRUTH-SYNC: Rule Guard Backlog Truth Synchronization

## Metadata

- Tree ID: `ISF-RULE-GUARD-DOC-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Synchronize stale ISF rule-guard documentation that still describes
standalone enum member and scalar aggregate rule guards as backlog after those
forms shipped in the current 13xx ISF test band.

## Non-Goals

- Do not change parser, scheduler, emitter, schedule-report, generated `.fsm`,
  or HDL behavior.
- Do not widen rule guard syntax beyond the already-shipped standalone enum
  member and scalar aggregate storage leaf forms.
- Do not change enum target, enum operator-position, aggregate
  operator-position, or subaggregate rule-target deferrals.

## Acceptance Criteria

- The ISF spec no longer lists standalone enum member or scalar aggregate rule
  guards as deferred.
- The mdBook feature backlog no longer lists standalone enum/aggregate rule
  guards as backlog and explicitly points to the shipped shorthand/long-form
  rule guard surface.
- A focused audit prevents the stale backlog wording from returning.
- Live docs and roadmap/task-tree state are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-RULE-GUARD-DOC-TRUTH-SYNC`
  Status: `done`
  Goal: `Remove stale rule-guard backlog wording from the spec and book.`
  Children: `ISF-RULE-GUARD-DOC-TRUTH-SYNC.1`

- ID: `ISF-RULE-GUARD-DOC-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Synchronize rule-guard backlog wording and add a focused audit.`
  Acceptance: `The ISF spec and mdBook backlog both state that standalone enum
  and scalar aggregate rule guards are shipped, while the remaining enum target,
  operator-position, and subaggregate deferrals stay explicit.`
  Verification: `perl -Iperl -c t/1306-isf-rule-guard-doc-truth-audit.t`;
  `prove -Iperl t/1306-isf-rule-guard-doc-truth-audit.t
  t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`;
  `./bin/ci-regression isf --no-book`; `git diff --check`
  Commit: `7e898397 ISF-RULE-GUARD-DOC-TRUTH-SYNC.1: sync rule guard docs`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-RULE-GUARD-DOC-TRUTH-SYNC.1` | `done` | The book backlog contradicted the shipped 1301/1302 rule-guard behavior. |

## Decisions

- `2026-05-16`: This is a documentation-truth slice because the shipped
  behavior is already covered by `t/1301` and `t/1302`.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-RULE-GUARD-DOC-TRUTH-SYNC.1` | `perl -Iperl -c t/1306-isf-rule-guard-doc-truth-audit.t`; `prove -Iperl t/1306-isf-rule-guard-doc-truth-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | passed; ISF gate Files=212, Tests=887 |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-RULE-GUARD-DOC-TRUTH-SYNC.1` | `7e898397 ISF-RULE-GUARD-DOC-TRUTH-SYNC.1: sync rule guard docs` | `completion commit` |

## Changelog

- `2026-05-16`: Removed stale rule-guard backlog wording from the ISF spec and
  book backlog, and added a focused doc-truth audit.
