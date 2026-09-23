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
  Children: `HOSTED-VIAL-REGRESSION-GATE-RESULT.1, HOSTED-VIAL-REGRESSION-GATE-RESULT.2, HOSTED-VIAL-REGRESSION-GATE-RESULT.3, HOSTED-VIAL-REGRESSION-GATE-RESULT.4, HOSTED-VIAL-REGRESSION-GATE-RESULT.5, HOSTED-VIAL-REGRESSION-GATE-RESULT.6, HOSTED-VIAL-REGRESSION-GATE-RESULT.7, HOSTED-VIAL-REGRESSION-GATE-RESULT.8, HOSTED-VIAL-REGRESSION-GATE-RESULT.9`
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
  Status: `done`
  Goal: `Diagnose the hosted Perl-file shard failures from the same push.`
  Acceptance: `Record the released-log census for run 35782532228. Separate Yosys deadline, OSVVM artifact-oracle, ignored-publication, and support-status causes. Do not treat those failures as support or capacity.`
  Verification: `Released failed-step logs for all 16 Perl-file jobs and the terminal build job are stored under ignored .artifacts/tmp/hosted-ci-20260923. The census names the four families below. Local prove of t/350 reproduces the support-status failure.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.4`
  Status: `done`
  Goal: `Admit the shipped regression-gate support status the audit already rejects.`
  Acceptance: `t/350 accepts shipped_bounded_regression_gate because that contract already carries non-empty guidance. Leave the semantic-family contract, which has a status and no guidance field, for its own leaf.`
  Verification: `prove -Iperl t/350-support-contract-builder-audit.t reports Files=1, Tests=57 and fails only subtest 54, FSM::Support::VIALSemanticFamilyContract. The regression contract is no longer in the failure. That remaining contract is HOSTED-VIAL-REGRESSION-GATE-RESULT.5.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.5`
  Status: `done`
  Goal: `Give the semantic-family support contract the guidance field its audit requires, or record why that contract is outside the audit.`
  Acceptance: `Do not invent guidance. Either add the field the contract's own shape requires, or exclude that module from the guidance assertion with a recorded reason.`
  Verification: `prove -Iperl t/350-support-contract-builder-audit.t reports All tests successful at Files=1, Tests=57. The semantic-family module stays outside the guidance assertion because its own nonclaims already exclude support_classification and its key list omits guidance.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.6`
  Status: `done`
  Goal: `Stop t/1765 and t/1766 from dying when the ignored calibration closure is absent.`
  Acceptance: `The mutation subtests that read the ignored closure skip with a recorded reason when that file is absent, and still run when it is present. Public derivation stays independent of that file. Do not invent a hosted pass.`
  Verification: `With the closure present, prove of t/1765 and t/1766 reports All tests successful at Files=2, Tests=15. With the file temporarily hidden and then restored, the same command passes. The released logs named those two files at t/1765 line 258 and t/1766 line 466.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.7`
  Status: `done`
  Goal: `Stop t/1776 from dying when the ignored current corpus is absent.`
  Acceptance: `The corpus-dependent subtests skip with a recorded reason when the ignored corpus is absent, and still run when it is present. The closed-invocation check stays. Do not invent a hosted pass.`
  Verification: `With the corpus present, and again with it hidden and restored, prove of t/1776 reports All tests successful at Files=1, Tests=3. The released log named the missing corpus at t/1776 line 166.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.8`
  Status: `done`
  Goal: `Stop t/1777 from dying when the ignored current corpus is absent.`
  Acceptance: `Every mutation subtest and the trailing identity check skip with a recorded reason when the ignored corpus is absent, and still run when it is present. Do not invent a hosted pass.`
  Verification: `With the corpus present, prove of t/1777 reports All tests successful at Files=1, Tests=7. With the corpus hidden and restored, the same command passes and skips those checks. The released log died at t/1777 line 304.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.9`
  Status: `active`
  Goal: `Stop the next hosted test from requiring an ignored qualification path on a fresh checkout.`
  Acceptance: `The next released-log reader of an ignored .artifacts/qualification/vial-scale path either uses a tracked publication or skips that ignored input with a recorded reason. Do not invent a hosted pass.`
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

## Acceptance Checklist (hosted Perl-file census HOSTED-VIAL-REGRESSION-GATE-RESULT.3)

- [x] **ROOT CAUSE (WHY + WHERE)** — Run 35782532228 failed all 16 Perl-file jobs. The released logs name four families: `yosys_synthesis` `status=timed_out` in the paired-busy alias tests; `OSVVM runtime artifact graph failed its exact oracle` at `ArchitectureScaleOSVVMRuntimeMaterialization.pm line 249`; tests that `Can't stat` ignored `.artifacts/qualification/vial-scale` paths; and `t/350-support-contract-builder-audit.t line 64` rejecting two shipped support statuses. `git log -S 'shipped_bounded_regression_gate' -- perl/FSM/Support` shows the regression status is shipped while the audit allow-list omits it.
- [x] **ADDRESSED (verified)** — The census is recorded here and in the book. Local `prove -Iperl t/350-support-contract-builder-audit.t` reproduces the support-status failure. The Yosys deadline, OSVVM oracle, and ignored-publication families stay separate. The terminal build job failed because those families failed. None of them is support or capacity.
- [x] **NO REGRESSION** — `knowledge-map: OK` preserves the tracked-seal route. The parse messages that precede passing language-contract tests stay expected diagnostics. Repair of the support-status allow-list remains HOSTED-VIAL-REGRESSION-GATE-RESULT.4.

