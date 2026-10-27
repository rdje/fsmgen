---
id: direct-vhdl-parameter-profiles
title: Direct VHDL preparation separates related natural declarations from static defaults
answers:
  - "which direct VHDL generic declarations use natural preparation?"
  - "how are normalized target names checked without replacing lexical parameter scope?"
date: 2026-10-27
status: current
tags: [vhdl, parameters, namespaces, lowering]
evidence: perl/FSM/Backend/VHDL/DirectParameterEmitter.pm; t/2153-direct-vhdl-parameter-profiles.t; t/2154-direct-vhdl-generic-integration.t; perl/FSM/ParameterDefaultEnvironmentSupport.pm
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2153-direct-vhdl-parameter-profiles.t t/2152-direct-binding-observation-proof.t t/2150-shared-vhdl-parameter-binding-renderer.t
---

DirectParameterEmitter prepares declarations from proved source observations
and an explicit actual target namespace/identifier mapping. Related consumers
and their referenced roots use the existing natural renderer. Equal numeric
defaults create no relationships; independent literal/vector/negative defaults
retain the static converter path and generated identifier normalization.

The plan checks emitted membership and case-insensitive namespace conflicts,
preserves dependency order with alphabetical ties and retains lexical source
scope across physical module copies. Related parameter renaming, stale
captures, cycles and unsupported natural relationships refuse. Legacy
programmatic declarations acquire no invented scope.

Actual normalized backend declarations and independent plan expectations
qualify private preparation. Caller-made namespace records are not provenance
attestation. The direct backend now consumes this plan with its actual normalized
module/declarations/mapping; standalone raw conversion retains its existing
integer/static behavior. T2154 and native supported/refused controls qualify
that coupling. Full external override/runtime/transport checks remain .6.
