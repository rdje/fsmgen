---
id: direct-binding-reference-proof
title: Complete canonical binding observations precede direct profile selection
answers:
  - "how is an empty direct parameter reference inventory checked for completeness?"
  - "which helper refuses dropped observations without borrowing static values?"
date: 2026-10-27
status: current
tags: [parameters, binding, provenance, scopes]
evidence: perl/FSM/ParameterDefaultEnvironmentSupport.pm; perl/FSM/ParameterBindingSupport.pm; t/2152-direct-binding-observation-proof.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2152-direct-binding-observation-proof.t t/2151-direct-parameter-default-environment.t t/2147-direct-scalar-default-headers.t
---

The opt-in `prove_binding_observations` method adapts canonical binding nodes
to the existing binder's observed-expression contract and requires complete
rebound snapshot equality, including JSON kinds and immediate identities.
Declared roots cannot borrow frozen static values after an observation is
dropped. Repeated references retain order, and same-token static snapshots
must agree across the captured scope.

Unknown, foreign, cyclic or opaque expression records refuse before a profile
can rely on an empty inventory. Actual scalar/aggregate and imported records
retain caller JSON kinds. The proof returns detached observations and a plain
zero/one dependency indicator alongside the existing temporary environment.

This proves the binding/observation contract; it does not authenticate jointly
forged caller records or select a target profile. Existing headers remain on
their current validator. Direct VHDL namespace/profile preparation and converter
activation are separately owned successors; full qualification remains .6.