## Acceptance Checklist (regression support status HOSTED-VIAL-REGRESSION-GATE-RESULT.4)

- [x] **ROOT CAUSE (WHY + WHERE)** — Before this slice, `prove -Iperl t/350-support-contract-builder-audit.t` failed at `t/350-support-contract-builder-audit.t line 64` because the allow-list omitted `shipped_bounded_regression_gate`. `git log -S 'shipped_bounded_regression_gate' -- perl/FSM/Support/VIALArchitectureScaleRegressionContract.pm` shows that status is already shipped, and the same module already returns a non-empty guidance array.
- [x] **ADDRESSED (verified)** — The allow-list now admits only that status. Focused prove reports Files=1, Tests=57 and fails only subtest 54, `FSM::Support::VIALSemanticFamilyContract`, at `t/350-support-contract-builder-audit.t line 65` and line 73. The regression contract is no longer in the failure. The semantic-family contract remains HOSTED-VIAL-REGRESSION-GATE-RESULT.5.
- [x] **NO REGRESSION** — `knowledge-map: OK` preserves the four hosted families and records that the regression status is now admitted. Unrelated statuses stay omitted. A failed or unavailable hosted run remains neither support nor capacity.

## Acceptance Checklist (semantic-family guidance exemption HOSTED-VIAL-REGRESSION-GATE-RESULT.5)

- [x] **ROOT CAUSE (WHY + WHERE)** — After the regression status was admitted, `prove -Iperl t/350-support-contract-builder-audit.t` still failed at `t/350-support-contract-builder-audit.t line 73` because `FSM::Support::VIALSemanticFamilyContract` returns no guidance array. `git log -S 'support_classification' -- perl/FSM/Support/VIALSemanticFamilyContract.pm` shows that module already names support_classification as an explicit nonclaim and omits guidance from its own key list.
- [x] **ADDRESSED (verified)** — The audit now exempts that module from the guidance assertion and requires the recorded nonclaim instead of inventing guidance. Focused prove reports All tests successful at Files=1, Tests=57.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the hosted census and records the exemption. Every other support contract still requires non-empty guidance. A failed or unavailable hosted run remains neither support nor capacity.

## Acceptance Checklist (ignored closure readers HOSTED-VIAL-REGRESSION-GATE-RESULT.6)

- [x] **ROOT CAUSE (WHY + WHERE)** — The released Perl-file logs die at `t/1765-vial-architecture-scale-regression-promotion-policy.t line 258` and `t/1766-vial-architecture-scale-regression-promotion-capture-plan.t line 466` with `cannot read` the ignored calibration-closure JSON. `git log -S 'calibration-closure.json' -- t/1765-vial-architecture-scale-regression-promotion-policy.t` shows those mutation checks still load that ignored publication.
- [x] **ADDRESSED (verified)** — Those mutation subtests now skip when the ignored file is absent and still run when it is present. Focused prove with the file present, and again with the file hidden and then restored, reports All tests successful at Files=2, Tests=15. Public derivation does not read the ignored file.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the tracked-seal route and records the skip. Remaining ignored-path readers stay HOSTED-VIAL-REGRESSION-GATE-RESULT.7. A failed or unavailable hosted run remains neither support nor capacity.

## Acceptance Checklist (ignored current-corpus reader HOSTED-VIAL-REGRESSION-GATE-RESULT.7)

- [x] **ROOT CAUSE (WHY + WHERE)** — The released Perl-file log fails `t/1776-vial-regression-promotion-current-corpus-verifier.t` because `Can't stat` the ignored current corpus, then dies at `t/1776-vial-regression-promotion-current-corpus-verifier.t line 166` inside the corpus census. `git log -S 'regression-promotion-corpus-v1' -- t/1776-vial-regression-promotion-current-corpus-verifier.t` shows that test still reads the ignored publication.
- [x] **ADDRESSED (verified)** — The two corpus-dependent subtests now skip when that directory is absent and still run when it is present. The closed-invocation check stays. Focused prove with the corpus present, and again with it hidden and restored, reports All tests successful at Files=1, Tests=3.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the earlier closure skip and records this corpus skip. Remaining ignored-path readers stay HOSTED-VIAL-REGRESSION-GATE-RESULT.8. A failed or unavailable hosted run remains neither support nor capacity.

## Acceptance Checklist (ignored corpus mutations HOSTED-VIAL-REGRESSION-GATE-RESULT.8)

- [x] **ROOT CAUSE (WHY + WHERE)** — The released Perl-file log dies at `t/1777-vial-regression-promotion-current-corpus-mutations.t line 304` with `Can't stat` the ignored current corpus, then reports `mutation fixture source tree is unavailable`. `git log -S 'regression-promotion-corpus-v1' -- t/1777-vial-regression-promotion-current-corpus-mutations.t` shows the mutation fixture still copies that ignored publication before any assertion.
- [x] **ADDRESSED (verified)** — Every mutation subtest and the trailing identity check now skip when that directory is absent and still run when it is present. Focused prove with the corpus present reports All tests successful at Files=1, Tests=7. The same command with the corpus hidden and restored also passes.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the earlier corpus-verifier skip and records this mutation skip. Remaining ignored-path readers stay HOSTED-VIAL-REGRESSION-GATE-RESULT.9. A failed or unavailable hosted run remains neither support nor capacity.
