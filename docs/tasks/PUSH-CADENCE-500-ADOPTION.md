# PUSH-CADENCE-500-ADOPTION: 500-commit cadence

## Metadata

- Tree ID: `PUSH-CADENCE-500-ADOPTION`
- Status: `done`
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
  Status: `done`
  Goal: `Adopt 500 accumulated local commits as the standing push interval.`
  Acceptance: `Current policy, decision, book, and Knowledge Map agree. History stays exact. No push.`
  Verification: `Both children are complete. Current COMMIT.md, decision 0102, mdBook and Knowledge Map agree on the standing interval; decision 0091 remains explicitly superseded with its historical evidence. Git-derived counting, per-slice commits and mandatory hosted-result qualification remain unchanged. No push or counter reset occurred.`
  Commit: `PUSH-CADENCE-500-ADOPTION.2: close verified push cadence adoption`
  Children: `PUSH-CADENCE-500-ADOPTION.1, PUSH-CADENCE-500-ADOPTION.2`
- ID: `PUSH-CADENCE-500-ADOPTION.1`
  Status: `done`
  Goal: `Supersede decision 0091 and synchronize the standing interval.`
  Acceptance: `The current contract names 500 accumulated local commits. Existing unpushed commits still count. An explicit early push still starts a fresh interval.`
  Verification: `rg finds the standing interval in COMMIT.md. Decision 0102 is current. Decision 0091 records its successor. The book paragraph names the same interval. knowledge-map: OK routes the cadence questions to the current decision and retains the historical decisions as superseded.`
  Commit: `this commit`

- ID: `PUSH-CADENCE-500-ADOPTION.2`
  Status: `done`
  Goal: `Verify policy agreement and close the completed cadence adoption.`
  Acceptance: `Recheck the authoritative workflow, current decision, superseded history, mdBook and Knowledge Map. Confirm the counter remains Git-derived and per-slice/hosted qualification unchanged. Close the root and remove its active row without pushing or changing policy; preserve the HIAL dependency question.`
  Verification: `Independent source assertions report cadence-closeout: workflow, current decision, historical predecessor and book agree; Git-derived counting, per-slice commits and hosted qualification remain explicit. The current and superseded frontmatter links agree. knowledge-map: OK verifies routed-source/query parity. The parent and both children are terminal; its active-index row is removed. No policy, book content, push or interval reset changes.`
  Commit: `this commit`

## Acceptance Checklist (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '300 accumulated local' -1 --format='%H %s' -- COMMIT.md` identifies the former standing interval. The director selected 500 accumulated local commits.
- [x] **ADDRESSED (verified)** — `rg -n '500 accumulated local' COMMIT.md docs/decisions/0102-push-cadence-is-500-commits.md docs/book/src/90-reference-map.md` names the same interval. Existing unpushed commits still count. No push is part of this slice.
- [x] **NO REGRESSION** — `[doctrine] all doctrine checks passed`. `knowledge-map: OK` retains the historical cadence decisions as superseded and routes the current answer to decision 0102.

## Acceptance Checklist (parent closeout .2)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'PUSH-CADENCE-500-ADOPTION.1'` identifies `0c8dd4b82`. The implementation leaf is done and policy surfaces already agree, but the parent and active index still advertise unfinished adoption without an executable leaf.
- [x] **ADDRESSED (verified)** — Source assertions independently compare the authoritative workflow, current decision, superseded predecessor and book. They check the standing interval together with Git-derived counting, per-slice commits, early-push treatment and mandatory hosted qualification. The completed parent now leaves the active index while its history remains addressable in this task and Git.
- [x] **NO REGRESSION** — `knowledge-map: OK` verifies canonical decision routes and cached/direct query parity. Re-derive: COMMIT.md and decision 0102; falsify: separate mdBook and predecessor-status/link assertions reject a stale active interval; durability: current policy, supersession metadata, canonical query and this owning task. No source policy changes, push, counter reset, hosted-pass claim or HIAL launch occurs.
