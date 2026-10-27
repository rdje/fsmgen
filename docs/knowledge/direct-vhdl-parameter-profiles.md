---
id: direct-vhdl-parameter-profiles
title: Direct VHDL preparation separates related natural declarations from static defaults
answers:
  - "which direct VHDL generic declarations use natural preparation?"
  - "can a direct VHDL generic used only by captured widths select natural preparation?"
  - "how are normalized target names checked without replacing lexical parameter scope?"
date: 2026-10-27
status: current
tags: [vhdl, parameters, namespaces, lowering]
evidence: perl/FSM/Backend/VHDL/DirectParameterEmitter.pm; perl/FSM/Backend/VHDL/DirectDeclarationPlan.pm; t/2178-direct-vhdl-declaration-plan.t; docs/audits/direct-vhdl-declaration-plan-20261027.json.gz; t/2177-direct-vhdl-width-generic-roots.t; t/2154-direct-vhdl-generic-integration.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2178-direct-vhdl-declaration-plan.t t/2177-direct-vhdl-width-generic-roots.t t/2173-direct-width-target-plans.t
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

Optional paired assignment_analysis/target_declarations now qualify actual
captured widths through DirectDeclaredWidthSupport against the same complete
target namespace. Proved width roots join the existing default-reference subset
before natural rendering. Width-only roots select natural; equal independent
literal/vector/negative defaults stay static. Missing/stale/renamed/inconsistent
inputs refuse. Omitting both inputs preserves the existing default-only profile.
This is private preparation: the direct converter does not yet supply width
context, and symbolic source-aware conversion remains .3.3.4.2/.3.

DirectDeclarationPlan now pairs original emitted SystemVerilog ranges with
normalized VHDL ranges and types, re-proving complete actual source/target
declarations before preparing natural generics against those same target rows.
Numeric width/signed/type metadata and lexical scope preserve; selected width1
retains vector rank. Fixed/type rows gain no invented relationship. Actual
capture/mapping, stale/foreign/collision, caller and isolated owner controls
qualify private preparation. Captures are a caller contract, not text-provenance
attestation. Parser consumption remains .3.3.4.2.2; renderer activation is .3.
