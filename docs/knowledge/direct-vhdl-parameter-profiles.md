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
  - "how do private symbolic VHDL assignments preserve unsigned sizing?"
  - "which direct VHDL symbolic source shapes now generate through the CLI?"
  - "why did fixed VHDL vector guards fail analysis?"
  - "why does source-aware symbolic VHDL require a captured transition?"
  - "which task owns the direct no-transition state-hold repair?"
date: 2026-10-28
status: current
tags: [vhdl, parameters, namespaces, lowering]
evidence: perl/FSM/Backend/VHDL/DirectParameterEmitter.pm; perl/FSM/Backend/VHDL/DirectDeclarationPlan.pm; perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; t/2179-direct-vhdl-declaration-parser.t; docs/audits/direct-vhdl-declaration-parser-20261027.json.gz; t/2178-direct-vhdl-declaration-plan.t; docs/audits/direct-vhdl-declaration-plan-20261027.json.gz; t/2177-direct-vhdl-width-generic-roots.t; t/2154-direct-vhdl-generic-integration.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2184-direct-vhdl-symbolic-source.t t/2179-direct-vhdl-declaration-parser.t t/2154-direct-vhdl-generic-integration.t
---

DirectParameterEmitter checks actual namespace/mapping and proved observations.
Related roots/consumers render natural; equal defaults prove no relation. Independent
literal/vector/negative defaults stay static/normalized. Membership, case-fold conflicts,
dependency order (alphabetical ties) and copied lexical scope qualify. Root renaming,
stale captures, cycles and unsupported natural relations refuse; legacy gains no scope.
Caller namespaces attest no provenance. T2154 checks actual declarations/mappings with
independent supported/refused controls. Raw stays integer/static; full external .6 remains.

Paired assignment_analysis/target_declarations qualify captured widths in that namespace
via DirectDeclaredWidthSupport. Width-only/default-referenced roots render natural;
independent defaults stay static. Missing/stale/renamed/inconsistent inputs refuse.
Omit both for default-only preparation; source supplies context, computed shapes .3.4.

DirectDeclarationPlan pairs exact emitted SV ranges and normalized VHDL ranges/types,
re-proving complete actual declarations before natural generic preparation. Numeric
width/signed/type and lexical scope preserve; width1 keeps vector rank, fixed/type rows
invent no relation. T2178/T2179 check actual capture/mapping and stale/foreign/collision/
caller/isolated-owner controls. Plans are caller contracts, not provenance attestation.
Parser checks complete normalized membership, roles, exact symbolic spelling, selected
width/signedness; separate VHDL type/range strings preserve all static/JSON products.
Missing/extra/duplicate/foreign/role/range/numeric substitutions refuse. Source consumes
the plan; raw symbolic text still refuses. The VHDL module POD owns detailed consumers.

T2180 target-rank: canonical vhdl_type drives whole-target decimal/sized literals via
target length, retaining width1 rank. Unsigned sized literals resize before target
signedness; selected lvalues and X/Z refuse. Independent exact declarations/literals,
caller kinds and static products qualify. Reverify T2180/T2179.
T2181 comparisons: unsigned vector/sized-literal numeric overloads preserve lengths and
orientation. Decimal equality uses scalar numeric overloads; Boolean literals use target
length. Negative arithmetic/signed symbolic sized profiles refuse; static products
preserve. Actual paired declarations/exact strings/caller kinds qualify; reverify T2181/T2180.
T2182 conditions: whole-vector OR helper reserves before collision checking. Grouping,
precedence and negation preserve; negated vector truth tests zero. Qualified literal
comparisons/reductions share consumers. Selected/bitwise/vector-pair/decimal-relational/
negated-comparison leaves withhold. Static products/helper inventory, actual plans,
exact strings/caller kinds/malformed/helper controls qualify; reverify T2182/T2181.
T2183 assignments: unsigned whole sources resize to target length, zero-extending or
truncating low bits before signedness. Scalars/reductions extend from one bit; scalar
destinations take the low source bit. Selected operands/lvalues, signed-vector resizing
and computed expressions refuse before default sizing. Actual ports/storage/registers,
exact strings/caller kinds/static/refusal controls qualify; reverify T2183/T2180.
Run named regression files under scripts/run_with_ram_guard.sh -- prove -Iperl.

Source generation joins completed collector, analysis and normalized paired plan.
T2184/T2188 check bounded unsigned ranges, target-length transfers/zero resets, caller
kinds and reuse. Flagged complete compiler transitions with fixed state targets are
separate from Core Signal ownership. Next/q uses proved parents; scalar whole unsigned
reductions use actual AST/event proof (T2191). Other intermediates/pulses/no-transition
shapes refuse (.27). Reverify `prove -Iperl t/2188-direct-vhdl-register-helpers.t
t/2191*.t`. Raw text gains no source authority; full transport/compiler/runtime stays .6.
Example: t/data/ial0-direct-symbolic-comb.fsm.

Task .27 owns missing no-transition next_state drive: registers allocate, but only
transitions add that family. Source/loci/unobserved dynamic impact retain in
.27/source-activation audit. Symbolic refuses; fixed behavior is unrepaired.
Fixed scalar/vector logical guards formerly emitted ill-typed and. T2193 binds actual
fixed declarations, whole-vector OR folds, scalar operators and case-fold helper
refusal; signed operands cast first. Scalar/data/comparison products preserve. Selected
native GHDL witness passes; full .6 stays open. Reverify T2193/T2182/T2191;
fixed-vhdl-vector-logic audit retains RED/tool evidence.

Retained consumer reverify recipes:
`prove -Iperl t/2180-direct-vhdl-target-rank.t
t/2179-direct-vhdl-declaration-parser.t`.
`prove -Iperl t/2181-direct-vhdl-comparison-rank.t
t/2180-direct-vhdl-target-rank.t`.
`prove -Iperl
t/2182-direct-vhdl-condition-rank.t t/2181-direct-vhdl-comparison-rank.t`.
`prove -Iperl
t/2183-direct-vhdl-assignment-rank.t t/2180-direct-vhdl-target-rank.t`.
`prove -Iperl t/2188-direct-vhdl-register-helpers.t t/2191*.t`.
