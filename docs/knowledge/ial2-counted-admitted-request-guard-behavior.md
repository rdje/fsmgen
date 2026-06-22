---
id: ial2-counted-admitted-request-guard-behavior
title: Counted admitted-request guard alignment is shipped for multi-group queue-head families
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.214 ship?"
  - "how are counted same-ID admitted request pulses guarded?"
  - "what is counted_request_set_capacity_fit?"
  - "what is request_set_fit_expression?"
  - "are AXI manager same-ID request onehot assertions group-local?"
date: 2026-06-22
status: current
tags: [ial2, axi, manager, same-id, counted-capacity, admitted-request, queue-head]
evidence: docs/AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.214|COUNTED_ADMITTED_REQUEST_GUARD_BEHAVIOR|counted_request_set_capacity_fit|request_set_fit_expression|request_assertion_scope|concrete_id_group|_counted_request_set_fit_expr|_same_id_group_local_request_assertion_specs' docs/AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.214` shipped counted admitted-request guard
alignment for generated AXI manager same-ID queue-head families with multiple
concrete-ID groups.

For counted multi-group families, each admitted-request pulse is now gated by a
`request_set_fit_expression` that mirrors the counted capacity/status matrix:
it enumerates current occupancy, Boolean completion credit, selected request
count, and `max_pending` so an over-capacity current request set is rejected
before enqueue. Reports identify that guard as
`guard_source: counted_request_set_capacity_fit` and retain
`over_capacity_policy: reject_current_request_set`.

The counted family-wide request onehot assertion is replaced only for counted
multi-group directions. Those directions now emit one request assertion per
concrete-ID queue group and report
`request_assertion_scope: concrete_id_group`. Non-counted directions and mixed
auto-ID plus one concrete-ID queue-group directions keep Boolean admitted
guards and the existing family-wide request onehot assertion.
