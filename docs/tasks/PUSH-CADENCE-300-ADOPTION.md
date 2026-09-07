# PUSH-CADENCE-300-ADOPTION: 300-Commit Cadence

## Metadata

- Tree ID: `PUSH-CADENCE-300-ADOPTION`
- Status: `done`
- Roadmap lane: `infra/continuity`
- Created: `2026-08-29`
- Last updated: `2026-09-07`
- Owner: repo-local workflow

## Task Tree

- ID: `PUSH-CADENCE-300-ADOPTION`
  Status: `done`
  Goal: `Adopt 300 commits; preserve commits, exceptions, qualification, and history.`
  Children: `PUSH-CADENCE-300-ADOPTION.1, PUSH-CADENCE-300-ADOPTION.2`

- ID: `PUSH-CADENCE-300-ADOPTION.1`
  Status: `done`
  Goal: `Supersede 0062 and synchronize policy.`
  Acceptance: `300 is current; history is exact; gates pass; no push.`
  Verification: `PASS — book, map, integrity, doctrines.`
  Commit: `PUSH-CADENCE-300-ADOPTION.1: adopt 300-commit cadence`

- ID: `PUSH-CADENCE-300-ADOPTION.2`
  Status: `done`
  Goal: `Preserve the director's clarification that generic batch size does not select an earlier push.`
  Acceptance: `Record the clarified selection against COMMIT.md and decision 0091; retain per-slice commits and pre-push qualification; validate the documentation slice and commit without pushing.`
  Verification: `The Knowledge Map routes cadence to decision 0091; COMMIT.md and the mdBook publication paragraph agree with the director's clarification. The RAM-guarded task-tree checker passes while this owner is active, and git diff --check passes. The staged doctrine driver and commit hook gate closure; evidence is under .artifacts/logs/push-cadence-reaffirmation-20260907/. Product behavior and the existing repair frontier are unchanged.`
  Commit: `PUSH-CADENCE-300-ADOPTION.2: reaffirm cadence independent of batch size`

## Director Clarification

On `2026-09-07`, the director clarified that batch length and push cadence
are independent settings. BWFSC defaults to 100 steps when no count is given;
that number controls how many tasks/slices/lanes run, not when commits are
pushed. The push cadence stays at 300 accumulated local commits unless the
director explicitly changes it. The assistant's earlier description of the
batch default as a push cadence was a conflation, not a repository policy.
This reaffirms `COMMIT.md` and decision `0091` without resetting the
Git-derived interval. Complete and commit every slice separately. Reaching
the cadence still requires the existing pre-push checks and exact
hosted-result qualification.

The existing mdBook publication paragraph in
`docs/book/src/90-reference-map.md` already matches the selected cadence;
no product documentation or behavior change is needed. The startup review
uses the director's task-directed scope retained in `SESSION-READING-SCOPE`.
`MEMORY.md` retains the Rust/Verilator fixture-startup repair frontier and its
pre-push qualification blocker. No push is part of this clarification slice.

## Acceptance Checklist

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '200 accumulated local' -- COMMIT.md` locates former authority commit `93e185c3c766`.
- [x] **ADDRESSED (verified)** — `rg -n '300 accumulated local|300th committed|standing 300-commit' COMMIT.md` proves the new contract; decision `0091`, Knowledge Map, active references, and mdBook agree.
- [x] **NO REGRESSION** — `mdbook build docs/book` and `knowledge-map: OK` pass; final gate reports `[doctrine] all doctrine checks passed`.

## Containment Finding

The rationale transition allowance is saturated; the existing `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION` tree owns compaction before another decision record is added.
