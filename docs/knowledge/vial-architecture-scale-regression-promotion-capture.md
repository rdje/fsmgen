---
id: vial-architecture-scale-regression-promotion-capture
title: VIAL regression promotion captures eleven current profiles through isolated v2 publication
answers:
  - "how will the VIAL architecture scale regression corpus be captured?"
  - "why does the VIAL current promotion corpus use eleven workers instead of 44 workers?"
  - "what does 44 invocations mean in the VIAL regression promotion policy?"
  - "which existing measurement adapters feed the VIAL v2 promotion corpus?"
  - "does the structural OSVVM promotion route execute GHDL?"
  - "how are VIAL promotion dispatch paths content addressed?"
  - "how does one VIAL regression-promotion profile run in isolation?"
  - "how is the VIAL v2 current corpus resumed and published?"
  - "how are regression-promotion report coordinates authenticated separately from policy selection?"
  - "did the repaired VIAL regression-promotion current corpus complete?"
  - "what is the current VIAL regression-promotion corpus identity and how can it be independently verified?"
  - "why is current VIAL regression-promotion corpus loading CPU bound?"
  - "why is balanced VIAL report validation expensive?"
  - "how is VIAL canonicalization cost measured without changing returned values?"
  - "why does VIAL complete-corpus validation separate capture and execution revisions?"
  - "why does VIAL complete-corpus validation isolate each whole profile operation?"
  - "how is the current VIAL regression-promotion budget qualification stored atomically?"
  - "how is the current VIAL regression-promotion budget qualification published or validated explicitly?"
  - "what is the real current VIAL regression-promotion budget qualification publication identity?"
  - "how is the current VIAL regression-promotion budget qualification independently verified?"
  - "how are copied VIAL current-budget qualification mutations and later-run applicability falsified?"
  - "how is VIAL current-budget qualification closed?"
  - "what is the VIAL regression-promotion gate contract?"
  - "when does a VIAL regression-promotion gate enforce performance?"
  - "does a VIAL regression gate recalibrate its own qualification?"
  - "where does the VIAL regression gate publish its latest observation?"
  - "how does one VIAL regression gate profile execute without publishing calibration evidence?"
  - "why does the VIAL regression gate use an anonymous report spool?"
  - "how does the VIAL regression gate distinguish provider absence from provider drift?"
  - "how are all eleven VIAL regression gate profiles coordinated in memory?"
  - "what is the VIAL regression gate aggregate precedence?"
date: 2026-09-03
status: current
tags: [hial, vial, scalability, regression, measurement, publication]
evidence: >-
  docs/decisions/0096-regression-promotion-uses-a-current-eleven-profile-corpus.md; docs/decisions/0097-regression-gates-publish-replaceable-observations-without-recalibrating.md;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16df-vial-architecture-scale-cap-closeout.md;
  perl/FSM/VIAL/ArchitectureScaleRegressionPromotionPolicy.pm; perl/FSM/VIAL/ArchitectureScaleMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScaleRegressionPromotionCapturePlan.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionProfileStore.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionProfileCapture.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionCorpusStore.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionCorpusCoordinator.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionQualification.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionQualificationStore.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionGateContract.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionGateProfile.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionGateCoordinator.pm;
  scripts/run_vial_regression_promotion_corpus.pl; scripts/run_vial_regression_promotion_budget_qualification.pl; scripts/verify_vial_regression_promotion_failed_prefix.pl; scripts/verify_vial_regression_promotion_current_corpus.pl; scripts/verify_vial_regression_promotion_budget_qualification.pl; scripts/measure_vial_regression_promotion_canonicalization.pl;
  t/1776-vial-regression-promotion-current-corpus-verifier.t; t/1777-vial-regression-promotion-current-corpus-mutations.t; t/1778-vial-regression-promotion-canonicalization-instrument.t; t/1779-vial-regression-promotion-qualification.t; t/1780-vial-regression-promotion-qualification-store.t; t/1781-vial-regression-promotion-qualification-cli.t; t/1782-vial-regression-promotion-budget-qualification-verifier.t; t/1783-vial-regression-promotion-budget-qualification-mutations.t; t/1784-vial-regression-promotion-budget-qualification-closeout.t; t/1785-vial-regression-promotion-gate-contract.t; t/1786-vial-regression-promotion-gate-profile.t; t/1787-vial-regression-promotion-gate-coordinator.t
