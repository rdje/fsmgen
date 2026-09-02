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
  - "how is the VIAL v2 current corpus resumed and published?"
date: 2026-09-02
status: current
tags: [hial, vial, scalability, regression, measurement, publication]
evidence: >-
  docs/decisions/0096-regression-promotion-uses-a-current-eleven-profile-corpus.md;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16df-vial-architecture-scale-cap-closeout.md;
  perl/FSM/VIAL/ArchitectureScaleRegressionPromotionPolicy.pm;
  perl/FSM/VIAL/ArchitectureScaleRegressionPromotionCapturePlan.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionProfileStore.pm;
  t/1765-vial-architecture-scale-regression-promotion-policy.t; t/1766-vial-architecture-scale-regression-promotion-capture-plan.t; t/1767-vial-architecture-scale-regression-promotion-profile-store.t
reverify: >-
  prove -Iperl t/1766-vial-architecture-scale-regression-promotion-capture-plan.t t/1767-vial-architecture-scale-regression-promotion-profile-store.t
---

Decision 0096 selects eleven current gate profiles under the non-colliding
`.artifacts/qualification/vial-scale/v2/regression-promotion-corpus-v1/`
publication. Broad matrix publishers remain revision-1 history and cannot
satisfy v2 current evidence. Each current adapter's public measurement call
owns one validation followed by three raw calls. Thus 44 controller records
group into eleven guard-visible profile lifecycles, not 44 workers.

`.17.5.2.1` now ships a closed, defensive, content-addressed dispatch plan. It
authenticates the policy and maps its order to seven adapters, public methods,
closed arguments, producer metadata, prerequisites, record counts, and unique
repository-relative v2 paths. Each path combines the policy ordinal with a
hash of the full selection key. Fatal producer/controller doubles prove that
derivation reads metadata without executing or publishing work.

The provider contract keeps two OSVVM responsibilities separate. Structural
OSVVM emission requires the exact repository-materialization identity but no
external verification tool. Only the OSVVM runtime dispatch requires the exact
qualified GHDL-plus-OSVVM tool profile. Metadata, provider, duplicate, missing,
unknown-coordinate, and revision-1-path mutations all fail closed.

Seven v1 matrices duplicate family-specific stores, so `.17.5.2.2.1` now owns
plan-derived paths, canonical envelopes, same-volume directory rename, bounded
identity reload, exact recovery, and fail-closed topology. Its provisional 64
MiB ceiling proves no fit/capacity; `.17.5.2.2.4` owns two unbounded legacy stores.

Only clean `.17.5.2.3` implementation may feed `.4`, which runs the guarded real
capture at one revision and publishes only after all eleven profiles and all
44 controller records reload with zero exclusions. Any unavailable provider or
current disagreement keeps the complete seal absent and stays owned for root
cause; historical bytes, relaxed validation, and forced acceptance are
forbidden.

`.17.5.2.5` independently reloads and falsifies the complete v2 evidence before
closing the parent. Performance budgets remain unpromoted and belong solely to
`.17.5.3`.

Related: [[vial-architecture-scale-proof]], [[vial-common-worker-output-census-admission]],
[[vial-portable-vhdl-runtime-scale]], [[vial-vhdl-osvvm-qualified-tier]].
