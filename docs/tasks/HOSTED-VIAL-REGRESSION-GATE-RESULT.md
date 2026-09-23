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
  Children: `HOSTED-VIAL-REGRESSION-GATE-RESULT.1, HOSTED-VIAL-REGRESSION-GATE-RESULT.2, HOSTED-VIAL-REGRESSION-GATE-RESULT.3, HOSTED-VIAL-REGRESSION-GATE-RESULT.4, HOSTED-VIAL-REGRESSION-GATE-RESULT.5, HOSTED-VIAL-REGRESSION-GATE-RESULT.6, HOSTED-VIAL-REGRESSION-GATE-RESULT.7, HOSTED-VIAL-REGRESSION-GATE-RESULT.8, HOSTED-VIAL-REGRESSION-GATE-RESULT.9, HOSTED-VIAL-REGRESSION-GATE-RESULT.10, HOSTED-VIAL-REGRESSION-GATE-RESULT.11, HOSTED-VIAL-REGRESSION-GATE-RESULT.12, HOSTED-VIAL-REGRESSION-GATE-RESULT.13, HOSTED-VIAL-REGRESSION-GATE-RESULT.14, HOSTED-VIAL-REGRESSION-GATE-RESULT.15, HOSTED-VIAL-REGRESSION-GATE-RESULT.16, HOSTED-VIAL-REGRESSION-GATE-RESULT.17, HOSTED-VIAL-REGRESSION-GATE-RESULT.18, HOSTED-VIAL-REGRESSION-GATE-RESULT.19, HOSTED-VIAL-REGRESSION-GATE-RESULT.20, HOSTED-VIAL-REGRESSION-GATE-RESULT.21, HOSTED-VIAL-REGRESSION-GATE-RESULT.22, HOSTED-VIAL-REGRESSION-GATE-RESULT.23, HOSTED-VIAL-REGRESSION-GATE-RESULT.24, HOSTED-VIAL-REGRESSION-GATE-RESULT.25`
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
  Status: `done`
  Goal: `Stop t/1767 from dying when the ignored calibration closure is absent.`
  Acceptance: `Every profile-store subtest that copies the ignored closure skips with a recorded reason when that file is absent, and still runs when it is present. Do not invent a hosted pass.`
  Verification: `With the closure present, prove of t/1767 reports All tests successful at Files=1, Tests=11. With the closure hidden and restored, the same command passes. The released log died at t/1767 line 76 with cannot copy calibration closure into fixture.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.10`
  Status: `done`
  Goal: `Stop t/1771 from failing when the ignored revision-1 publication is absent.`
  Acceptance: `The revision-1 census skips with a recorded reason when that ignored tree is absent, and still runs when it is present. The synthetic publisher checks stay. Do not invent a hosted pass.`
  Verification: `With the publication present, prove of t/1771 reports All tests successful at Files=1, Tests=3. With the tree hidden and restored, the same command passes. The released log failed the census at t/1771 line 69 after Can't stat vial-scale/v1.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.11`
  Status: `done`
  Goal: `Stop t/1772 from dying when the ignored calibration closure is absent.`
  Acceptance: `Every corpus-store subtest and the trailing cleanup check skip with a recorded reason when the ignored closure is absent, and still run when it is present. Do not invent a hosted pass.`
  Verification: `With the closure present, prove of t/1772 reports All tests successful at Files=1, Tests=9. With the closure hidden and restored, the same command passes. The released log died with cannot read calibration-closure.json before any subtest.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.12`
  Status: `done`
  Goal: `Stop t/1782 from dying when the ignored budget qualification inputs are absent.`
  Acceptance: `The two input-dependent verifier subtests skip with a recorded reason when either ignored tree is absent, and still run when both are present. The closed-invocation check stays. Do not invent a hosted pass.`
  Verification: `With both inputs present, prove of t/1782 reports All tests successful at Files=1, Tests=3. With both trees hidden and restored, the same command passes. The released log died at t/1782 line 202 with Can't stat the ignored current qualification and corpus.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.13`
  Status: `done`
  Goal: `Stop t/1783 from dying when the ignored budget qualification inputs are absent.`
  Acceptance: `The mutation checks skip with a recorded counted reason when either ignored tree is absent, and still run when both are present. Do not invent a hosted pass.`
  Verification: `With both inputs present, prove of t/1783 reports All tests successful at Files=1, Tests=16. With both trees hidden and restored, the same command passes at Files=1, Tests=10. The released log died at t/1783 line 568 with Can't stat, then mutation fixture source tree is unavailable.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.14`
  Status: `done`
  Goal: `Stop t/1784 from dying when the ignored budget qualification inputs are absent.`
  Acceptance: `The reconstruction and residue subtests skip with a recorded reason when either ignored tree is absent, and still run when both are present. The executable-contract check stays. Do not invent a hosted pass.`
  Verification: `With both inputs present, guarded prove of t/1784 reports All tests successful at Files=1, Tests=3. With both trees hidden and restored, the same command passes. The released log died at t/1784 line 289 with Can't stat the ignored qualification and corpus.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.15`
  Status: `done`
  Goal: `Stop t/1775 from dying when the ignored failed-prefix inputs are absent.`
  Acceptance: `The three evidence subtests skip with a recorded reason when either ignored tree is absent, and still run when both are present. Do not invent a hosted pass.`
  Verification: `With both inputs present, prove of t/1775 reports All tests successful at Files=1, Tests=3. With both trees hidden and restored, the same command passes. The released log died before any subtest with verifier fixture source tree is unavailable.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.16`
  Status: `done`
  Goal: `Stop t/1792 from requiring the unshipped IPC::Run3 module.`
  Acceptance: `The hosted-result verifier test captures the verifier with core IPC::Open3. Focused prove passes. Do not invent a hosted pass.`
  Verification: `prove -Iperl t/1792-vial-regression-promotion-hosted-result-verifier.t reports All tests successful at Files=1, Tests=5. The released log died at t/1792 line 11 because IPC/Run3.pm is absent from the hosted Perl image.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.17`
  Status: `done`
  Goal: `Stop t/1676 from dying when the ignored OSVVM provider cache is absent.`
  Acceptance: `The provider-backed subtests skip with a recorded reason when the ignored cache is absent, and still run when it is present. Provider-free construction and preflight checks stay. Do not inspect the OSVVM submodule or invent a hosted pass.`
  Verification: `With the cache present, prove of t/1676 reports All tests successful at Files=1, Tests=5. With the cache hidden and restored, the same command passes. The released log died at ArchitectureScaleOSVVMRuntimeMaterialization.pm line 249 because the ordinary shard does not materialize the provider.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.18`
  Status: `done`
  Goal: `Stop t/1677 from dying when the ignored OSVVM provider cache is absent.`
  Acceptance: `The execution-plan subtests skip with a recorded reason when the ignored cache is absent, and still run when it is present. Do not inspect the OSVVM submodule or invent a hosted pass.`
  Verification: `With the cache present, prove of t/1677 reports All tests successful at Files=1, Tests=4. With the cache hidden and restored, the same command passes and skips those checks. The released log died at ArchitectureScaleOSVVMRuntimeMaterialization.pm line 249, called from t/1677 line 57.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.19`
  Status: `done`
  Goal: `Stop t/1679 from failing when the ignored OSVVM provider cache is absent.`
  Acceptance: `The measurement guard check accepts the recorded cache absence when that ignored cache is absent, and still requires the active RAM guard when it is present. Do not inspect the OSVVM submodule or invent a hosted pass.`
  Verification: `With the cache present, prove of t/1676, t/1677, and t/1679 reports All tests successful at Files=3, Tests=17. With the cache hidden and restored, the same command passes. The released log failed t/1679 line 161 because the artifact-graph oracle preceded the RAM-guard check.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.20`
  Status: `done`
  Goal: `Stop the persisted-request tests from dying when the ignored OSVVM provider cache is absent.`
  Acceptance: `t/1740 through t/1747 skip with a recorded reason when the ignored cache is absent, and still run when it is present. Do not inspect the OSVVM submodule or invent a hosted pass.`
  Verification: `With the cache present, prove of t/1740 through t/1747 reports All tests successful at Files=8, Tests=18. With the cache hidden and restored, the same command passes. The released logs died in OSVVMRuntimePersistedRequest.pm line 25 for t/1740 through t/1747.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.21`
  Status: `done`
  Goal: `Stop the paired-busy alias tests from failing the hosted Perl-file shards on the Yosys synthesis deadline.`
  Acceptance: `The eleven released paired-busy tests record the sealed 120-second Yosys deadline and do not treat that deadline as a pass. Decision 0101 keeps the wall. A failed or unavailable hosted run remains neither support nor capacity.`
  Verification: `Run 35782532228 stopped yosys_synthesis with status=timed_out at t/1515 line 144, t/1516 line 152, t/1523 line 165, t/1524 line 129, t/1525 line 173, t/1526 line 148, t/1534 line 148, t/1537 line 168, t/1538 line 136, t/1539 line 186, and t/1540 line 155. Focused prove of t/1526 reports Files=1, Tests=4. With the Darwin runtime qualified, the other ten report Files=10, Tests=39.`
  Commit: `this commit`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.22`
  Status: `done`
  Goal: `Stop the OSVVM gallery refresh from dying when the ignored provider cache is absent.`
  Acceptance: `scripts/refresh_vial_vhdl_osvvm_gallery.pl records the absent exact OSVVM 2026.05 provider cache before emission and does not treat that absence as a current gallery. t/1799 and t/1800 record that absence for the OSVVM case only. Native and portable gallery checks stay. Do not inspect the OSVVM submodule or invent a hosted pass.`
  Verification: `Focused prove of t/1799 and t/1800 reports All tests successful at Files=2, Tests=10 with the cache present, and again with the cache hidden and restored.`
  Commit: `993feb28d`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.23`
  Status: `done`
  Goal: `Stop the hosted lsof observer stall from failing outside the Linux observer the supervisor actually runs.`
  Acceptance: `t/1756 stalls the host observer that ProcessSupervisor executes. Linux stalls ps, the process census it runs. Darwin stalls lsof, the pipe-identity command it runs. A stall still returns one explicit process failure. Do not treat a missing observer as a pass.`
  Verification: `Focused prove on Darwin reports All tests successful at Files=1, Tests=1.`
  Commit: `0ae36ce2f`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.24`
  Status: `active`
  Goal: `Stop the HIAL/VIAL book entry check from requiring a SUMMARY cluster that omits a nested chapter.`
  Acceptance: `t/1796 requires the current nested HIAL/VIAL SUMMARY cluster, including Inactive Proxy Lifetimes. The stable overview and future-backlog checks stay. Do not invent a hosted pass.`
  Verification: `pending`
  Commit: `pending`
- ID: `HOSTED-VIAL-REGRESSION-GATE-RESULT.25`
  Status: `pending`
  Goal: `Diagnose the next released Perl-file failure family after the book entry path.`
  Acceptance: `Name the next released family from the hosted logs and make that ordinary path fail closed without inventing a hosted pass.`
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

## Acceptance Checklist (ignored profile-store closure HOSTED-VIAL-REGRESSION-GATE-RESULT.9)

- [x] **ROOT CAUSE (WHY + WHERE)** — The released Perl-file log dies at `t/1767-vial-architecture-scale-regression-promotion-profile-store.t line 76` with `cannot copy calibration closure into fixture`. `git log -S 'calibration-closure.json' -- t/1767-vial-architecture-scale-regression-promotion-profile-store.t` shows the fixture still copies that ignored publication before the sealed plan exists.
- [x] **ADDRESSED (verified)** — Every profile-store subtest now skips when that closure is absent and still runs when it is present. Focused prove with the closure present reports All tests successful at Files=1, Tests=11. The same command with the closure hidden and restored also passes.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the earlier corpus skip and records this profile-store skip. Remaining ignored-path readers stay HOSTED-VIAL-REGRESSION-GATE-RESULT.10. A failed or unavailable hosted run remains neither support nor capacity.

## Acceptance Checklist (ignored revision-1 census HOSTED-VIAL-REGRESSION-GATE-RESULT.10)

- [x] **ROOT CAUSE (WHY + WHERE)** — The released Perl-file log fails the census at `t/1771-vial-legacy-matrix-publication-bounds.t line 69` after `Can't stat` ignored `.artifacts/qualification/vial-scale/v1` at line 360. `git log -S 'vial-scale/v1' -- t/1771-vial-legacy-matrix-publication-bounds.t` shows that census still walks the ignored publication.
- [x] **ADDRESSED (verified)** — The census now skips when that tree is absent and still runs when it is present. The synthetic publisher checks stay. Focused prove with the publication present reports All tests successful at Files=1, Tests=3. The same command with the tree hidden and restored also passes.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the earlier profile-store skip and records this census skip. Remaining ignored-path readers stay HOSTED-VIAL-REGRESSION-GATE-RESULT.11. A failed or unavailable hosted run remains neither support nor capacity.

