---
id: direct-parameter-default-environment
title: Captured direct default environment validation is shared across targets
answers:
  - "where is captured direct parameter source and binding membership validated?"
  - "how do backend name validators preserve captured direct source scope?"
date: 2026-10-27
status: current
tags: [parameters, provenance, scopes, lowering]
evidence: perl/FSM/ParameterDefaultEnvironmentSupport.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm; t/2151-direct-parameter-default-environment.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2151-direct-parameter-default-environment.t t/2147-direct-scalar-default-headers.t t/2149-direct-aggregate-default-headers.t t/2143-direct-scalar-parameter-alias-emission.t
---

ParameterDefaultEnvironmentSupport validates complete normalized declaration,
authored-source and canonical-binding membership under the original direct
source owner. Reference observations remain consistent with actual declared
roots. Declaration order keeps alphabetical ties; empty coherent maps have no
invented scope. Physical module copies retain their lexical source owner.

Target reservation belongs to a transient per-name validator. The Verilog
consumer preserves its original check position and diagnostics; caller JSON
kinds and successful header products remain unchanged. The helper returns the
supplied parameter snapshot as a read-only temporary map, without retaining the
callback. Core getters already detach that snapshot from module ownership.

This validates compiler records without evaluating values, choosing a target
profile, attesting caller-made provenance or changing public schemas. Direct
VHDL namespace/profile preparation and converter integration remain successors.
