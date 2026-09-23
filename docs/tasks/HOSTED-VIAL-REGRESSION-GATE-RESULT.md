# HOSTED-VIAL-REGRESSION-GATE-RESULT: hosted gate result

## Metadata

- Tree ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT`
- Status: `active`
- Roadmap lane: `verification architecture`
- Created: `2026-09-22`
- Last updated: `2026-09-23`
- Owner: repo-local workflow

## Goal

Make the hosted VIAL regression gate agree with one published result.

## Non-Goals

- Do not treat a failed or unavailable hosted run as support or capacity.
- Do not rewrite the local exact-pinned observation.

## Acceptance Criteria

- The failed hosted step is diagnosed from its released log.
- The workflow, verifier, public contract, and mdBook name one hosted result.
- Focused checks and the doctrine gate pass.

## Task Tree

- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT`
  Status: `active`
  Goal: `Publish one hosted VIAL regression result that the workflow, verifier, contract, and book all name.`
  Acceptance: `Diagnose the failed hosted command, then align the workflow and published contract with the result that command produces.`
  Verification: `pending`
  Commit: `pending`
  Children: `HOSTED-VIAL-REGRESSION-GATE-RESULT.1, HOSTED-VIAL-REGRESSION-GATE-RESULT.2, HOSTED-VIAL-REGRESSION-GATE-RESULT.3`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.1`
  Status: `done`
  Goal: `Diagnose the first hosted gate failure and own the contract contradiction.`
  Acceptance: `Record the released-log diagnosis that push 54ac1c22d ran the public vial-gate command and that step failed because the ignored calibration-closure publication is absent on a fresh checkout. Keep the published unavailable-aggregate contract distinct from that failure. Do not infer support or capacity.`
  Verification: `Run 35782532228 job 106931292867 failed ./bin/ci-regression vial-gate --no-book after evidence materialization and both validators. The guarded step died in validate_complete_publication because calibration closure publication root is absent at ArchitectureScaleCalibrationClosurePublication.pm:1046 for ignored .artifacts/qualification/vial-scale/v1/calibration-closure-v1. The independent verifier was skipped. The registered placement claim remains unchanged.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.2`
  Status: `done`
  Goal: `Make public policy derivation load the pinned tracked seal.`
  Acceptance: `The public vial-gate policy path loads vial/qualification/regression_promotion_policy/regression-promotion-policy-v1.json under the RAM guard and does not require the ignored calibration-closure publication. The pinned policy identity stays unchanged. A failed or unavailable hosted run remains neither support nor capacity.`
  Verification: `prove -Iperl t/1765-vial-architecture-scale-regression-promotion-policy.t passed. A copied checkout without the ignored publication derived the pinned identity and eleven profiles. Decision 0103 records the authority change.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.3`
  Status: `active`
  Goal: `Diagnose the hosted Perl-file shard failures from the same push.`
  Acceptance: `Own the released-log causes of the Perl-file shard failures separately from the absent closure publication. Do not treat those failures as support or capacity.`
  Verification: `pending`
  Commit: `pending`

## Acceptance Checklist (hosted gate released-log diagnosis HOSTED-VIAL-REGRESSION-GATE-RESULT.1)

- [x] **ROOT CAUSE (WHY + WHERE)** — The released failed-step log names the mechanism at `ArchitectureScaleCalibrationClosurePublication.pm line 1046`: `calibration closure publication root is absent`. `git log -S 'calibration-closure-v1' -- perl/FSM/VIAL/ArchitectureScaleRegressionPromotionPolicy.pm` shows `derive` still loads that ignored publication before the public gate can run.
- [x] **ADDRESSED (verified)** — Run 35782532228 job 106931292867 records that absence after both validators and before any profile result. The book, task tree, and knowledge card name that released-log cause. The published unavailable-aggregate contract stays distinct. Alignment remains HOSTED-VIAL-REGRESSION-GATE-RESULT.2.
- [x] **NO REGRESSION** — `knowledge-map: OK` preserves the earlier gate questions and adds the absent-publication route. The rendered book states the diagnosis outside the registered placement claim. Claim identity, dispositions, containment, and staged doctrines accompany the normal hooks.

## Acceptance Checklist (tracked policy seal HOSTED-VIAL-REGRESSION-GATE-RESULT.2)

- [x] **ROOT CAUSE (WHY + WHERE)** — Public `derive` required the ignored publication at `ArchitectureScaleRegressionPromotionPolicy.pm line 236` before this slice. `git log -S 'validate_complete_publication' -- perl/FSM/VIAL/ArchitectureScaleRegressionPromotionPolicy.pm` shows that call. A fresh checkout does not carry the publication, so the public gate stopped before any profile result.
- [x] **ADDRESSED (verified)** — Public derivation now loads `vial/qualification/regression_promotion_policy/regression-promotion-policy-v1.json` and validates the pinned identity. Focused t/1765 passed, including a same-volume checkout that lacks the sealed document. A copied checkout without the ignored publication derived the same identity. Decision 0103, the book, and the knowledge card name that route.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the earlier capture questions and adds the tracked-seal route. The published unavailable-aggregate contract and the local exact-pinned observation stay distinct. A failed or unavailable hosted run remains neither support nor capacity.