## Acceptance Checklist (ignored corpus-store closure HOSTED-VIAL-REGRESSION-GATE-RESULT.11)

- [x] **ROOT CAUSE (WHY + WHERE)** — The released Perl-file log dies before any subtest with `cannot read` the ignored calibration-closure JSON. `git log -S 'calibration-closure.json' -- t/1772-vial-regression-promotion-corpus-store.t` shows the sealed plan still loads that ignored publication.
- [x] **ADDRESSED (verified)** — Every corpus-store subtest and the trailing cleanup check now skip when that file is absent and still run when it is present. Focused prove with the closure present reports All tests successful at Files=1, Tests=9. The same command with the closure hidden and restored also passes.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the earlier census skip and records this corpus-store skip. Remaining ignored-path readers stay HOSTED-VIAL-REGRESSION-GATE-RESULT.12. A failed or unavailable hosted run remains neither support nor capacity.

## Acceptance Checklist (ignored budget verifier HOSTED-VIAL-REGRESSION-GATE-RESULT.12)

- [x] **ROOT CAUSE (WHY + WHERE)** — The released Perl-file log dies at `t/1782-vial-regression-promotion-budget-qualification-verifier.t line 202` with `Can't stat` the ignored current qualification and source corpus. `git log -S 'regression-promotion-budget-qualification-v1' -- t/1782-vial-regression-promotion-budget-qualification-verifier.t` shows those checks still census the ignored trees.
- [x] **ADDRESSED (verified)** — The two input-dependent subtests now skip when either ignored tree is absent and still run when both are present. The closed-invocation check stays. Focused prove with both inputs present reports All tests successful at Files=1, Tests=3. The same command with both trees hidden and restored also passes.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the earlier corpus-store skip and records this budget-verifier skip. Remaining ignored-path readers stay HOSTED-VIAL-REGRESSION-GATE-RESULT.13. A failed or unavailable hosted run remains neither support nor capacity.

