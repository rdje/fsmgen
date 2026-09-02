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
date: 2026-09-02
status: current
tags: [hial, vial, scalability, regression, measurement, publication]
evidence: >-
  docs/decisions/0096-regression-promotion-uses-a-current-eleven-profile-corpus.md;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16df-vial-architecture-scale-cap-closeout.md;
  perl/FSM/VIAL/ArchitectureScaleRegressionPromotionPolicy.pm; perl/FSM/VIAL/ArchitectureScaleMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScaleRegressionPromotionCapturePlan.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionProfileStore.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionProfileCapture.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionCorpusStore.pm;
  t/1765-vial-architecture-scale-regression-promotion-policy.t; t/1766-vial-architecture-scale-regression-promotion-capture-plan.t; t/1767-vial-architecture-scale-regression-promotion-profile-store.t; t/1768-vial-architecture-scale-regression-promotion-profile-capture.t; t/1769-vial-architecture-scale-regression-promotion-profile-resume.t; t/1772-vial-regression-promotion-corpus-store.t
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl t/1766-vial-architecture-scale-regression-promotion-capture-plan.t t/1767-vial-architecture-scale-regression-promotion-profile-store.t t/1768-vial-architecture-scale-regression-promotion-profile-capture.t t/1769-vial-architecture-scale-regression-promotion-profile-resume.t t/1772-vial-regression-promotion-corpus-store.t
---

Decision 0096 selects eleven v2 gate profiles. Each adapter call owns one
validation plus three raw calls: 44 records in eleven guarded lifecycles.
Revision-1 matrices are inadmissible.

`.17.5.2.1` authenticates policy order and seals seven adapters, public methods,
arguments, prerequisites, counts, and v2 paths without producer execution.
Structural OSVVM binds read-only repository
materialization; only OSVVM runtime binds qualified GHDL-plus-OSVVM execution.

`.17.5.2.2.1` supplies bounded canonical same-volume publication, reload, and
exact recovery; its provisional 64 MiB limit proves no fit or capacity. `.2`
forks one ordinal-only child, runs and revalidates the public adapter, admits
the ordered accepted records, clean common/provider identity, and zero residue,
then publishes. Bounded metadata crosses IPC; the parent reloads exact bytes.

`.3` resumes an existing root-plus-ordinal publication without producer or
fallback. A fresh child repeats public validation and all admission, including
current host, RAM guard, foundation tool or sealed external provider; the
parent reloads and revalidates again. Stale plan/dispatch/common/provider state,
target or staging residue, v1 substitution, mutation, exceptions, and signals
reject. Resume never seals the complete corpus. `.4` owns two unbounded legacy
stores; public-method doubles create no real evidence.
Legacy child `.4.1` separately audits semantic/bridge's direct coordinator loop.

Only clean `.17.5.2.3` may feed guarded capture in `.4`; unavailable providers
or disagreement withhold the seal. `.5` independently falsifies v2 evidence.
Historical substitution and budget promotion remain forbidden; budgets belong
solely to `.17.5.3`.

Complete-store child `.17.5.2.3.1` now derives the sole v2 complete coordinate,
reloads all eleven immutable profile references, enforces 11/33/44/0, and
atomically seals canonical report plus manifest under 1,048,576/65,536-byte
containment limits. Revision/host/guard are globally common; heterogeneous
tool/provider identities remain ordered per profile. Transient publication
status is excluded from the corpus hash. The store executes no worker or tool;
`.17.5.2.3.2` still owns ordered coordination and `.17.5.2.4` real capture.

Related: [[vial-architecture-scale-proof]], [[vial-common-worker-output-census-admission]],
[[vial-portable-vhdl-runtime-scale]], [[vial-vhdl-osvvm-qualified-tier]].
