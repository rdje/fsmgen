# PUBLIC-SYNC-TEST-DRIFT-REPAIR: Restore Existing Public Sync Gates

## Metadata

- Tree ID: `PUBLIC-SYNC-TEST-DRIFT-REPAIR`
- Status: `active`
- Roadmap lane: `public-contract, specification, and focused-test synchronization`
- Created: `2026-07-23`
- Last updated: `2026-07-30`
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
  Status: `active`
  Goal: `Restore the pre-existing public synchronization gates without behavior changes.`
  Children: `PUBLIC-SYNC-TEST-DRIFT-REPAIR.1`, `PUBLIC-SYNC-TEST-DRIFT-REPAIR.2`, `PUBLIC-SYNC-TEST-DRIFT-REPAIR.3`

- ID: `PUBLIC-SYNC-TEST-DRIFT-REPAIR.1`
  Status: `done`
  Goal: `Synchronize the shipped verification-observation public presence-key family.`
  Acceptance: `Update only the authoritative public-contract key listing with the three already-shipped verification-observation key families and directly prove an empty payload/list difference, t/1131, plus relevant schema/presence checks.`
  Verification: `Activated only after clean parent selector commit 06c03e6bf through clean activation commit 6a166c62e. Added exactly schedule_report_verification_observation_keys, schedule_report_verification_observation_role_values, and schedule_report_verification_observation_signal_keys to isf_public_interface_public_top_level_keys(), beside the existing schedule-report key families. The direct set-difference probe moves from three missing / zero extra to missing=0 / extra=0. Perl syntax passes. A guarded focused/adjacent public-contract run passes t1112/t1113/t1114/t1115/t1116/t1131/t1260/t297/t321 with All tests successful, Files=9, Tests=21. Feature-backlog status, live-book-path, and relative-path audits pass with Files=3, Tests=40; Knowledge Map generation/check passes at 1,068 facts / 5,499 question keys; mdBook HTML build and diff hygiene pass; Memory remains at 60 lines and README at 246. The payload, schema version, parser, scheduler, manifest shape, source language, generated artifacts, HDL/runtime behavior, and pending .2/.3 owners are unchanged.`
  Commit: `PUBLIC-SYNC-TEST-DRIFT-REPAIR.1: synchronize public presence keys`

- ID: `PUBLIC-SYNC-TEST-DRIFT-REPAIR.2`
  Status: `done`
  Goal: `Synchronize the ISF specification focused-test index through current HEAD.`
  Acceptance: `After .1 commits, add exactly the five current t/*-isf-*.t paths missing from the authoritative ISF spec focused-test index under its lexicographic policy and prove zero missing/extra paths, t/1250, plus guarded ISF regression.`
  Verification: `Activated only after clean .1 implementation commit 012660f90 through clean activation commit 300fa057b. Added exactly the five measured links in lexicographic order: t1464 UVM passive monitor, t1465 VHDL observation package, t1476 output default reset, t1542 named-drive priority readiness, and t1544 assertion precedence readiness. The exact comparison moves from listed=327 / expected=332 / five missing / zero extra to listed=332 / expected=332 / missing=0 / extra=0. Focused t1250 passes with All tests successful, Files=1, Tests=2. The host100/process4096 guarded ./bin/ci-regression isf --no-book passes All tests successful, Files=295, Tests=2037 in 618 seconds. No test, parser, scheduler, source language, generated artifact, HDL/runtime behavior, or pending .3 owner changes.`
  Commit: `PUBLIC-SYNC-TEST-DRIFT-REPAIR.2: synchronize focused-test index`

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
- `2026-07-30`: Clean parent selector commit `06c03e6bf` selects and activates
  only `.1`; current-HEAD evidence refines its authoritative-list correction
  to the three verification-observation discovery families. `.2` and `.3`
  remain pending and unchanged.
- `2026-07-30`: `.1` synchronizes the exact three-key verification-observation
  presence family and restores t1131 without changing the payload or behavior.
- `2026-07-30`: Clean `.1` commit `012660f90` activates `.2`; its exact
  current-HEAD boundary is five missing focused-test links and zero extras.
- `2026-07-30`: `.2` adds exactly those five links, restores a 332/332 exact
  index, and passes the full guarded ISF regression without behavior changes.

## Blockers

- `.1` is complete at clean `012660f90`; `.2` is complete in this commit. `.3`
  may activate only after `.2` commits cleanly.

## Acceptance Checklist (enforced for implementation changes)

- [x] **ROOT CAUSE (WHY + WHERE)** — The pre-fix public discovery audit failed
  at t/1131-isf-public-top-level-discovery-audit.t line 72; the exact contract
  set-difference probe named the three verification-observation payload keys
  missing from `isf_public_interface_public_top_level_keys()`.
- [x] **ADDRESSED (verified)** — The same exact probe now reports `missing=0`
  and `extra=0`, and t1131 passes in the guarded public-contract test set.
- [x] **NO REGRESSION** — The guarded direct/JSON/defensive-copy/CLI-manifest/
  key-family/discovery/verification-observation/capability/embedding set reports
  `All tests successful` with `Files=9, Tests=21`; the final staged doctrine
  driver is also required.