## Acceptance Checklist (ignored budget mutations HOSTED-VIAL-REGRESSION-GATE-RESULT.13)

- [x] **ROOT CAUSE (WHY + WHERE)** — The released Perl-file log dies at `t/1783-vial-regression-promotion-budget-qualification-mutations.t line 568` with `Can't stat` the ignored qualification and corpus, then reports `mutation fixture source tree is unavailable`. `git log -S 'regression-promotion-budget-qualification-v1' -- t/1783-vial-regression-promotion-budget-qualification-mutations.t` shows the fixture still copies those ignored trees before any assertion.
- [x] **ADDRESSED (verified)** — The mutation checks now skip with a counted reason when either ignored tree is absent and still run when both are present. Focused prove with both inputs present reports All tests successful at Files=1, Tests=16. The same command with both trees hidden and restored passes at Files=1, Tests=10.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the earlier budget-verifier skip and records this mutation skip. Remaining ignored-path readers stay HOSTED-VIAL-REGRESSION-GATE-RESULT.14. A failed or unavailable hosted run remains neither support nor capacity.

## Acceptance Checklist (ignored budget closeout HOSTED-VIAL-REGRESSION-GATE-RESULT.14)

- [x] **ROOT CAUSE (WHY + WHERE)** — The released Perl-file log dies at `t/1784-vial-regression-promotion-budget-qualification-closeout.t line 289` with `Can't stat` the ignored qualification and corpus, then fails the reconstruction at line 78. `git log -S 'regression-promotion-budget-qualification-v1' -- t/1784-vial-regression-promotion-budget-qualification-closeout.t` shows the closeout still censuses those ignored trees before any subtest.
- [x] **ADDRESSED (verified)** — The reconstruction and residue subtests now skip when either ignored tree is absent and still run when both are present. The executable-contract check stays. Guarded prove with both inputs present reports All tests successful at Files=1, Tests=3. The same command with both trees hidden and restored also passes.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the earlier budget-mutation skip and records this closeout skip. Remaining ignored-path readers stay HOSTED-VIAL-REGRESSION-GATE-RESULT.15. A failed or unavailable hosted run remains neither support nor capacity.

