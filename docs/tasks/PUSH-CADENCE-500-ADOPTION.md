# PUSH-CADENCE-500-ADOPTION: 500-commit cadence

## Metadata

- Tree ID: `PUSH-CADENCE-500-ADOPTION`
- Status: `active`
- Roadmap lane: `infra/continuity`
- Created: `2026-09-23`
- Last updated: `2026-09-23`
- Owner: repo-local workflow

## Goal

Make 500 accumulated local commits the standing push interval.

## Non-Goals

- Do not push.
- Do not reset the Git-derived interval.
- Do not change per-slice commits or hosted qualification.

## Acceptance Criteria

- `COMMIT.md`, the current decision, the book, and the Knowledge Map name the same interval.
- Decision `0091` remains historical.
- The doctrine gate passes.

## Task Tree

- ID: `PUSH-CADENCE-500-ADOPTION`
  Status: `active`
  Goal: `Adopt 500 accumulated local commits as the standing push interval.`
  Acceptance: `Current policy, decision, book, and Knowledge Map agree. History stays exact. No push.`
  Verification: `pending`
  Commit: `pending`
  Children: `PUSH-CADENCE-500-ADOPTION.1`
- ID: `PUSH-CADENCE-500-ADOPTION.1`
  Status: `done`
  Goal: `Supersede decision 0091 and synchronize the standing interval.`
  Acceptance: `The current contract names 500 accumulated local commits. Existing unpushed commits still count. An explicit early push still starts a fresh interval.`
  Verification: `rg finds the standing interval in COMMIT.md. Decision 0102 is current. Decision 0091 records its successor. The book paragraph names the same interval. knowledge-map: OK routes the cadence questions to the current decision and retains the historical decisions as superseded.`
  Commit: `this commit`

## Acceptance Checklist (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '300 accumulated local' -1 --format='%H %s' -- COMMIT.md` identifies the former standing interval. The director selected 500 accumulated local commits.
- [x] **ADDRESSED (verified)** — `rg -n '500 accumulated local' COMMIT.md docs/decisions/0102-push-cadence-is-500-commits.md docs/book/src/90-reference-map.md` names the same interval. Existing unpushed commits still count. No push is part of this slice.
- [x] **NO REGRESSION** — `[doctrine] all doctrine checks passed`. `knowledge-map: OK` retains the historical cadence decisions as superseded and routes the current answer to decision 0102.
