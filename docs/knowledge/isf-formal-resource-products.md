---
id: isf-formal-resource-products
title: Potential resource pointer declarations share the executable arbitration producer
answers:
  - "are round robin resource pointer names reserved during formal preparation?"
  - "what does resource_signal_products prove about resource arbitration?"
  - "can a raw formal shadow a round robin pointer before physical renaming?"
date: 2026-09-27
status: current
tags: [isf, formals, reservations, resources, arbitration]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1944-isf-formal-resource-products.t; t/1218-isf-rule-slot-resource-arbitration.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1944-isf-formal-resource-products.t t/1218-isf-rule-slot-resource-arbitration.t
---
Current integration: [production formal scope](isf-production-formal-scope.md)
now consumes the qualified preparation products. The producer-specific account
below records its original qualification boundary; pending global integration
statements are historical. Independent-controller and local-call execution
remain separately gated.


Round-robin pointer declarations appear during resource arbitration, after the
earlier formal-preparation product stages. T1944 derives the actual pointer
from production storage roles and verifies it was absent from that inventory.
The shared _round_robin_pointer_declaration producer now supplies name, width
and storage role to both executable arbitration and resource_signal_products.
The latter contains potential declarations for selected round-robin resource
kinds with users, sorted by source resource name. Malformed pointer-producing
resource names fail through the shared canonical diagnostic.

This is a declaration inventory, not resource admission or a grant model.
Fixed-symbol collisions, unknown/overlapping users and member errors remain
executable arbitration obligations. Collection can return a potential declaration
for such a resource; actual lowering must still reject it. Priority, unused and
unsupported-kind resources add no pointer declaration. No fabricated parent IR
or bypass of executable validation is used to obtain names.

T1944 compares actual counters/roles and grant update targets across supported
resource kinds, tests independent width boundaries, stable source/permutation
identities and detached snapshots, and separates a raw formal/pointer alias
through explicit physical projection. Strict projected carriers and canonical
invalid-resource controls pass. Exact before/after native schedule comparison
retains executable grants and metadata. The subsequent
[arbitration namespace qualification](isf-formal-arbitration-namespace.md)
observes actual grants, priority and finalization stages: only these pointer
declarations extend their declaration namespace. Parent ownership connections
and outer domain composition remain later obligations before complete
reservations or automatic production rewriting can be claimed.

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.1.