## Acceptance Checklist (ignored failed-prefix verifier HOSTED-VIAL-REGRESSION-GATE-RESULT.15)

- [x] **ROOT CAUSE (WHY + WHERE)** — The released Perl-file log dies before any subtest with `verifier fixture source tree is unavailable` at `t/1775-vial-regression-promotion-failed-prefix-verifier.t line 140`. `git log -S 'regression-promotion-report-coordinate-failure-ordinal-5-v1' -- t/1775-vial-regression-promotion-failed-prefix-verifier.t` shows the fixture still copies that ignored history archive and the ignored current corpus before any subtest.
- [x] **ADDRESSED (verified)** — The three evidence subtests now skip when either ignored tree is absent and still run when both are present. Focused prove with both inputs present reports All tests successful at Files=1, Tests=3. The same command with both trees hidden and restored also passes.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the earlier budget-closeout skip and records this failed-prefix skip. Remaining ignored-path readers stay HOSTED-VIAL-REGRESSION-GATE-RESULT.16. A failed or unavailable hosted run remains neither support nor capacity.

## Acceptance Checklist (hosted-result core capture HOSTED-VIAL-REGRESSION-GATE-RESULT.16)

- [x] **ROOT CAUSE (WHY + WHERE)** — The released Perl-file log dies at `t/1792-vial-regression-promotion-hosted-result-verifier.t line 11` with `Can't locate IPC/Run3.pm`. `git log -S 'IPC::Run3' -- t/1792-vial-regression-promotion-hosted-result-verifier.t` shows that test was the only repository reader of the unshipped module.
- [x] **ADDRESSED (verified)** — The test now captures the verifier with core `IPC::Open3`, matching the sibling failed-prefix verifier. Focused prove reports All tests successful at Files=1, Tests=5.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the failed-prefix skip and records this core capture. The OSVVM artifact-graph oracle and the Yosys synthesis deadline stay HOSTED-VIAL-REGRESSION-GATE-RESULT.17. A failed or unavailable hosted run remains neither support nor capacity.

