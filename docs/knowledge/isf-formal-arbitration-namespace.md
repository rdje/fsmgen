---
id: isf-formal-arbitration-namespace
title: Resource priority and finalization reuse the retained declaration namespace
answers:
  - "do rule grants and priority create additional formal reservation names?"
  - "does parent IR finalization add declarations before child storage connections?"
  - "what qualifies the resource priority namespace boundary?"
date: 2026-09-27
status: current
tags: [isf, formals, reservations, resources, priority, finalization]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1948-isf-formal-arbitration-namespace.t; t/1944-isf-formal-resource-products.t; t/1218-isf-rule-slot-resource-arbitration.t; t/1220-isf-arbitration-schedule-report.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1948-isf-formal-arbitration-namespace.t t/1944-isf-formal-resource-products.t t/1218-isf-rule-slot-resource-arbitration.t t/1220-isf-arbitration-schedule-report.t
---

Actual _apply_rule_user_resource_arbitration adds round-robin pointer counters
through the shared declaration producer already retained as
resource_signal_products. Priority grants and assignment-priority resolution
rewrite guards using existing signal operands and state_active state identities;
they do not allocate additional declaration names. _finalize_ir derives
assignment provenance, compatible fan-in and conflict issues, then applies its
canonical conflict refusal. It does not extend the declaration namespace.

T1948 observes before/after declaration names around the real production
resource, rule/rule priority, rule/transaction priority and finalization calls.
Its wrappers delegate to each original function; no raw preparation maps are
merged into a fabricated parent. It checks stage order, exact declaration
additions/removals, coverage by authored/prepared products and preservation
after detached formal projection. It exercises supported resource kinds with
priority and round-robin arbiters, direct assignment priority in both directions,
unique named-drive priority in both directions, state_active guards and strict
carrier replay. Actual grant and resolution records prevent vacuous passes.

A native round-robin schedule confirms that whole-rule resource grants can
coexist with target-local assignment-priority records. The initial test assumed
those records would vanish; that expectation was corrected without changing
production. Compatible transaction-trigger pulses retain their separate path.
Potential pointer collection still does not establish valid users or symbols:
unknown users and fixed pointer collisions fail in actual arbitration, and
incomparable data writers fail during actual finalization.

This qualifies a declaration boundary, not a complete executable reservation
set, new runtime behavior or production formal renaming. Potential
[parent write declarations](isf-formal-parent-write-products.md) are now retained;
following parent connections and outer domain realization remain later producers. Source-owned
controller execution and physical writer admission retain decision 0109 gates.
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.1.