reverify: >-
  scripts/run_with_ram_guard.sh -- scripts/run_vial_regression_promotion_corpus.pl --validate; scripts/run_with_ram_guard.sh -- scripts/run_vial_regression_promotion_corpus.pl --inventory; scripts/verify_vial_regression_promotion_failed_prefix.pl; scripts/verify_vial_regression_promotion_current_corpus.pl; scripts/run_with_ram_guard.sh -- prove -v t/1777-vial-regression-promotion-current-corpus-mutations.t; scripts/run_with_ram_guard.sh -- scripts/measure_vial_regression_promotion_canonicalization.pl --phase corpus-load --sample-relative .artifacts/diagnostics/vial-scale/corpus.sample.txt --sample-seconds 3;
  scripts/run_with_ram_guard.sh -- scripts/measure_vial_regression_promotion_canonicalization.pl --phase balanced-validation --sample-relative .artifacts/diagnostics/vial-scale/balanced.sample.txt --sample-seconds 3; scripts/run_with_ram_guard.sh -- prove -Iperl t/1769-vial-architecture-scale-regression-promotion-profile-resume.t t/1773-vial-regression-promotion-corpus-coordinator.t;
  scripts/run_with_ram_guard.sh -- prove -Iperl t/1779-vial-regression-promotion-qualification.t t/1780-vial-regression-promotion-qualification-store.t t/1781-vial-regression-promotion-qualification-cli.t; scripts/run_with_ram_guard.sh -- scripts/run_vial_regression_promotion_budget_qualification.pl --validate; scripts/run_with_ram_guard.sh -- scripts/verify_vial_regression_promotion_budget_qualification.pl;
  scripts/run_with_ram_guard.sh -- prove -v t/1782-vial-regression-promotion-budget-qualification-verifier.t t/1783-vial-regression-promotion-budget-qualification-mutations.t t/1784-vial-regression-promotion-budget-qualification-closeout.t; scripts/run_with_ram_guard.sh -- env FSMGEN_VIAL_REGRESSION_GATE_CONTRACT_EXACT=1 prove -Iperl -v t/1785-vial-regression-promotion-gate-contract.t; prove -Iperl -v t/1786-vial-regression-promotion-gate-profile.t t/1787-vial-regression-promotion-gate-coordinator.t
---

Decision 0096 selects eleven v2 gate profiles. Each adapter call owns one
validation plus three raw calls: 44 records in eleven guarded lifecycles.
Revision-1 matrices are inadmissible.

`.17.5.2` authenticates seven adapters, bounds same-volume storage, isolates
workers and parent reload, supports exact resume, exposes closed CLI modes, and
falsifies copied v2 evidence. Only clean capture can seal. Complete coordinates
enforce 11/33/44/0, common host/guard, provider order, and no history swap.

Clean `610ed7869` sealed no corpus: structural backend-emission's fixed
`artifact_graph` report axis differs from the null policy-selection axis. The
exact four-report/600,036-byte prefix remains in revision-keyed history as
`regression-promotion-failed-prefix/f46939aab1731f2b2a136a0d06cf161d4ff6ec99b2336559227a668c8b86e5a4`.
Its verifier accepts archive-only replay and rejects mutation, foreign paths,
hard-link aliasing, or cross-history substitution.

`.17.5.2.4.2` closes the defect without changing selection keys or paths:
capture-plan schema v2 pins producer-derived `report_coordinate_authority` for
all eleven entries, and capture/resume authenticate it independently of policy
selection. Changed, missing, rehashed, or aliased coordinates reject; the real
backend/runtime/balanced axes remain exact.

