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
date: 2026-09-02
status: current
tags: [hial, vial, scalability, regression, measurement, publication]
evidence: >-
  docs/decisions/0096-regression-promotion-uses-a-current-eleven-profile-corpus.md;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16df-vial-architecture-scale-cap-closeout.md;
  perl/FSM/VIAL/ArchitectureScaleRegressionPromotionPolicy.pm; perl/FSM/VIAL/ArchitectureScaleMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScaleRegressionPromotionCapturePlan.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionProfileStore.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionProfileCapture.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionCorpusStore.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionCorpusCoordinator.pm; scripts/run_vial_regression_promotion_corpus.pl; scripts/verify_vial_regression_promotion_failed_prefix.pl;
  t/1765-vial-architecture-scale-regression-promotion-policy.t; t/1766-vial-architecture-scale-regression-promotion-capture-plan.t; t/1767-vial-architecture-scale-regression-promotion-profile-store.t; t/1768-vial-architecture-scale-regression-promotion-profile-capture.t; t/1769-vial-architecture-scale-regression-promotion-profile-resume.t; t/1772-vial-regression-promotion-corpus-store.t; t/1773-vial-regression-promotion-corpus-coordinator.t; t/1774-vial-regression-promotion-corpus-cli.t
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl t/1766-vial-architecture-scale-regression-promotion-capture-plan.t t/1767-vial-architecture-scale-regression-promotion-profile-store.t t/1768-vial-architecture-scale-regression-promotion-profile-capture.t t/1769-vial-architecture-scale-regression-promotion-profile-resume.t t/1772-vial-regression-promotion-corpus-store.t t/1773-vial-regression-promotion-corpus-coordinator.t t/1774-vial-regression-promotion-corpus-cli.t; scripts/verify_vial_regression_promotion_failed_prefix.pl
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
`.17.5.2.3.2` now adds closed inventory/capture/validate coordination. It walks
the plan once, delegates isolation and bounded child IPC to ProfileCapture,
reloads each artifact in the parent, and seals only after complete common and
route-specific admission. Inventory executes no worker; validate requires an
existing seal and cannot capture. `.17.5.2.4` still owns real capture.

`.17.5.2.3.3` completes the public CLI. It derives the repository from its
tracked script and requires one explicit limits, inventory, capture, or
validate mode; missing flags never default into capture. Canonical stdout is
encoded and bounded before writing, including the newline. Fresh-process
synthetic controls prove dispatch and the exact boundary without real work.

The first real guarded capture at clean revision `610ed7869` published the
first four profiles and then failed closed at structural backend-emission
ordinal five: its canonical report requires `primary_axis=artifact_graph`,
while the policy selection coordinate is intentionally null. All seven later
producer reports likewise own a fixed report axis distinct from their null
selection axis; synthetic doubles had copied the selection value and masked
the distinction. No corpus seal was written. The exact four-report/600,036-byte
prefix plus a canonical failure manifest is preserved in the revision-keyed
same-volume history archive with identity
`regression-promotion-failed-prefix/f46939aab1731f2b2a136a0d06cf161d4ff6ec99b2336559227a668c8b86e5a4`;
the active v2 namespace is empty. The repository-relative
`verify_vial_regression_promotion_failed_prefix.pl` rechecks every fixed
identity, byte, hash, record, path, device, link, owner, and residue invariant;
a copied report mutation rejects before emitting a result.

`.17.5.2.4.2` closes the admission defect without changing a selection key or
publication path. Capture-plan schema v2 carries a distinct authenticated
`report_coordinate_authority` on every entry. Each of the seven adapters
derives its four report coordinates through canonical producer ownership, and
the plan pins the resulting eleven identities. Capture and resume compare
reports to this authority rather than to policy selection coordinates.
Backend, runtime, and balanced selection axes remain null, while their real
report axes are respectively `artifact_graph`, `runtime_trace_records`, and
`interaction_profile`. Synthetic reports reproduce those real axes. Changed,
missing, newly appearing, rehashed, or aliased coordinates reject before
publication; the guarded seven-file integration passes 58 tests. Fresh real
capture remains solely owned by `.17.5.2.4.3`.

Related: [[vial-architecture-scale-proof]], [[vial-common-worker-output-census-admission]],
[[vial-portable-vhdl-runtime-scale]], [[vial-vhdl-osvvm-qualified-tier]].
