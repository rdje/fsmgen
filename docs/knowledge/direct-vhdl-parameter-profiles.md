---
id: direct-vhdl-parameter-profiles
title: Direct VHDL preparation separates related natural declarations from static defaults
answers:
  - "which direct VHDL generic declarations use natural preparation?"
  - "can a direct VHDL generic used only by captured widths select natural preparation?"
  - "how are normalized target names checked without replacing lexical parameter scope?"
  - "how do private direct VHDL literal assignments retain symbolic vector rank at default one?"
  - "how do private symbolic VHDL comparisons avoid selected-default sizing?"
  - "how do private symbolic VHDL conditions retain whole-vector truth?"
date: 2026-10-27
status: current
tags: [vhdl, parameters, namespaces, lowering]
evidence: perl/FSM/Backend/VHDL/DirectParameterEmitter.pm; perl/FSM/Backend/VHDL/DirectDeclarationPlan.pm; perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; t/2179-direct-vhdl-declaration-parser.t; docs/audits/direct-vhdl-declaration-parser-20261027.json.gz; t/2178-direct-vhdl-declaration-plan.t; docs/audits/direct-vhdl-declaration-plan-20261027.json.gz; t/2177-direct-vhdl-width-generic-roots.t; t/2154-direct-vhdl-generic-integration.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2179-direct-vhdl-declaration-parser.t t/2178-direct-vhdl-declaration-plan.t t/2154-direct-vhdl-generic-integration.t
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
attestation. The private parser now checks complete normalized name membership,
port/storage roles, exact symbolic source ranges and selected numeric widths and
signedness. It retains separate canonical VHDL type/range strings and vector rank
at width1, preserving complete static parser products and scalar kinds. Altered
text controls reject missing/extra/duplicate/foreign declarations, wrong roles,
ranges and numeric substitutions. Renderer activation remains separately owned;
public symbolic raw conversion still refuses.

Private declaration rendering now consumes canonical vhdl_type. Whole-target
decimal and sized literals use target length, preserving vector rank at default1;
unsigned sized literals resize before target signedness conversion. Selected
symbolic literal lvalues and X/Z literals refuse. T2180 independently expects
actual paired target types/literals and preserves static products. Other
expression consumers and public source activation remain pending. Reverify with
`prove -Iperl t/2180-direct-vhdl-target-rank.t t/2179-direct-vhdl-declaration-parser.t`.

Private symbolic unsigned sized-literal comparisons use numeric unsigned
vector overloads, preserving actual lengths and operand orientation. Decimal
equality uses numeric scalar overloads, and Boolean result literals use the
symbolic target length. Static products preserve. Negative comparisons keep
the existing arithmetic refusal; signed symbolic sized comparisons remain
withheld. T2181 qualifies actual paired declarations with independent complete
text expectations and caller-kind controls. Other expression consumers and
source converter activation remain pending; full override/runtime stays owned.
Reverify: `prove -Iperl t/2181-direct-vhdl-comparison-rank.t t/2180-direct-vhdl-target-rank.t`.

Private symbolic Boolean conditions fold whole vectors through the existing OR
helper, reserving it before collision validation. Logical grouping and precedence
preserve; negated vector truth tests zero. Qualified literal comparisons and
reductions reuse existing consumers. Selected, bitwise, vector-pair,
decimal-relational and negated-comparison leaves remain withheld. Static condition
products and helper inventory preserve. Actual paired declarations, complete
independent Boolean strings, caller kinds and malformed/helper controls qualify
T2182. Source activation and remaining assignment/shape consumers stay pending.
Reverify: `prove -Iperl t/2182-direct-vhdl-condition-rank.t t/2181-direct-vhdl-comparison-rank.t`.
