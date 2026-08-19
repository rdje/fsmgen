---
id: vial-execution-scale-source-cap-representation
title: VIAL operation-scale levels are bounded by the 1-MiB source cap and need repeat above ~74,900
answers:
  - "why can a VIAL scale workload not author one million operations literally?"
  - "what is the VIAL source byte cap and where is it enforced?"
  - "how many literal reset operations fit in a VIAL source?"
  - "when must a VIAL scale workload use repeat instead of a literal action list?"
  - "does VIAL check operation count before or after serializing the plan?"
  - "which cap wins first for VIAL operations total 1000000?"
  - "source exceeds the 1048576-byte limit"
  - "scenario exceeds 65536 expanded actions"
  - "serialized_plan_bytes exceeds the limit 16777216"
  - "why is the VIAL over-limit level cheaper to materialize than the limit level?"
date: 2026-08-19
status: current
tags: [vial, scale, limits, execution-ir, source-cap, repeat]
evidence: >-
  perl/FSM/VIAL/Parser.pm (MAX_SOURCE_BYTES 1048576, MAX_TOKENS 1000000);
  perl/FSM/VIAL/SemanticBuilder.pm (MAX_SCENARIO_ACTIONS 65536, MAX_REPEAT 1000000);
  perl/FSM/VIAL/ExecutionBuilder.pm (expanded_operations_total before serialized_plan_bytes);
  perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm;
  docs/decisions/0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md;
  t/1620-vial-architecture-scale-execution-operation-limit.t;
  t/1621-vial-architecture-scale-execution-operation-over-limit.t
reverify: >-
  grep -n 'MAX_SOURCE_BYTES\|MAX_TOKENS' perl/FSM/VIAL/Parser.pm &&
  grep -n 'MAX_SCENARIO_ACTIONS\|MAX_REPEAT' perl/FSM/VIAL/SemanticBuilder.pm &&
  grep -n 'expanded_operations_total\|serialized_plan_bytes' perl/FSM/VIAL/ExecutionBuilder.pm
---

The architecture-scale generator authors operations as a literal
`(reset bus 1)` list costing 14 bytes each, so the 1-MiB `MAX_SOURCE_BYTES`
parser cap bounds a literal single-scenario workload at roughly 74,900
operations. Measured points: 65,536 operations is 918,533 bytes and 65,537 is
918,547. A literal 1,000,000-operation source would be about 14,001,029 bytes
and is rejected by the source cap — not by the 16-MiB plan cap that decision
`0061` selects for that level. Reaching it requires `(repeat COUNT action)`
spread over at least 16 scenarios, because `MAX_SCENARIO_ACTIONS` caps
expansion at 65,536 per scenario.

Cap order matters for cost. `ExecutionBuilder` checks structural counts such as
`expanded_operations_per_scenario` and `expanded_operations_total` while
building the operation graph, and checks `serialized_plan_bytes` only after
serializing the plan. An over-limit level therefore fails early and cheaply,
while a limit level at `==` the structural cap must serialize a full oversized
plan first. That is why decision `0061` requires preflighting a minimum
representation and forbids materializing a larger nominal limit once a smaller
witness proves monotonic plan-cap dominance.

Related: [[vial-execution-scale-reachability]].
