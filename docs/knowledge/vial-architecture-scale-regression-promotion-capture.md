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
date: 2026-09-02
status: current
tags: [hial, vial, scalability, regression, measurement, publication]
evidence: >-
  docs/decisions/0096-regression-promotion-uses-a-current-eleven-profile-corpus.md;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16df-vial-architecture-scale-cap-closeout.md;
  perl/FSM/VIAL/ArchitectureScaleRegressionPromotionPolicy.pm; perl/FSM/VIAL/ArchitectureScaleMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScaleRegressionPromotionCapturePlan.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionProfileStore.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionProfileCapture.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionCorpusStore.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionCorpusCoordinator.pm; scripts/run_vial_regression_promotion_corpus.pl; scripts/verify_vial_regression_promotion_failed_prefix.pl; scripts/verify_vial_regression_promotion_current_corpus.pl; scripts/measure_vial_regression_promotion_canonicalization.pl;
  t/1776-vial-regression-promotion-current-corpus-verifier.t; t/1777-vial-regression-promotion-current-corpus-mutations.t; t/1778-vial-regression-promotion-canonicalization-instrument.t
reverify: >-
  scripts/run_with_ram_guard.sh -- scripts/run_vial_regression_promotion_corpus.pl --validate; scripts/run_with_ram_guard.sh -- scripts/run_vial_regression_promotion_corpus.pl --inventory; scripts/verify_vial_regression_promotion_failed_prefix.pl; scripts/verify_vial_regression_promotion_current_corpus.pl; scripts/run_with_ram_guard.sh -- prove -v t/1777-vial-regression-promotion-current-corpus-mutations.t; scripts/run_with_ram_guard.sh -- scripts/measure_vial_regression_promotion_canonicalization.pl --phase corpus-load --sample-relative .artifacts/diagnostics/vial-scale/corpus.sample.txt --sample-seconds 3;
  scripts/run_with_ram_guard.sh -- scripts/measure_vial_regression_promotion_canonicalization.pl --phase balanced-validation --sample-relative .artifacts/diagnostics/vial-scale/balanced.sample.txt --sample-seconds 3
---

Decision 0096 selects eleven v2 gate profiles. Each adapter call owns one
validation plus three raw calls: 44 records in eleven guarded lifecycles.
Revision-1 matrices are inadmissible.

`.17.5.2.1` authenticates policy order and seven adapters without execution;
only OSVVM runtime binds qualified GHDL-plus-OSVVM execution. `.2` owns bounded
canonical same-volume per-profile publication, isolated ordinal workers,
parent reload, ordered admission, clean identities, and zero residue. `.3`
resumes only exact root-plus-ordinal evidence through fresh public validation;
stale coordinates, residue, mutation, exceptions, and signals reject, and
resume never seals the complete corpus. `.4` owns the two unbounded legacy
stores and separately audits semantic/bridge's direct coordinator loop.

Only clean `.17.5.2.3` may feed guarded capture in `.4`; unavailable providers
or disagreement withhold the seal. `.5` independently falsifies v2 evidence.
Historical substitution and budget promotion remain forbidden; budgets belong
solely to `.17.5.3`.

`.17.5.2.3.1` derives the sole complete coordinate, reloads eleven immutable
profiles, enforces 11/33/44/0, and atomically seals a bounded canonical report
plus manifest; common revision/host/guard and ordered heterogeneous providers
remain authenticated. `.3.2` supplies closed inventory/capture/validate
coordination with isolated child IPC and parent reload; only capture seals.
`.3.3` exposes explicit repository-derived CLI modes with bounded canonical
stdout, while `.17.5.2.4` alone owns real capture.

The first real capture at clean `610ed7869` sealed no corpus: structural
backend-emission failed closed because its fixed report axis `artifact_graph`
differs from the intentionally null policy-selection axis, a distinction the
synthetic doubles had masked. The exact four-report/600,036-byte prefix remains
in same-volume revision-keyed history as
`regression-promotion-failed-prefix/f46939aab1731f2b2a136a0d06cf161d4ff6ec99b2336559227a668c8b86e5a4`.
Its verifier accepts archive-only replay, separately authenticates any current
seal, and rejects mutation, foreign paths, hard-link aliasing, or cross-history
substitution before output.

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

The read-only independent verifier imports no production module and authenticates 13 files/6,220,126 bytes, inventory `94c11e5c...bb57`, all identities, 11/33/44/0, cleanup, nonclaims, and seven foundation/one materialized/three external routes.
That direct digest covers every file; production `file_set_sha256` directly covers report+manifest and transitively binds profiles. t1776 proves read-only identity; t1777 rejects 17 safe same-volume content/file/staging/history mutation classes, restores each copy, removes it, and leaves the real census exact.

`.17.5.2.5.3` adds a value/prototype-preserving JSON/clone/SHA diagnostic
underlay with no probe encode, separately counted top-level clones/recursive
nodes, and independent pre/post corpus authentication. On `fafe5d88b`, complete
load reads 6,220,126 unique bytes but its twelve plan/policy derivations encode
16,496,724 bytes. Balanced validation returns the exact 1,241,948-byte report
while materializing 1,447,616,826 tracked JSON bytes and hashing 1,044,992,073.
Required fresh gates/determinism/replay remain; `.3.1` owns repeated store-plan
derivation and `.3.2` the skipped accepted-composition emitter seam. These
diagnostics promote no regression budget, support tier, or capacity.

Related: [[vial-architecture-scale-proof]], [[vial-common-worker-output-census-admission]],
[[vial-portable-vhdl-runtime-scale]], [[vial-vhdl-osvvm-qualified-tier]].