## Acceptance Checklist (absent OSVVM provider cache HOSTED-VIAL-REGRESSION-GATE-RESULT.17)

- [x] **ROOT CAUSE (WHY + WHERE)** — The released Perl-file log dies at `ArchitectureScaleOSVVMRuntimeMaterialization.pm line 249` with `OSVVM runtime artifact graph failed its exact oracle`, called from `t/1676-vial-architecture-scale-osvvm-runtime-materialization.t line 121`. Decision 0088 materializes exact OSVVM 2026.05 only for dedicated coordinates t/1598, t/1648, and t/1650. `git check-ignore` shows `.artifacts/cache/providers/osvvm/2026.05/source` is ignored, so an ordinary shard does not carry it.
- [x] **ADDRESSED (verified)** — The three provider-backed subtests now skip when that cache is absent and still run when it is present. Ownership, construction, and provider-free preflight checks stay. Focused prove with the cache present reports All tests successful at Files=1, Tests=5. The same command with the cache hidden and restored also passes.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the core-capture repair and records this provider-cache skip. Remaining ordinary OSVVM readers stay HOSTED-VIAL-REGRESSION-GATE-RESULT.18. A failed or unavailable hosted run remains neither support nor capacity.

## Acceptance Checklist (absent OSVVM execution-plan cache HOSTED-VIAL-REGRESSION-GATE-RESULT.18)

- [x] **ROOT CAUSE (WHY + WHERE)** — The released Perl-file log dies at `ArchitectureScaleOSVVMRuntimeMaterialization.pm line 249` with `OSVVM runtime artifact graph failed its exact oracle`, called from `t/1677-vial-architecture-scale-osvvm-runtime-execution-plan.t line 57`. `git log -S 'ArchitectureScaleOSVVMRuntimeExecutionPlan' -- t/1677-vial-architecture-scale-osvvm-runtime-execution-plan.t` shows that plan still evaluates the ignored provider graph. Decision 0088 materializes exact OSVVM 2026.05 only for dedicated coordinates t/1598, t/1648, and t/1650.
- [x] **ADDRESSED (verified)** — The four execution-plan subtests now skip when that cache is absent and still run when it is present. Focused prove with the cache present reports All tests successful at Files=1, Tests=4. The same command with the cache hidden and restored also passes.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the materialization skip and records this execution-plan skip. Remaining ordinary OSVVM readers stay HOSTED-VIAL-REGRESSION-GATE-RESULT.19. A failed or unavailable hosted run remains neither support nor capacity.

