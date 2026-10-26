---
id: isf-authored-scalar-width-provenance
title: Scalar width declarations retain authored provenance
answers:
  - "where do authored ISF scalar width dependencies disappear?"
  - "how will private ISF width declarations distinguish equal defaults?"
  - "why cannot an ISF width parameter be copied blindly into IAL0 size syntax?"
  - "where are authored bank depth and watchdog parameter references lost?"
  - "which scopes must generated child width declarations preserve?"
  - "where is library parameter override source provenance lost?"
  - "why is library source preservation blocked on nested aggregate normalization?"
  - "where does IAL0 retain authored scalar width expressions?"
  - "where are original transaction parameter defaults retained for width binding?"
  - "where are canonical parameter default reference bindings retained?"
date: 2026-10-26
status: current
tags: [isf, width, parameters, lowering, provenance, formal]
evidence: perl/FSM/Support/ISFWidthBindings.pm; docs/audits/domain-width-ir-20261025.json.gz; docs/audits/reusable-width-ir-20261025.json.gz; docs/audits/width-generated-port-controls-20261022.json.gz; docs/audits/width-carrier-contract-first-20261022.json.gz; docs/audits/width-static-use-controls-20261022.json.gz; docs/audits/width-carrier-contract-verify-20261022.py; docs/audits/scalar-width-foundation-20261022.json.gz; docs/audits/scalar-width-foundation-20261022.txt; docs/audits/scalar-width-foundation-verify-20261022.py; docs/tasks/ISF-REDUCTION-DELIVERY.md; docs/audits/scalar-width-declarations-qualification-20261022.json.gz; docs/audits/scalar-width-declarations-native-20261022.json.gz; t/2094-isf-authored-width-declarations.t; perl/FSM/Adapter/ISF/Parser.pm
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/211[0-7]-*.t t/50-language-contract-size-section-boundary.t t/2108-isf-width-parameter-default-sources.t t/2109-isf-width-default-bindings.t t/2101-isf-generated-width-ir.t t/2100-isf-direct-formal-width-ir.t t/2107-isf-reusable-width-ir.t && python3 -B docs/audits/generated-width-ir-20261023.py verify && python3 -B docs/audits/formal-width-ir-20261023.py verify && python3 -B docs/audits/width-ir-qualification-20261023.py verify && python3 -B docs/audits/width-physical-verify-20261022.py && python3 -B docs/audits/library-override-diagnosis-verify-20261022.py && python3 -B docs/audits/library-source-retention-20261022.py verify && python3 -B docs/audits/library-source-qualification-20261022.py verify
---
# 0119 — Scalar width declarations retain authored provenance

- Type: private declaration and lowering contract
- Status: private source/IR and scoped target/instance plans have focused checks; carrier/HDL/public qualification pending
- Owner: `ISF-REDUCTION-DELIVERY.2.1`

## Context

Decision 0117 requires authored width dependencies to survive independently of
resolved defaults. The source-only audit locates their first loss in ISF parser
width finalizers. Parameter, alias, distinct equal-default parameter and constant
references become numbers. LoweringIR projects those numbers, then IAL0 emits
them. Named types already retain their own reference/specification. A transaction
parameter-use set does not associate each port with its source token.

Library use-site overrides reach tops while child shapes retain defaults: existing specialization backlog.
Derived actor-parameter arithmetic remains refused. Composition currently resolves overrides from static top/package symbols;
top +params and sibling parameter references refuse. Required generic forwarding needs top declarations and typed bindings.
Audit/native/private products cannot qualify generic HDL. Evidence: `docs/audits/width-forwarding-contract-20261026.json.gz`; reverify with `python3 -B docs/audits/width-forwarding-contract-verify-20261026.py`.

## Decision

Capture a private `_width_declaration` at the existing successful parser width
resolution branch. Preserve its original token, source kind and lexical owner;
keep the resolved number in the existing `width` field. Distinguish actor
parameters, actor constants, package constants and transaction parameters from
their actual resolution branch, preserving local shadowing and authored aliases.
Do not infer dependencies from equal numbers. Explicit literals and implicit
one-bit declarations do not acquire parameter provenance. Named types retain
their existing separate representation. Detach token data before inspection.

Reuse existing static/alias resolution. Derived arithmetic must share public
IAL0 integer-expression semantics while retaining the ISF contract's earlier-
declaration requirement; do not introduce an independent evaluator. IAL0's
acyclic out-of-order parameter graph is not permission to widen ISF ordering.

Qualify parser preservation first, then physical preparation/IR/carrier
associations, then detached successful native/API/newline MCP reports and
schema applicability. Public numbers describe the selected environment.
Generic HDL, re-specialization, reset/constant sizing and external legality
retain separate required owners under `.3`, `.4` and SEM `.32.3`.

