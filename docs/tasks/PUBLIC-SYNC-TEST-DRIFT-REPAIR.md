# PUBLIC-SYNC-TEST-DRIFT-REPAIR: Restore Existing Public Sync Gates

## Metadata

- Tree ID: `PUBLIC-SYNC-TEST-DRIFT-REPAIR`
- Status: `proposed`
- Roadmap lane: `public-contract, specification, and focused-test synchronization`
- Created: `2026-07-23`
- Last updated: `2026-07-23`
- Owner: repo-local workflow

## Goal

Repair the pre-existing public synchronization failures independently
confirmed while closing the multi-bit loop-truthiness and requester
terminal-completion repairs.

## Root-Cause Evidence

- `t/1131` finds
  `schedule_report_verification_observation_keys` in the existing public
  contract payload but not in `public_top_level_presence_keys`.
- `t/1250` finds that the ISF specification focused-test index ends at t/1453
  even though existing HEAD already tracks t/1464 and later tests.
- `t/1474` expects the older `.ahb` wrong-object cardinality diagnostic ending
  at the one-subordinate aggregate shape, while the existing parser diagnostic
  already includes the shipped two-subordinate aggregate shape.

The guarded ISF suite passed 293 of 295 files; t/1131 and t/1250 were its only
failures. The t/1474 mismatch was independently reproduced from the unchanged
HEAD test and parser sources while the public requester `.ahb` source itself
continued to pass strict checking. All three conditions are outside the
changed loop lowering and requester terminal-count paths.

## Non-Goals

- Do not absorb this drift into the loop-truthiness or AHB terminal-count
  commits.
- Do not change any parser, scheduler, generated HDL, or runtime behavior.
- Do not activate while the current AHB BUSY-insertion work is in flight.

## Acceptance Criteria (when activated)

- Synchronize the verification-observation top-level public presence key with
  its already-shipped payload key and prove t/1131.
- Bring the ISF specification focused-test index through the current public
  test boundary using the repository's established indexing policy and prove
  t/1250.
- Synchronize t/1474's wrong-object diagnostic with the already-shipped
  two-subordinate aggregate wording and prove the full alias test.
- Run the relevant public-contract/spec/Knowledge Map/doctrine gates and a
  guarded ISF suite to confirm that all three existing red gates become green.

## Task Tree

- ID: `PUBLIC-SYNC-TEST-DRIFT-REPAIR`
  Status: `proposed`
  Goal: `Restore the pre-existing public synchronization gates without behavior changes.`
  Children: `PUBLIC-SYNC-TEST-DRIFT-REPAIR.1`, `PUBLIC-SYNC-TEST-DRIFT-REPAIR.2`, `PUBLIC-SYNC-TEST-DRIFT-REPAIR.3`

- ID: `PUBLIC-SYNC-TEST-DRIFT-REPAIR.1`
  Status: `pending`
  Goal: `Synchronize the shipped verification-observation public presence key.`
  Acceptance: `Update only the authoritative public-contract key listing and directly prove t/1131 plus relevant schema/presence checks.`
  Verification: `pending`
  Commit: `pending`

- ID: `PUBLIC-SYNC-TEST-DRIFT-REPAIR.2`
  Status: `pending`
  Goal: `Synchronize the ISF specification focused-test index through current HEAD.`
  Acceptance: `After .1 commits, update the authoritative ISF spec focused-test index under the established policy and prove t/1250 plus guarded ISF regression.`
  Verification: `pending`
  Commit: `pending`

- ID: `PUBLIC-SYNC-TEST-DRIFT-REPAIR.3`
  Status: `pending`
  Goal: `Synchronize the AHB alias wrong-object diagnostic expectation.`
  Acceptance: `After .2 commits, update only t/1474's stale aggregate-cardinality diagnostic regex to include the already-shipped two-subordinate shape; prove t/1474 and direct strict checking of ppif/ahb_requester.ahb.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-07-23`: Keep all fixes behind one proposed, inactive public-sync tree;
  they are documentation/schema/test-expectation drift, not behavioral
  prerequisites for the active AHB slice.

## Blockers

- Activation/order follows the task-tree pivot doctrine after ongoing active
  work dries out.