## Acceptance Checklist (absent OSVVM measurement cache HOSTED-VIAL-REGRESSION-GATE-RESULT.19)

- [x] **ROOT CAUSE (WHY + WHERE)** — The released Perl-file log fails `t/1679-vial-architecture-scale-osvvm-runtime-measurement.t line 161` because `validate_profile` reaches `ArchitectureScaleOSVVMRuntimeMaterialization.pm line 249` before the RAM-guard check. `git log -S 'OSVVM runtime artifact graph failed its exact oracle' -- perl/FSM/VIAL/ArchitectureScaleOSVVMRuntimeMaterialization.pm` shows that oracle still runs for every materialized level. Decision 0088 materializes exact OSVVM 2026.05 only for dedicated coordinates t/1598, t/1648, and t/1650.
- [x] **ADDRESSED (verified)** — Materialized evaluation now stops with `exact OSVVM 2026.05 provider cache is absent` before the oracle. The measurement guard check accepts that recorded absence and still requires the active RAM guard when the cache is present. Focused prove of t/1676, t/1677, and t/1679 with the cache present reports All tests successful at Files=3, Tests=17. The same command with the cache hidden and restored also passes.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the execution-plan skip and records this measurement fail-closed absence. Remaining ordinary OSVVM readers stay HOSTED-VIAL-REGRESSION-GATE-RESULT.20. A failed or unavailable hosted run remains neither support nor capacity.

## Acceptance Checklist (absent OSVVM persisted-request cache HOSTED-VIAL-REGRESSION-GATE-RESULT.20)

- [x] **ROOT CAUSE (WHY + WHERE)** — The released Perl-file logs die at `t/lib/FSM/Test/OSVVMRuntimePersistedRequest.pm line 25` with `OSVVM runtime artifact graph failed its exact oracle`, called from t/1740 line 18, t/1741 line 16, t/1742 line 16, t/1743 line 19, t/1744 line 16, t/1745 line 17, t/1746 line 16, and t/1747 line 40. `git log -S 'ArchitectureScaleOSVVMRuntimeExecutionPlan' -- t/lib/FSM/Test/OSVVMRuntimePersistedRequest.pm` shows that helper still evaluates the ignored provider graph before any assertion.
- [x] **ADDRESSED (verified)** — Those eight tests now skip when the ignored cache is absent and still run when it is present. Focused prove with the cache present reports All tests successful at Files=8, Tests=18. The same command with the cache hidden and restored also passes.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the measurement fail-closed absence and records this persisted-request skip. The Yosys synthesis deadline stays HOSTED-VIAL-REGRESSION-GATE-RESULT.21. A failed or unavailable hosted run remains neither support nor capacity.

## Acceptance Checklist (sealed Yosys synthesis deadline HOSTED-VIAL-REGRESSION-GATE-RESULT.21)

- [x] **ROOT CAUSE (WHY + WHERE)** — Run 35782532228 stopped `yosys_synthesis` with `status=timed_out: supervised process exceeded its fixed deadline` at `t/1526-ial2-ahb-two-subordinate-exact-two-paired-busy-composition-profile-alias.t line 148`, and at the same `--verify-hdl` check in t/1515 line 144, t/1516 line 152, t/1523 line 165, t/1524 line 129, t/1525 line 173, t/1534 line 148, t/1537 line 168, t/1538 line 136, t/1539 line 186, and t/1540 line 155. `git log -S 'hdl_external_validation_step_timeout_seconds' -- perl/FSM/Support/HDLExternalValidation.pm` shows the 120-second wall is sealed. Decision 0101 keeps that wall.
- [x] **ADDRESSED (verified)** — Those eleven tests now record `hosted Yosys synthesis deadline is sealed at 120 seconds` before Yosys starts. Focused prove of t/1526 reports All tests successful at Files=1, Tests=4. With `FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1`, the other ten report All tests successful at Files=10, Tests=39. `FSMGEN_HOSTED_YOSYS_DEADLINE_CHECK=1` keeps the check.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the persisted-request skip and records this deadline. The next released family stays HOSTED-VIAL-REGRESSION-GATE-RESULT.22. A failed or unavailable hosted run remains neither support nor capacity.

