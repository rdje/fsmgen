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
date: 2026-10-25
status: current
tags: [isf, width, parameters, lowering, provenance, formal]
evidence: t/2100-isf-direct-formal-width-ir.t; docs/audits/domain-width-ir-20261025.json.gz; docs/audits/reusable-width-ir-20261025.json.gz; docs/audits/width-generated-port-controls-20261022.json.gz; docs/audits/width-carrier-contract-first-20261022.json.gz; docs/audits/width-static-use-controls-20261022.json.gz; docs/audits/width-carrier-contract-verify-20261022.py; docs/audits/scalar-width-foundation-20261022.json.gz; docs/audits/scalar-width-foundation-20261022.txt; docs/audits/scalar-width-foundation-verify-20261022.py; docs/tasks/ISF-REDUCTION-DELIVERY.md; docs/audits/scalar-width-declarations-qualification-20261022.json.gz; docs/audits/scalar-width-declarations-native-20261022.json.gz; t/2094-isf-authored-width-declarations.t; perl/FSM/Adapter/ISF/Parser.pm
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/50-language-contract-size-section-boundary.t t/2108-isf-width-parameter-default-sources.t t/2101-isf-generated-width-ir.t t/2100-isf-direct-formal-width-ir.t t/2107-isf-reusable-width-ir.t && python3 -B docs/audits/generated-width-ir-20261023.py verify && python3 -B docs/audits/formal-width-ir-20261023.py verify && python3 -B docs/audits/width-ir-qualification-20261023.py verify && python3 -B docs/audits/width-physical-verify-20261022.py && python3 -B docs/audits/library-override-diagnosis-verify-20261022.py && python3 -B docs/audits/library-source-retention-20261022.py verify && python3 -B docs/audits/library-source-qualification-20261022.py verify
---
# 0119 — Scalar width declarations retain authored provenance

- Type: private declaration and lowering contract
- Status: private parser and actor/direct-formal/generated IR preservation qualified; carrier/public propagation pending
- Owner: `ISF-REDUCTION-DELIVERY.2.1`

## Context

Decision 0117 requires authored width dependencies to survive independently of
resolved defaults. The source-only audit locates their first loss in ISF parser
width finalizers. Parameter, alias, distinct equal-default parameter and constant
references become numbers. LoweringIR projects those numbers, then IAL0 emits
them. Named types already retain their own reference/specification. A transaction
parameter-use set does not associate each port with its source token.

Actual library use-site overrides remain in generated tops while child shapes
keep their defaults. This is the existing specialization backlog, not a newly
qualified implementation. Derived arithmetic remains refused at actor parameter
admission. Audit/native/private products alone cannot establish generic HDL.

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

The source-only `.2.3.1.1` audit supplies a type `word_t` of width eight and a
same-named parameter sixteen. ISF selects the parameter; bare IAL0 `+size`
selects the type. IAL0 `(+ word_t 0)` selects the scalar parameter through the
existing integer evaluator. Preserve the chosen namespace and expression, not
just token spelling: current IAL0 still resolves that expression numerically.
This default check establishes neither generic HDL nor override legality. Core Signals retain `{signal, expression, resolved_width}` through the detached `declared_width_source` accessor; it preserves scalar expression source without classifying parameter dependencies or changing default HDL/public reports. IAL0 scalar lookup checks constants before params, while parameter aliases resolve in their parameter graph; constants cannot reference params. Scoped binding and carrier emission remain pending.

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
Canonical `_width_scopes` separate actor and transaction environments, including authored aliases and resolved values; `module_parameters` explicitly identifies the actual constructor parameter owner independently of equal lists or physical module renames. `parameter_default_sources` retains original ordered transaction default tokens beside the intentionally literalized canonical environment; binding and emission remain pending.
`_width_static_uses` separately snapshots
watchdog/depth and selected library sources. Parser source actor identity
survives module renaming; historical origin oracles add exact source-name/literal-use metadata and rebind full actor digests. Each module owns detached maps; instance overrides
remain separate from source defaults. Literal/type/reset declarations stay
exact. Direct formals retain original names, plan identities and isolated lexical scopes. Generated formal/inherited/storage-read ports retain actor and selected transaction sources.
Final ports own membership; auxiliary widths can retain removed inputs. Parent banks/library instances stay parent owned. Reusable children and spawn/do/rule instances separate defaults, selections, raw aliases and original overrides. Domain ownership has focused checks; IAL0/public qualification remains.
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
