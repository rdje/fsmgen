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

DirectParameterEmitter uses proved observations and actual namespace/mapping.
Related roots/consumers render natural; equal defaults prove no relation.
Independent literal/vector/negative defaults retain static conversion/normalization.
Membership, case-fold conflicts and dependency order (alphabetical ties) are checked;
lexical scope survives copies. Related root renaming, stale captures, cycles and
unsupported natural relations refuse. Legacy declarations gain no scope.
Actual declarations and independent expectations qualify preparation; caller-made
namespaces attest no provenance. T2154 checks native module/declaration/mapping
coupling and supported/refused controls. Raw conversion stays integer/static;
full external override/runtime/transport checks remain .6.

Paired assignment_analysis/target_declarations qualify captured widths against the
same namespace via DirectDeclaredWidthSupport. Width-only/default-referenced roots
render natural; independent literals/vectors/negative defaults stay static. Missing,
stale, renamed or inconsistent inputs refuse. Omit both for default-only preparation.
Source generation supplies context; remaining computed shapes belong to .3.4.

DirectDeclarationPlan now pairs original emitted SystemVerilog ranges with normalized VHDL ranges
and types, re-proving complete actual source/target declarations before preparing natural generics
against those same target rows. Numeric width/signed/type metadata and lexical scope preserve;
selected width1 retains vector rank. Fixed/type rows gain no invented relationship. Actual
capture/mapping, stale/foreign/collision, caller and isolated owner controls qualify private
preparation. Captures are a caller contract, not text-provenance attestation. The private parser now
checks complete normalized name membership, port/storage roles, exact symbolic source ranges and
selected numeric widths and signedness. It retains separate canonical VHDL type/range strings and
vector rank at width1, preserving complete static parser products and scalar kinds. Altered text
controls reject missing/extra/duplicate/foreign declarations, wrong roles, ranges and numeric
substitutions. Bounded source-aware rendering now consumes this plan; public symbolic raw conversion
still refuses.

Private declaration rendering now consumes canonical vhdl_type. Whole-target decimal and sized
literals use target length, preserving vector rank at default1; unsigned sized literals resize
before target signedness conversion. Selected symbolic literal lvalues and X/Z literals refuse.
T2180 independently expects actual paired target types/literals and preserves static products.
Reverify with `prove -Iperl t/2180-direct-vhdl-target-rank.t
t/2179-direct-vhdl-declaration-parser.t`.

Private symbolic unsigned sized-literal comparisons use numeric unsigned vector overloads,
preserving actual lengths and operand orientation. Decimal equality uses numeric scalar overloads,
and Boolean result literals use the symbolic target length. Static products preserve. Negative
comparisons keep the existing arithmetic refusal; signed symbolic sized comparisons remain withheld.
T2181 qualifies actual paired declarations with independent complete text expectations and
caller-kind controls. Reverify: `prove -Iperl t/2181-direct-vhdl-comparison-rank.t
t/2180-direct-vhdl-target-rank.t`.

Private symbolic Boolean conditions fold whole vectors through the existing OR helper, reserving it
before collision validation. Logical grouping and precedence preserve; negated vector truth tests
zero. Qualified literal comparisons and reductions reuse existing consumers. Selected, bitwise,
vector-pair, decimal-relational and negated-comparison leaves remain withheld. Static condition
products and helper inventory preserve. Actual paired declarations, complete independent Boolean
strings, caller kinds and malformed/helper controls qualify T2182. Reverify: `prove -Iperl
t/2182-direct-vhdl-condition-rank.t t/2181-direct-vhdl-comparison-rank.t`.

Private symbolic assignments resize unsigned sources to actual target length, zero-extending or
truncating low bits before target signedness conversion. Scalars and reductions extend from one bit;
scalar destinations take the low source bit. Selections, signed-vector resizing and computed
expressions refuse before numeric default logic. T2183 checks actual paired ports/storage/registers,
independent whole strings, caller kinds and static/refusal controls. Reverify: `prove -Iperl
t/2183-direct-vhdl-assignment-rank.t t/2180-direct-vhdl-target-rank.t`.

Source generation joins completed collector, analysis and normalized paired plan.
T2184/T2188 check bounded unsigned ranges, target-length transfers/zero resets,
caller kinds and backend reuse. Complete flagged compiler transition families with
fixed state targets are separate from Core data Signal ownership.
Register next/q uses proved parents; scalar whole unsigned reductions use actual AST/event proof
(T2191). Other intermediates/pulses and no-transition shapes refuse (.27). Reverify:
`prove -Iperl t/2188-direct-vhdl-register-helpers.t t/2191*.t`. Raw symbolic text gains no source
authority; full transport/compiler/runtime qualification remains .6. See
t/data/ial0-direct-symbolic-comb.fsm.

Task .27 owns missing no-transition next_state drive: state registers allocate,
but only transitions add that assignment family. Source/loci/unobserved dynamic impact
remain in .27/source-activation audit. Symbolic refuses; fixed behavior is unrepaired.

Fixed scalar/vector logical guards formerly emitted ill-typed `and`. T2193 now
binds actual fixed declarations, whole-vector OR folds, scalar operators and
case-fold helper refusal; signed operands cast first. Scalar/data/comparison
products preserve. The selected native GHDL witness passes; full .6 stays open.
Reverify T2193/T2182/T2191; fixed-vhdl-vector-logic audit retains RED/tool evidence.