## Acceptance Checklist (absent OSVVM gallery cache HOSTED-VIAL-REGRESSION-GATE-RESULT.22)

- [x] **ROOT CAUSE (WHY + WHERE)** — Run 35782532228 failed `refresh_vial_vhdl_osvvm_gallery.pl checked gallery is current` at `t/1799-hial-vial-legacy-migration.t line 368` and `refresh_vial_vhdl_osvvm_gallery.pl succeeds` at `t/1800-hial-vial-capability-support-reference.t line 231`. Both stderr texts are `cannot emit OSVVM gallery` with `VIAL_OSVVM_PROVIDER_MATERIALIZATION_ERROR` and `OSVVM dependency root is not materialized` at `OSVVM2026_05Materialization.pm line 130`. `git log -S 'OSVVM dependency root is not materialized' -- perl/FSM/VIAL/Backend/OSVVM2026_05Materialization.pm` shows emission still verifies the ignored provider root. Decision 0088 materializes exact OSVVM 2026.05 only for dedicated coordinates.
- [x] **ADDRESSED (verified)** — `scripts/refresh_vial_vhdl_osvvm_gallery.pl` now records `exact OSVVM 2026.05 provider cache is absent on an ordinary checkout` before emission. t/1799 and t/1800 require that recorded absence for the OSVVM case and still require the current census when the cache is present. Native and portable gallery checks stay. Focused prove with the cache present reports All tests successful at Files=2, Tests=10. The same command with the cache hidden and restored also passes.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the sealed Yosys deadline and records this gallery absence. The next released family stays HOSTED-VIAL-REGRESSION-GATE-RESULT.23. A failed or unavailable hosted run remains neither support nor capacity.

## Acceptance Checklist (host-observer stall HOSTED-VIAL-REGRESSION-GATE-RESULT.23)

- [x] **ROOT CAUSE (WHY + WHERE)** — Run 35782532228 failed `lsof stall returns one explicit process failure` at `t/1756-vial-selected-tool-host-observer-deadline.t line 101` with got `F` expected `S`. `git log -S 'linux-pipe-inode' -- perl/FSM/VIAL/Backend/ProcessSupervisor.pm` shows Linux authenticates the containment pipe from `/proc` and runs `ps` for the process census. The stalling `lsof` fixture is the Darwin pipe-identity command, so the hosted Ubuntu probe never executed it.
- [x] **ADDRESSED (verified)** — The stall injection now follows the observer the host runs: Linux stalls `ps`, and Darwin stalls `lsof`. A stall still has to return one explicit process failure. Focused prove on Darwin reports All tests successful at Files=1, Tests=1.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the gallery absence and records this host-observer stall. The next released family stays HOSTED-VIAL-REGRESSION-GATE-RESULT.24. A failed or unavailable hosted run remains neither support nor capacity.

## Acceptance Checklist (HIAL/VIAL book entry path HOSTED-VIAL-REGRESSION-GATE-RESULT.24)

- [x] **ROOT CAUSE (WHY + WHERE)** — Run 35782532228 failed `SUMMARY nests specialist evidence beneath the stable overview` at `t/1796-hial-vial-book-entry-path.t line 63`. The expected cluster omitted the nested chapter already present in `docs/book/src/SUMMARY.md`. `git log -S '16dk-inactive-proxy-lifetimes.md' -- docs/book/src/SUMMARY.md` shows Inactive Proxy Lifetimes is part of that nested entry path.
- [x] **ADDRESSED (verified)** — The entry check now requires that current nested cluster, including Inactive Proxy Lifetimes. The overview names the same chapter. Focused prove reports All tests successful at Files=1, Tests=4.
- [x] **NO REGRESSION** — `knowledge-map: OK` keeps the host-observer stall and records this entry path. The next released family stays HOSTED-VIAL-REGRESSION-GATE-RESULT.25. A failed or unavailable hosted run remains neither support nor capacity.
