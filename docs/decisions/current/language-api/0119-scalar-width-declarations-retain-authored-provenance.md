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
date: 2026-10-22
status: current
tags: [isf, width, parameters, lowering, provenance]
evidence: docs/audits/width-physical-verify-20261022.py; docs/audits/width-generated-port-controls-20261022.json.gz; docs/audits/width-carrier-contract-first-20261022.json.gz; docs/audits/width-static-use-controls-20261022.json.gz; docs/audits/width-carrier-contract-verify-20261022.py; docs/audits/scalar-width-foundation-20261022.json.gz; docs/audits/scalar-width-foundation-20261022.txt; docs/audits/scalar-width-foundation-verify-20261022.py; docs/tasks/ISF-REDUCTION-DELIVERY.md; docs/audits/scalar-width-declarations-qualification-20261022.json.gz; docs/audits/scalar-width-declarations-native-20261022.json.gz; t/2094-isf-authored-width-declarations.t; perl/FSM/Adapter/ISF/Parser.pm
reverify: python3 -B docs/audits/width-physical-verify-20261022.py && python3 -B docs/audits/library-override-diagnosis-verify-20261022.py
---
# 0119 — Scalar width declarations retain authored provenance

- Type: private declaration and lowering contract
- Status: private parser preservation qualified; carrier/public propagation pending
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

The initial slice changes no source admission, carrier or public report schema.
Every later propagation boundary needs an independent declaration oracle and
caller/result isolation; transport agreement alone cannot establish provenance.
The audit's literal source/scope/carrier oracles and hostile association records
qualify its observed baseline, not future implementation. Exact selected Git
source joins, tracked producer/receipt/verifier and missing footprint/raw-stream/
HDL/API legs are recorded in the companion audit. Required reductions and
publication remain open until their actual behavior is qualified.

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

The unchanged strengthened regression fails through an exactly observed
predecessor parser and passes currently, including package/constant storage,
transaction shadows and detached library clones. Complete native check/semantic/
schedule products and carrier bytes match the committed baseline after only
fixture-directory normalization. The parsed actors differ solely by the exact
independently expected private records. Historical audit qualification remains
available through `scalar-width-foundation-verify-20261022.py`; current retained
products are checked by `scalar-width-declarations-verify-20261022.py` in
`docs/audits/`. Public inventory, carrier propagation and generic HDL remain open.

## Carrier namespace and static-use prerequisites

The source-only `.2.3.1.1` audit supplies a type `word_t` of width eight and a
same-named parameter sixteen. ISF selects the parameter; bare IAL0 `+size`
selects the type. IAL0 `(+ word_t 0)` selects the scalar parameter through the
existing integer evaluator. Preserve the chosen namespace and expression, not
just token spelling: current IAL0 still resolves that expression numerically.
This default check establishes neither generic HDL nor override legality.

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
beside separately resolved instance products. Library use overrides differ:
`_validate_use_params` overwrites original values before cloning. A named LIMIT
and literal16 produce identical complete private products. Mandatory
`.2.3.2.1.2` preserves that source before resolution; specialization stays `.4`.

Select a detached private IR map `_width_declarations` keyed by actual physical
signal, with original declaration identity, token/kind/owner and explicit lexical
scope. Use actual formal marks/plans, local-port precedence and bank element
indices, never equal widths or generated-name guesses. Keep scoped canonical
parameter/constant declarations in `_width_scopes`, separating actor and
transaction environments; retain static-use sources separately. Source clones
must carry original actor identity before module/domain renaming. Each physical
module owns detached maps; library instance selection remains separate from
source defaults. Literal/type/reset declarations and existing public/carrier
projections stay exact. Later IAL0 allocation uses those explicit scopes.
Nested aggregate heads also remain mis-normalized; `.2.3.2.1.2.2` owns the prerequisite repair, qualified in `docs/audits/library-override-diagnosis-verify-20261022.py`.

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
library-source preservation remains `.2.3.2.1.2`, followed by scoped IR/IAL0 work.
Reverify retained original/current products and hostile association controls:
`python3 -B docs/audits/static-references-20261022.py verify`.
