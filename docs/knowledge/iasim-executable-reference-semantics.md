---
id: iasim-executable-reference-semantics
title: IASIM is a proposed HDL-independent Intent Abstraction runtime with its own native signoff
answers:
  - "what is IASIM?"
  - "should FSMGen simulate Intent Abstraction directly?"
  - "can IASIM replace an HDL simulator?"
  - "how would IASIM combine HIAL and VIAL?"
  - "what should IASIM execute?"
  - "how does IASIM avoid common-mode code generation bugs?"
  - "is IASIM constrained by HDL?"
  - "can IASIM run without generating HDL?"
  - "how can IASIM be signoff accurate?"
  - "what language should implement IASIM?"
  - "is Perl 5 fast enough for IASIM?"
  - "does IASIM need to be rewritten in Rust?"
  - "how may Rust accelerate IASIM?"
date: 2026-08-10
status: current
tags: [hial, vial, iasim, execution-ir, simulator-profile, architecture, task-tree]
evidence: >-
  docs/tasks/IASIM-EXECUTABLE-REFERENCE-SEMANTICS.md;
  docs/decisions/0004-simulate-to-catch-codegen-bugs.md;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/TASK_TREE.md;
  docs/book/src/16d-hial-vial-verification-architecture.md
reverify: >-
  scripts/check_task_tree_integrity.pl &&
  rg -n 'native Intent Abstraction|signoff|direct semantic adapters|HDL-independent|kernel/session|Perl 5|versioned C ABI|shared library|differential equivalence'
  docs/tasks/IASIM-EXECUTABLE-REFERENCE-SEMANTICS.md
  docs/book/src/16d-hial-vial-verification-architecture.md
---

`IASIM-EXECUTABLE-REFERENCE-SEMANTICS` preserves a separate proposed
architecture for an Intent Abstraction Simulator. IASIM is a first-class,
HDL-independent runtime for the native Intent Abstraction world. Direct
IAL2/IAL1/IAL0 semantic adapters feed one canonical execution model and engine;
production tier lowering remains a separately comparable path. IASIM runs the
existing `VIALExecutionIR` against HIAL and produces normalized traces and
results. The intended scheduler seam is VIAL drive, HIAL settle/domain/state
update, then VIAL sample, react, and check. Its values, time, events, and updates
come from explicit Intent Abstraction semantics rather than inherited HDL event
regions or least-common-denominator simulator behavior.

The definition-oriented IASIM reference kernel is Perl 5 first. Perl remains
the semantic orchestrator and authoritative comparison route; representative
xIAL workloads must demonstrate a real bottleneck before optimization. A
measured bounded hotspot may later be implemented in Rust and exposed as a
shared library through a stable versioned C ABI (`Rust -> shared library ->
Perl`). Such an accelerator must define memory ownership plus error and panic
boundaries explicitly and prove deterministic normalized differential
equivalence against the pure-Perl route. No full IASIM rewrite is implied.

IASIM accuracy is qualified natively, without generating HDL: a precise
versioned semantics, a definition-oriented reference interpreter or equivalent
independent oracle, manually derived conformance vectors, property/metamorphic
tests, bounded exhaustive small cases, direct-versus-lowered cross-level
equivalence, deterministic replay, semantic coverage, and mutation/seeded-defect
detection. A passing IASIM result can therefore carry its own exact signoff
claim, while still not proving generated HDL syntax, elaboration, backend
translation, or external simulator scheduling. The proposed first leaf audits
whether the existing HIAL projections can support that native contract or
whether a private execution model is needed. Optional later HDL runs compare
against IASIM to qualify the lowering, PGEN/NEXSIM, or another simulator; they
do not define IASIM correctness.

Related: [[xial-native-development-framework]],
[[hial-vial-verification-fixture-architecture]],
[[vial-execution-ir-v1-contract]].
