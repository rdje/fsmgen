---
id: isf-formal-reusable-products
title: Reusable library and resolved ATL products share real child construction
answers:
  - "are reusable library and ATL child declarations retained before formal allocation?"
  - "what does reusable_child_products include in source preparation?"
  - "does formal preparation preserve reusable parameters and ATL child data ports?"
  - "does ATL output admission preserve caller width kinds?"
date: 2026-10-03
status: current
tags: [isf, formals, reservations, library, atl, children, scope]
evidence: t/2060-isf-reusable-diagnostic-causes.t; t/2059-isf-atl-source-width-kind-preservation.t; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1947-isf-formal-reusable-products.t; t/1945-isf-formal-child-products.t; t/1231-isf-library-generated-top.t; t/1330-isf-atl-resolved-child-fixture-coverage.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl -It/lib t/2060-isf-reusable-diagnostic-causes.t t/2059-isf-atl-source-width-kind-preservation.t t/1947-isf-formal-reusable-products.t t/1945-isf-formal-child-products.t t/1231-isf-library-generated-top.t
---
Current integration: [production formal scope](isf-production-formal-scope.md) consumes preparation products. Independent-controller/local-call execution and the separately owned reusable formal exception remain gated.

_build_module_child_products shares generated children, library uses, resolved ATL actors, selected tops and child data-interface marking between build_module and preparation. Preparation uses a detached actor and separate generated/reusable views. reusable_child_products contains children keyed by module, library_uses and atl_top_instances, excluding generated transaction modules. Parent declaration merging is unnecessary to construct them.

Missing module/shell, cross-kind module collisions and ATL composition admission apply to preparation. External unresolved intent fabricates no module. Parameter/binding/origin/storage/bank/public-port/data-endpoint products remain actual producer outputs; child finalization is independent of the parent. T1947 covers FIFO, trigger/event, vector ingress/egress, actor routes and trigger batches, mixed generated/library scopes, detachment, raw parent conflicts and strict carriers. Its local_delay control avoids an existing public payload pin.

[Cause repair](../audits/reusable-cause-repair-20261003/scope.txt) compares complete declared reasons, rejecting real earlier/primary echoes in helper and direct consumers; exact prior and collision-bypass controls fail. Whole ordinary products conserve; .2.3.10 still owns FIFO test Storable projection kind loss. Original/prepared FIFO JSON stays intact; misleading Storable snapshots remain unqualified. ATL [width repair](../audits/atl-source-width-kind-repair-20261003/scope.txt) detaches the scalar: T2059 preserves callers on acceptance/refusal and complete outputs conserve. Finite source/clause/mutation/schema/origin/kind models pass; wider child internals remain cold-owned. Runtime origins are portable-encoded; moved-root proof remains .1.2.4-owned.

[Grant/priority/finalization](isf-formal-arbitration-namespace.md) and [library readback](isf-library-parent-port-ownership.md) own adjacent boundaries. Historical parent/domain closure is separate; no new HDL runtime claim.
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.1.
