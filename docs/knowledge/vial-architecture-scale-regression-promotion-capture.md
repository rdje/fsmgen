---
id: vial-architecture-scale-regression-promotion-capture
title: VIAL regression promotion captures eleven current profiles through isolated v2 publication
answers:
  - "how will the VIAL architecture scale regression corpus be captured?"
  - "why does the VIAL current promotion corpus use eleven workers instead of 44 workers?"
  - "what does 44 invocations mean in the VIAL regression promotion policy?"
  - "which existing measurement adapters feed the VIAL v2 promotion corpus?"
  - "when will the real VIAL current promotion measurements run?"
  - "how is the VIAL v2 current corpus resumed and published?"
  - "what is the next VIAL architecture scale task after current corpus selection?"
date: 2026-09-02
status: current
tags: [hial, vial, scalability, regression, measurement, publication]
evidence: >-
  docs/decisions/0096-regression-promotion-uses-a-current-eleven-profile-corpus.md;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16df-vial-architecture-scale-cap-closeout.md;
  perl/FSM/VIAL/ArchitectureScaleRegressionPromotionPolicy.pm;
  perl/FSM/VIAL/ArchitectureScaleSemanticBridgeMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScaleBackendEmissionMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScalePortableRuntimeMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScalePortableVHDLRuntimeMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScaleOSVVMRuntimeMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScaleBalancedPortableMeasurement.pm
reverify: >-
  rg -n 'measure_profile|measure_member|validation|measurement_records|regression-promotion-corpus-v1|17[.]5[.]2[.][1-5]|44 common measurement-controller|eleven ordered worker' docs/decisions/0096-regression-promotion-uses-a-current-eleven-profile-corpus.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md docs/book/src/16df-vial-architecture-scale-cap-closeout.md perl/FSM/VIAL/ArchitectureScaleRegressionPromotionPolicy.pm perl/FSM/VIAL/ArchitectureScale{SemanticBridge,ExecutionChecking,BackendEmission,PortableRuntime,PortableVHDLRuntime,OSVVMRuntime,BalancedPortable}Measurement.pm
---

Decision 0096 and the executable promotion policy select eleven current gate
profiles under the non-colliding
`.artifacts/qualification/vial-scale/v2/regression-promotion-corpus-v1/`
publication. The existing broad matrix publishers remain revision-1 historical
authorities and cannot satisfy or publish a v2 current-evidence field.

Every selected measurement adapter already owns the canonical current
producer. Its public measurement entry point performs one validation and, only
after acceptance, three raw measurement-controller calls. “44 invocations”
therefore means 44 common-controller records grouped inside eleven
guard-visible profile-worker lifecycles; it does not require 44 publication
workers.

`.17.5.2.1` derives a closed dispatch plan without executing producers. `.2`
adds isolated per-profile capture and atomic publication. `.3` adds bounded
coordination, exact profile-boundary resume, complete-seal withholding,
fresh-worker reload, and a repository-relative CLI. Default implementation
tests must use bounded injected workers rather than expensive real capture.

Only clean `.17.5.2.3` implementation may feed `.4`, which runs the guarded real
capture at one revision and publishes only after all eleven profiles and all
44 controller records reload with zero exclusions. Any unavailable provider or
current disagreement keeps the complete seal absent and stays owned for root
cause; historical bytes, relaxed validation, and forced acceptance are
forbidden.

`.17.5.2.5` independently reloads and falsifies the complete v2 evidence before
closing the parent. Performance budgets remain unpromoted and belong solely to
`.17.5.3`.

Related: [[vial-architecture-scale-proof]],
[[vial-common-worker-output-census-admission]],
[[vial-portable-vhdl-runtime-scale]], [[vial-vhdl-osvvm-qualified-tier]].