## Consequences and evidence

Initial preservation changes no admission, carrier or public schema. Each
propagation boundary needs independent declaration oracles and caller/result
isolation; transport agreement cannot establish provenance. Literal scope/carrier
oracles and hostile associations qualify only the observed baseline. The audit
records exact Git source joins, producer/receipt/verifier and missing footprint,
raw-stream, HDL and API legs. Required reductions and publication stay open.

This bounded record owns the new fact/question without growing the rollover-
debt Knowledge Map card collection or the saturated decision 0117. Both original
records remain byte-exact; no previous question or fact is removed.

## Private parser preservation

Leaf `.2.2` captures symbolic actor interface/storage and transaction-port
declarations at their successful existing resolution branches. Parameters,
constants and package constants retain distinct kinds; local transaction
parameters retain their transaction owner, and library clones retain the source
export owner. Literal/default widths and named types gain no invented parameter
dependency. Aliases keep their authored token, with numeric defaults unchanged.

The fixed regression fails on the observed predecessor and passes currently:
package/constant storage, transaction shadows and detached library clones.
Complete native check/semantic/schedule and carrier bytes match the baseline
with only fixture-directory normalization; parsed actors differ solely by
independently expected private records. Saved audit readers in `docs/audits/`:
`scalar-width-foundation-verify-20261022.py` (historical) and
`scalar-width-declarations-verify-20261022.py` (current). Public inventory,
carrier propagation and generic HDL remain open.

## Carrier namespace and static-use prerequisites

The source-only `.2.3.1.1` audit gives type `word_t` width eight and same-named parameter sixteen: ISF chooses the parameter, bare IAL0 `+size` the type, and `(+ word_t 0)` the scalar. Preserve namespace and expression; numeric default checks establish neither generic HDL nor override legality.
Core Signals retain detached `{signal, expression, resolved_width}` via `declared_width_source`, without classifying dependencies or changing default HDL/public reports. Scalar width lookup checks constants before params; parameter aliases use their parameter graph; constants cannot reference params. Scoped binding/emission remain pending.
Historical `.2.3.3.3.2.2.2.1` controls give constant/define aliases width eight, ordinary parameter alias sixteen and enum-to-constant alias eight, with `(param W)` refused then. Leaf `.2.3.3.3.2.2.2.3` now admits `(param NAME)` only in direct +size expressions, via detached declared-parameter payloads and the existing integer evaluator. Type/constant/parameter W controls select four/eight/sixteen; malformed, missing, aggregate and non-positive cases refuse. No independent alias knob or generic HDL propagation is added.
With W=16, BOUND=W and BOUND=16 keep identical normalized Core parameter records and distinct raw ASTs. ParameterValueSupport normalizes the reference, Parser stores that value, and native SV still prints BOUND=16. The new detached parameter_default_sources() map separately retains source module, declaration, original expression and ordered direct parameter references observed at the actual resolver branches, including member/index suffixes.
Leaf `.2.3.3.3.2.2.2.2` preserves authored defaults before canonicalization, isolates callers/getters/copies and clears stale source on replacement; programmatic values gain none. Constants/enums retain expressions without invented parameter references; aliases retain direct rather than expanded transitive references. ParameterDeclarationSupport now shares the canonical graph, preserves products/order/source isolation and releases parser contexts on success/refusal. The separate symbol-context defect is P1 `.19` before publication; top/HDL propagation remains pending.
Re-derive/falsify from `docs/audits/width-scalar-namespace-contract-20261026.json.gz` and `docs/audits/ial0-parameter-default-sources-20261026.json.gz`: actual source/native/Core controls, selected Git joins, corrected fixed predecessor RED/current GREEN and hostile identity controls. Tasks/book/fact/Git retain durability; only the native header Date is normalized for selected HDL comparison. The selector packet `docs/audits/ial0-parameter-width-selection-20261026.json.gz` adds fixed RED/GREEN, native source/ranges/refusal/discovery and immutable-source controls. Full footprint, generic runtime and other profiles are unclaimed.

At parameter default two, changing only bank `(depth 2)` to `(depth W)`, or only
`(watchdog 2)` to `(watchdog W)`, yields exactly identical complete parsed actors,
selected IR and carrier files with the same explicit source label. Storage-depth
and watchdog finalizers overwrite the references without retaining raw source.
Keep their primitive kinds and numeric defaults while preserving original
token/kind/lexical owner before generic emission. Mandatory successor `.2.3.2.1`
owns this and the remaining static-use census; `.2.3.3` owns unambiguous IAL0
expression preservation. Existing default-only behavior remains correct.

