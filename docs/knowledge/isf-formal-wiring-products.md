---
id: isf-formal-wiring-products
title: Actual local and external activation wiring names join source reservation products
answers:
  - "are external activation ready ports and request states reserved before formal allocation?"
  - "what does parent_wiring_products contain in formal source preparation?"
  - "why can a generated ready port collide with a private direct formal?"
date: 2026-09-27
status: current
tags: [isf, formals, reservations, wiring, domains, activation]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1942-isf-formal-wiring-products.t; t/1387-isf-cross-domain-activation-handshake-lowering.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1942-isf-formal-wiring-products.t t/1387-isf-cross-domain-activation-handshake-lowering.t
---

Transaction and parent activation products precede _wire_do_children and
_wire_external_activations. Actual projected domains add ready/request states,
callee entries and ready ports there. The crossing fixture's caller creates
parent_do_1_ready, parent_do_1_req and worker_start_ready after the old inventory.
The callee creates its external entry and done-ready/request chain. These names
cannot be recovered safely by guessing naming patterns.

prepare_formal_source now retains parent_wiring_products from those actual
routines. It clones retained direct transaction states and activation ports;
generated/pruned transaction bodies stay out. The routines only add/promote
handshake counters, so their additions use a separate map rather than merging
unallocated transaction widths/roles. Both earlier product sets remain detached.
Returned states stop at this wiring boundary and are not executable IR.

T1942 compares real parent and projected-domain products, shows a private formal
main.done_ready can collide with the actual ready port of callee isf_port_main,
and verifies exact/case-folded allocation avoids it. Physical projection preserves
helper and state identities; strict carriers pass. Source-order, mutation,
generated/pruned, raw width conflict, malformed role and fixed-port width controls
retain source isolation and executable admission boundaries.

Point resolution, defaults, priority/resources, child ownership connections and
library/ATL/final domain composition remain outside this product set. Preparing
an already projected domain does not establish complete outer namespace coverage.
No automatic production renaming or controller runtime repair is enabled.
See the [scope contract](isf-direct-transaction-port-scope.md) and book transaction
chapter for the broader boundary. Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.1.
