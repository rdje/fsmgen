---
id: vial-execution-scale-reachability
title: VIAL execution scale uses canonical routes and reports the earliest real cap
answers:
  - "how will VIAL execution graph scale workloads be generated?"
  - "which VIAL execution scale axes reach their selected limits?"
  - "why does VIAL execution scale need a private qualification binder?"
  - "does the public VIAL binder accept the architecture scale bridge capability?"
  - "how are exact 1 MiB 4 MiB and 16 MiB VIAL plans constructed?"
  - "how is the one million random attempt boundary proved?"
  - "which cap wins for VIAL operations bindings types and source maps?"
date: 2026-08-10
status: current
tags: [vial, execution-ir, scale, binder, bridge, random, replay, plan, limits]
evidence: docs/decisions/0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md; docs/decisions/0060-vial-bridge-scale-uses-a-qualification-only-direct-ial1-profile.md; perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm; perl/FSM/VIAL/ExecutionBuilder.pm; perl/FSM/VIAL/ExecutionRandom.pm; perl/FSM/Support/VIALExecutionContract.pm; t/1603-vial-architecture-scale-execution-foundation.t; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/book/src/16d-hial-vial-verification-architecture.md
reverify: git log -S'hial_vial.bridge_qualification.architecture_scale_v1' --oneline -- perl docs t && prove -Iperl t/1603-vial-architecture-scale-execution-foundation.t && rg -n 'selected_scenarios|expanded_operations_per_scenario|expanded_operations_total|total_fibers|simultaneous_live_fibers|bindings|execution_types|source_map_records|random_attempts|serialized_plan_bytes' perl/FSM/Support/VIALExecutionContract.pm perl/FSM/VIAL/ExecutionBuilder.pm docs/decisions/0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md
---

Decision `0061` selects the `execution_graph_v1` reachability contract. The
fixed AHB route owns scenarios, operations, fibers, source maps, random/replay,
and plan bytes. A plain direct-IAL1 actor owns execution types. The scale-only
bridge event family owns the 2,048-binding gate through a caller-sealed private
binder admission. Public `ExecutionBuilder->build`, public planning, backends,
support accounting, and the decision-`0060` nonclaims remain unchanged.

The first `.17.2.4.2` implementation slice now constructs that binding gate
from ordinary IAL1 and VIAL sources. Exactly 2,042 ordinal events plus the six
unit/domain/endpoint/probe/transaction/field records produce 2,048 bindings.
The plan contains one type, scenario, operation, and fiber, 2,047 source-map
records, and 2,656,823 serialized bytes. The private binder admits only the
exact generator caller and exact qualification protocol metadata; the public
binder and altered metadata still return stable closed errors. The private
capability is labelled `qualification_only` and `private_nonportable`.

The nominal execution limits are not all reachable. Scenarios and
simultaneously live fibers reach their exact 4,096 and 16,384 limits. Operations
per scenario, total operations, total fibers, and source maps encounter the
16-MiB serialized-plan cap at selected higher levels. Binding and type fanout
encounter earlier VIAL-source or bridge event/type caps. Each excess workload
must report the first diagnostic in the canonical semantic → bridge → plan
order; it may not forge a downstream object to reach a preferred number.

Random attempts are independently reachable: a u64 equality constraint targets
the candidate at zero-based attempt `N - 1`. Attempts 8,192, 262,144, and
1,000,000 succeed exactly; target 1,000,001 returns
`VIAL_RANDOM_EXHAUSTED`. Replay must preserve the keyed normalized value and
attempt exactly.

The AHB plan-byte recipes use real reset operations and referenced semantic
identifiers. They produce canonical plans of exactly 1,048,576, 4,194,304, and
16,777,216 bytes; one additional complete reset operation is rejected. These
are construction/boundary facts only. `.17.2.4.2` remains active for every
other execution axis, and no scale capacity is supported until later
measurement and promotion.
