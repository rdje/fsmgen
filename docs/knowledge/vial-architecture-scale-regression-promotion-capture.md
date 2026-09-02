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
  perl/FSM/VIAL/ArchitectureScaleRegressionPromotionPolicy.pm;
  perl/FSM/VIAL/ArchitectureScaleRegressionPromotionCapturePlan.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionProfileStore.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionProfileCapture.pm;
  t/1765-vial-architecture-scale-regression-promotion-policy.t; t/1766-vial-architecture-scale-regression-promotion-capture-plan.t; t/1767-vial-architecture-scale-regression-promotion-profile-store.t; t/1768-vial-architecture-scale-regression-promotion-profile-capture.t
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl t/1766-vial-architecture-scale-regression-promotion-capture-plan.t t/1767-vial-architecture-scale-regression-promotion-profile-store.t t/1768-vial-architecture-scale-regression-promotion-profile-capture.t
---

Decision 0096 selects eleven current gate profiles below the non-colliding v2
corpus. One public adapter call owns validation plus three raw calls, so 44
controller records form eleven guard-visible lifecycles. Revision-1 matrices
remain history and cannot satisfy current evidence.

`.17.5.2.1` authenticates policy order and seals seven adapters, public methods,
arguments, producer/provider prerequisites, counts, and content-addressed v2
paths without producer execution. Structural OSVVM binds read-only repository
materialization; only OSVVM runtime binds qualified GHDL-plus-OSVVM execution.

`.17.5.2.2.1` supplies canonical same-volume publication, bounded identity
reload, and exact recovery. Its provisional 64 MiB limit proves no fit or
capacity; `.17.5.2.2.4` owns two unbounded legacy stores. `.2` forks one ordinal-only
guard-visible child, invokes and revalidates the sealed public adapter, admits
only ordered accepted records with zero exclusions and one clean common
identity, authenticates the provider, then publishes through `.1`. Bounded
canonical metadata crosses IPC; the parent reloads and revalidates exact bytes
and revision. Signals, malformed IPC, foreign providers, mixed identity,
repository mutation, incomplete records, and residue reject. Public-method
doubles cover all routes without creating real capture evidence.
Legacy child `.4.1` separately audits semantic/bridge's direct coordinator loop.

Only clean `.17.5.2.3` may feed guarded real capture in `.4`; unavailable
providers or disagreement keep the complete seal absent. `.5` independently
reloads and falsifies v2 evidence. Historical substitution, forced acceptance,
and budget promotion remain forbidden; budgets belong solely to `.17.5.3`.

Related: [[vial-architecture-scale-proof]], [[vial-common-worker-output-census-admission]],
[[vial-portable-vhdl-runtime-scale]], [[vial-vhdl-osvvm-qualified-tier]].
