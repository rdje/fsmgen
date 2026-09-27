---
id: isf-local-rule-payload-retention-boundary
title: Local rule-trigger payloads lose delayed reads after the request pulse
answers:
  - "why does a local rule-trigger input become zero after a wait?"
  - "are generated do inputs live or snapshots?"
  - "does a local rule trigger automatically install a transaction entry?"
  - "what runtime evidence isolates local trigger payload retention?"
date: 2026-09-27
status: current
tags: [isf, binding, trigger, payload, snapshot, runtime]
evidence: docs/audits/local-rule-payload-scoped-baseline-20260927.json; docs/audits/direct-controller-binding-timing-20260927.json; docs/decisions/0109-direct-transactions-have-independent-logical-controllers.md; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1171-isf-rule-trigger-fanin.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh perl docs/audits/local-rule-payload-scoped-baseline-20260927/reproduce.pl; compare current observations with the bounded scoped baseline. The older diagnostic HDL comparison separately normalizes only its generated Date.
---

Generated do input bindings are live handoffs. Snapshot spelling is correctly
rejected there; the runtime control observes a source change after admission.
Local rule-trigger payload bindings promise snapshots instead. Their per-rule
source is retained, but _rule_trigger_payload_fanin_assignments drives the
local input through a combinational pulse guard and otherwise defaults to zero.

The request-gated `(on worker_start)` probe completes once but reads zero after
its wait with both stable and changed external inputs. A diagnostic emitted-HDL
control changes only that mux default to the retained source and passes both
observations. The generated Date comment differs independently. This confirms
the payload mechanism without claiming a production fix or multi-source policy.

A target without an authored entry free-runs; that intermediate probe is not a
new implicit-entry defect. The local rule contract supplies transaction_start
fan-in and the target authors its request guard, as T1171 demonstrates.
Blocking local calls have a different callee-entry contract and remain separately
unqualified until their controller repair executes.

Decision 0109 preserves these distinctions. Repair owner
SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.2 must qualify early samples,
delayed reads, repeated/reset behavior and granted multiple sources before
closing local payload retention. Generated live-call or trigger qualification
does not close this local defect.


The scoped baseline at b7b18c76095e2c08a629f823d964a2fd28afad93 confirms the
same failure after private formal integration: stable and changed local inputs
both read zero with one completion instead of captured seven. Generated live
controls read seven and thirteen respectively. Canonical source/testbench hashes
are unchanged; no emitted HDL counterfactual is used in this re-verification.

Implementation must derive the target's initial owned state and authored guard.
An entry-cycle payload view must expose a selected request before capture; the
retained value updates only at actual acceptance. Bypass eligibility cannot
depend on an entry guard that itself reads the payload, which would form a
combinational cycle. Busy requests must not replace an accepted payload. Preserve
per-source request/grant guards and generated live timing. New helper declarations
must be produced identically for source preparation and actual domain lowering.

Fresh schedule output also exposes unadvertised child-completion storage roles
and a DT kind. Owner .56 precedes snapshot report-role additions; the scoped
baseline records that separate contract mismatch. Snapshot implementation and
runtime qualification remain .32.1.3.3.1.3.2.2 and .3.