The repaired capture at clean `155aa22ea` contains 11 selected reports,
11 validations, 33 fresh raw measurements, 44 accepted invocations, and zero
exclusions. Its atomic same-volume corpus is
`regression-promotion-corpus/ab2df8992d85b8466f4afca530a5af36984031c453002534fc92ff5678a2e505`;
its publication identity is `regression-promotion-corpus-publication/865c5cce3deee3eaaca9b66cd5d7f007a6e10b6423ac7d5dff2dc7484cd8432e`;
the complete file-set digest is `dc5b315b827389eb466776716f6851cdd9ddd13b2f1aec441f8a51b7d72dc66f`.
Producer-free validate/inventory reproduced every identity/count with eleven
present, zero missing, and no staging. Copied-artifact falsification is complete.

The independent verifier imports no production module and authenticates 13
files/6,220,126 bytes, inventory `94c11e5c...bb57`, all identities, 11/33/44/0,
cleanup, nonclaims, and the 7/1/3 provider split. T1776 proves read-only
identity; t1777 rejects 17 copied mutation classes and restores exact census.

`.17.5.2.5.3` instruments JSON/clone/SHA without changing values. At
`fafe5d88b`, single-plan load cuts policy encodes 12→1 and observed
23.09→6.55 seconds; composition reuse cuts canonical bytes
1,325,878,982→813,307,147 and observed 492.56→297.92 seconds. Exact outputs
remain. Revision-separated validation then isolates each whole profile; at
`1da11b2e3`, all verification paths agree. These are not stable budgets.

`.17.5.3` derives and atomically seals the current qualification in a fixed
two-file v2 namespace, binding source, formula, budgets, environment/provider,
correctness, applicability, publisher, and immutable recalibration/rollback.
From `8667f766c`, its 764,010-byte report and 28,148-byte manifest bind
publication `1c2a3832...945f` and file set `28ba972c...9095`; distinct validation
returns 793,084 canonical bytes. Independent and copied-hostile verification
rejects content, schema, type, formula, budget, identity, provenance, path,
alias, staging, or residue drift. Later exact identity is eligible only after
correctness; environment drift is informational, deterministic drift rejects,
provider absence is not pass, and recalibration needs separately owned old/new
immutable evidence. T1784 closes both real censuses with no owned residue.

Decision 0097 and `.17.5.4.1` add the metadata-only gate contract at
`regression-promotion-gate-contract/0150f4b3...e368`. It joins all eleven
canonical dispatches to the sealed qualification without executing work,
requires correctness and exact deterministic identity before applicability,
compares every fresh metric maximum only on an exact environment, and permits
no enforcement override. Unmatched performance is informational; unavailable
providers remain unavailable. Repeated gates will atomically replace one
latest observation under the v2 gate namespace without changing qualification
bytes or creating budget evidence. `.17.5.4.2` owns execution and publication.

`.17.5.4.2.1` implements one profile only. One fresh child calls the selected
adapter once; child and parent validate the full canonical report through an
immediately unlinked same-volume spool, while IPC carries bounded metadata.
The qualification's caller-sealed projection verifies correctness before
maximum timing. Exact environment uses inclusive pass/fail, mismatch is
informational, absence is unavailable, and present provider drift rejects.
T1786 is synthetic and leaves no spool or process residue; all three real
exact-provider preflights report available without running a workload.

`.17.5.4.2.2` derives one contract, visits ordinals 1-11 once through the
sealed profile seams, and re-admits every full result into one bounded in-memory
aggregate. It separates required 11/33/44 totals from honest observed counts
when providers are unavailable; precedence is fail, unavailable,
informational, pass. T1787 is synthetic and publishes nothing.

Related: [[vial-architecture-scale-proof]], [[vial-common-worker-output-census-admission]],
[[vial-portable-vhdl-runtime-scale]], [[vial-vhdl-osvvm-qualified-tier]].
