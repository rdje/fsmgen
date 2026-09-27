---
id: isf-local-rule-payload-retention-boundary
title: Local rule payload retention at accepted entry
answers:
  - "why does a local rule-trigger input become zero after a wait?"
  - "are generated do inputs live or snapshots?"
  - "does a local rule trigger automatically install a transaction entry?"
  - "what runtime evidence isolates local trigger payload retention?"
date: 2026-09-27
status: current
tags: [isf, binding, trigger, payload, snapshot, runtime]
evidence: t/1965-isf-local-rule-snapshot-integration.t; t/1966-isf-local-rule-snapshot-runtime.t; docs/audits/local-rule-payload-scoped-baseline-20260927.json; docs/audits/direct-controller-binding-timing-20260927.json; docs/decisions/0109-direct-transactions-have-independent-logical-controllers.md; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1171-isf-rule-trigger-fanin.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl -It/lib t/1965-isf-local-rule-snapshot-integration.t t/1966-isf-local-rule-snapshot-runtime.t; the tracked scoped-baseline reproduce.pl retains the original production probes for historical comparison.
---

Generated do input bindings are live handoffs; snapshot spelling is rejected
there. Local rule inputs instead retain accepted payloads. Production lowering
uses the target's first explicitly owned state, exposes each guarded requesting
source during that state, and captures only under the authored entry condition.
The retained value feeds the formal outside that request-visible window.
The view does not depend on a payload-qualified entry guard, avoiding a cycle.
Later entry states and busy requests cannot replace this invocation's payload.

`_local_rule_payload_snapshot_products` supplies both detached source preparation
and actual parent/domain lowering. Names use authored formal identity and reserve
raw formals even after private projection, so freeing a shadowed spelling does
not change allocation. Width/type and internal ownership follow the formal;
helpers use the advertised transaction_port_binding role. Existing per-source
request/grant guards remain. No reset value, implicit entry, queue or source
winner is invented. Binding reports retain authored provenance.

T1965 checks raw/projected naming collisions, signed types, independent domain
scopes, missing preparation category and unreserved declaration controls, strict
carrier replay and full native/API/newline reports. Public-pin SV/Verilog runtime
checks entry samples and delayed reads under a payload-dependent leading when.
T1966 independently qualifies repeated source changes, rejected entry, busy
requests at a later on, reset abort, held level requests and priority/round-robin
grants in both emitted Verilog families. Ungranted overlap trips the payload
selector assertion. Unguarded-target and authenticated generated-live controls
preserve their separate semantics. A held request can accept the next invocation
on the previous invocation's delayed completion edge: entry samples and completed
results then belong to different invocations. The test observes them separately.

Historical evidence stays immutable. At
b7b18c76095e2c08a629f823d964a2fd28afad93, the scoped baseline observes zero with
one completion for stable and changed local inputs, instead of captured seven.
The old pulse-gated formal mux caused that failure, despite retained per-rule
sources. The integrated producer restores seven for both original probes;
generated live controls still observe seven and thirteen respectively. The
canonical source/testbench hashes are unchanged and no emitted HDL is patched.

An unguarded target keeps its authored free-running behavior. Local rule fan-in
supplies transaction_start; the target authors its admission guard. Decision
0109 keeps independent controller execution and blocking local-call ownership
as separate prerequisites. Generated trigger retention is separately qualified.
The baseline's report-enumeration gap is repaired under .56; see
[advertised generated report values](isf-generated-report-enumerations.md).
