---
id: isf-formal-resource-products
title: Potential resource pointer declarations share the executable arbitration producer
answers:
  - "are round robin resource pointer names reserved during formal preparation?"
  - "what does resource_signal_products prove about resource arbitration?"
  - "can a raw formal shadow a round robin pointer before physical renaming?"
date: 2026-10-03
status: current
tags: [isf, formals, reservations, resources, arbitration]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1944-isf-formal-resource-products.t; t/1218-isf-rule-slot-resource-arbitration.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1944-isf-formal-resource-products.t t/1218-isf-rule-slot-resource-arbitration.t
---
Current integration: [production formal scope](isf-production-formal-scope.md) consumes the qualified products. Below is the historical producer boundary; independent-controller/local-call execution remains gated.

Resource arbitration adds round-robin pointers after earlier preparation stages. T1944 derives their absence from production roles. Shared _round_robin_pointer_declaration supplies name/width/role to executable arbitration and potential resource_signal_products; selected kinds with users sort by source resource name. Malformed names use canonical errors.

Inventory is not admission/grant proof. It may return potential declarations despite fixed collisions, unknown/overlapping users or member errors; executable arbitration still refuses them. Priority, unused and unsupported-kind resources add none. Names come from the canonical producer, never fabricated IR or executable bypass.

T1944 compares counters/roles/grant-update targets, independent width boundaries, permutation identities, detachment, raw alias projection, strict carriers and genuine invalid-resource fixtures. Prior native schedule comparison preserves executable grants/metadata. [Namespace qualification](isf-formal-arbitration-namespace.md) observes grants, priority and finalization; only pointers extend the namespace. Historical parent/domain reservation/rewrite closure follows that stage, not this inventory.

Complete resource/context/reason comparisons now reject earlier statement errors and primary-code echoes. [Repair](../audits/formal-resource-cause-repair-20261003/scope.txt) retains exact prior false matches, real bypass failures and conserved whole products. Compile consumers before calls to avoid active eval-source echoes. Finite actor/pointer/schema models qualify; wider internals remain cold-owned.

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.1.
