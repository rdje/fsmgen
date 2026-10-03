---
id: isf-formal-reusable-products
title: Reusable library and resolved ATL products share real child construction
answers:
  - "are reusable library and ATL child declarations retained before formal allocation?"
  - "what does reusable_child_products include in source preparation?"
  - "does formal preparation preserve reusable parameters and ATL child data ports?"
date: 2026-10-03
status: current
tags: [isf, formals, reservations, library, atl, children, scope]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1947-isf-formal-reusable-products.t; t/1945-isf-formal-child-products.t; t/1231-isf-library-generated-top.t; t/1330-isf-atl-resolved-child-fixture-coverage.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1947-isf-formal-reusable-products.t t/1945-isf-formal-child-products.t t/1231-isf-library-generated-top.t
---
Current integration: [production formal scope](isf-production-formal-scope.md) consumes preparation products. Independent-controller/local-call execution and the separately owned reusable formal exception remain gated.

_build_module_child_products shares generated children, library uses, resolved ATL actors, selected tops and child data-interface marking between build_module and preparation. Preparation uses a detached actor and separate generated/reusable views. reusable_child_products contains children keyed by module, library_uses and atl_top_instances, excluding generated transaction modules. Parent declaration merging is unnecessary to construct them.

Missing module/shell, cross-kind module collisions and ATL composition admission apply to preparation. External unresolved intent fabricates no module. Parameter/binding/origin/storage/bank/public-port/data-endpoint products remain actual producer outputs; child finalization is independent of the parent. T1947 covers FIFO, trigger/event, vector ingress/egress, actor routes and trigger batches, mixed generated/library scopes, detachment, raw parent conflicts and strict carriers. Its local_delay control avoids an existing public payload pin.

[Diagnosis](../audits/reusable-product-helper-causes-20261003/scope.txt) qualifies actual helper/direct false causes; .2.3.9 owns complete reasons. First-line fragments still accept primary echoes. .2.3.10 owns test Storable projection kind loss; pure copying restores FIFO products. .2.3.11 immediately owns actual ATL caller-width flag changes at _ensure_atl_child_data_source_ports: detached-value controls preserve callers and complete outputs. Original/prepared FIFO JSON stays intact; misleading Storable snapshots remain unqualified. Finite source/clause/mutation/schema/origin/kind models pass; wider constructors/child internals remain cold observations, not whole-kind signoff. Runtime origin coordinates are portable-encoded; moved-root proof remains .1.2.4-owned.

[Grant/priority/finalization](isf-formal-arbitration-namespace.md) and [library readback](isf-library-parent-port-ownership.md) own adjacent boundaries. Historical parent/domain closure is separate; no new HDL runtime claim.
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.1.
