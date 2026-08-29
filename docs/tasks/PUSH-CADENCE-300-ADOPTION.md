# PUSH-CADENCE-300-ADOPTION: 300-Commit Cadence

## Metadata

- Tree ID: `PUSH-CADENCE-300-ADOPTION`
- Status: `done`
- Roadmap lane: `infra/continuity`
- Created: `2026-08-29`
- Last updated: `2026-08-29`
- Owner: repo-local workflow

## Task Tree

- ID: `PUSH-CADENCE-300-ADOPTION`
  Status: `done`
  Goal: `Adopt 300 commits; preserve commits, exceptions, qualification, and history.`
  Children: `PUSH-CADENCE-300-ADOPTION.1`

- ID: `PUSH-CADENCE-300-ADOPTION.1`
  Status: `done`
  Goal: `Supersede 0062 and synchronize policy.`
  Acceptance: `300 is current; history is exact; gates pass; no push.`
  Verification: `PASS — book, map, integrity, doctrines.`
  Commit: `PUSH-CADENCE-300-ADOPTION.1: adopt 300-commit cadence`

## Acceptance Checklist

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '200 accumulated local' -- COMMIT.md` locates former authority commit `93e185c3c766`.
- [x] **ADDRESSED (verified)** — `rg -n '300 accumulated local|300th committed|standing 300-commit' COMMIT.md` proves the new contract; decision `0091`, Knowledge Map, active references, and mdBook agree.
- [x] **NO REGRESSION** — `mdbook build docs/book` and `knowledge-map: OK` pass; final gate reports `[doctrine] all doctrine checks passed`.

## Containment Finding

The rationale transition allowance is saturated; the existing `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION` tree owns compaction before another decision record is added.
