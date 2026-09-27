---
id: isf-formal-reusable-products
title: Reusable library and resolved ATL products share real child construction
answers:
  - "are reusable library and ATL child declarations retained before formal allocation?"
  - "what does reusable_child_products include in source preparation?"
  - "does formal preparation preserve reusable parameters and ATL child data ports?"
date: 2026-09-27
status: current
tags: [isf, formals, reservations, library, atl, children, scope]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1947-isf-formal-reusable-products.t; t/1945-isf-formal-child-products.t; t/1231-isf-library-generated-top.t; t/1330-isf-atl-resolved-child-fixture-coverage.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1947-isf-formal-reusable-products.t t/1945-isf-formal-child-products.t t/1231-isf-library-generated-top.t
---

_build_module_child_products is the unchanged production order for generated
transaction children, library uses, resolved ATL actors, selected ATL top records
and child data-interface marking. Both build_module and prepare_formal_source
use it. Preparation passes a separate actor clone and independently detaches
its generated_child_products and reusable_child_products views. The latter
contains children keyed by module, library_uses and atl_top_instances; it excludes
generated transaction modules. No parent declaration merge or connection is
needed to construct these actual child modules.

Canonical module-conflict checks, missing-shell/module errors and supported ATL
composition admission apply to preparation too. Unresolved external actor intent
fabricates no module. Library parameters, binding metadata, storage/bank logic,
origin, child public ports and selected ATL data endpoints remain actual producer
outputs. Reusable children keep their own semantic finalization. These are child
modules and selected composition records, not an emitted or finalized parent.

T1947 compares complete production products on FIFO, resolved trigger/event,
vector ingress/egress, actor-to-actor data and trigger-batch fixtures. Detached
parent formal rewriting preserves those products and strict child carriers pass.
Mixed generated/library children, source/product isolation, independent raw
parent width conflicts, missing shells/modules, cross-kind module collisions
and unsupported ATL groups retain their real boundaries. The added control
formal uses local_delay because one ATL fixture already has a public payload
pin; its initial payload spelling correctly triggered the existing direct
formal/pin collision refusal.

Parent storage/named-completion/readback connections, grant/priority products
and outer domain namespace realization still require coverage before complete
reservations or automatic production formal renaming. No new HDL runtime
qualification is claimed. Library readback behavior remains owned by
[isf-library-parent-port-ownership](isf-library-parent-port-ownership.md).
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.1.