Reverify these retained observations with
`python3 -B docs/audits/width-carrier-contract-verify-20261022.py`. It reads the
first namespace/static-use and independent single-slot control receipts, joins
selected source hashes to Git, and rejects hostile width/kind/equality products.
No HDL tools, API/MCP qualification or full IR capture is claimed.

## Physical associations and selected private IR contract

The `.2.3.1.2` audit captures actual source preparations, formal plans, physical
actors, full module IR, domain realizations and carriers. Formal plan declarations
and projected source ports retain width records; module port/storage projections
discard them. Domain clones preserve lexical owners while renaming module actors.
Library and resolved ATL clones likewise retain exported source owners before
their IR projections. The known reusable-formal refusal remains separately owned.

Connected generated controls use an actor alias of W=8 for one formal and local
transaction W=4 for another. Child module parameters currently contain local W=4;
copying the actor-derived token into that module without its environment would
lose or change its meaning. Activation clauses retain original override values
beside separately resolved instance products. The audit observed library uses
losing original values in `_validate_use_params`: named LIMIT and literal16 gave
identical complete private products. `.2.3.2.1.2.3` now retains detached ordered
name/value/lexical-owner source lists before resolution; selected alias/nested/default native/API/newline reports conserve old products. Specialization stays `.4`.

Actor module IR now owns detached `_width_declarations` keyed by actual ports
and storage signals, with declaration identity, token/kind/owner and lexical
scope. Bank indices are explicit; no equal-width or generated-name inference.
`_width_scopes` retain actor/transaction authored/resolved environments. `module_parameters` selects the constructor owner independently of equal lists or physical names. Ordered `parameter_default_sources` retain original transaction tokens; `parameter_default_bindings` records canonical branch kinds. `_width_bindings` retains width/default identities, real parameters, immutable locals, nested lists and deduplicated width/default actor captures; constants/packages/enums/literals stay distinct. `_width_symbols` maps IAL0 trees, deterministic contexts and immutable aliases from selected static caches, reserving final declarations/executable tokens and state/enable names with case folding. No new evaluator/output change; emitted forwarding/carriers/HDL/public qualification pending.
`_width_static_uses` separately snapshots watchdog/depth and selected library sources. Bound-expression/default evidence: `docs/audits/isf-width-binding-expressions-20261026.json.gz` and `docs/audits/isf-width-default-expressions-20261026.json.gz` and `docs/audits/isf-width-symbol-plans-20261026.json.gz` and `docs/audits/isf-width-context-forwarding-20261026.json.gz` and `docs/audits/isf-domain-width-forwarding-20261026.json.gz`.
Parser source actor identity
survives module renaming; historical origin oracles add exact source-name/literal-use metadata and rebind full actor digests. Each module owns detached maps; instance overrides
remain separate from source defaults. Literal/type/reset declarations stay
exact. Direct formals retain original names, plan identities and isolated lexical scopes. Generated formal/inherited/storage-read ports retain actor and selected transaction sources.
Final ports own membership; auxiliary widths can retain removed inputs. Parent banks/library instances stay parent owned. Reusable children and spawn/do/rule instances separate defaults, selections, raw aliases and original overrides. Domain ownership has focused checks; IAL0/public qualification remains. Private `_width_forwarding` joins actual normal instances to declared producer parameters or explicit imported contexts by source identity, retaining selected environments separately. Domain realization applies final allocated producer-instance and child-instance/module names, preserving parent definitions, lexical scopes, slots and selections. Carrier/HDL emission and public qualification remain pending.
Nested heads now normalize recursively under `.2.3.2.1.2.2`; original diagnosis: `docs/audits/library-override-diagnosis-verify-20261022.py`.

`python3 -B docs/audits/width-physical-verify-20261022.py` checks the retained
packets, scope/physical identities and hostile allocation/kind controls. Initial
unconnected-output and malformed await-list refusals are retained, not promoted
to successful native cases. First-touch JSON observations supersede lossy audit
Storable copies; their explicit copy counterfactual preserves originals while
changing numeric kinds. This does not assert a production copier defect. Native
and private audit products establish neither generic HDL nor runtime behavior.

## Private static-source preservation

Leaf `.2.3.2.1.1` captures detached `_depth_declaration` on symbolic banks and
`_watchdog_declaration` on symbolic actor watchdogs at successful existing
resolution branches: authored `token`, source `kind` and lexical `owner`.
Aliases and package owners remain distinct from equal defaults. Literal/implicit
values gain no dependency; resolved primitives, carriers and public defaults
remain unchanged. This does not implement generic shapes or public inventories.
The task owns the parser-finalizer census and complete qualification evidence;
library source lists now persist privately; scoped IR/IAL0 propagation remains.
Reverify retained original/current products and hostile association controls:
`python3 -B docs/audits/static-references-20261022.py verify`.
