---
id: ial2-counted-admission-capacity-readiness-audit
title: Counted same-ID admission belongs in the capacity matrix
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.210 decide?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.211?"
  - "where should counted same-direction admission be implemented?"
  - "why not implement counted same-id admission as a separate overlay?"
date: 2026-06-21
status: current
tags: [ial2, axi, manager, same-id, counted-admission, capacity]
evidence: docs/AXI_IAL2_MANAGER_COUNTED_ADMISSION_CAPACITY_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.210|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.211|COUNTED_ADMISSION_CAPACITY_READINESS_AUDIT|counted_same_id_selected_requests|reject_current_request_set|_direction_rules|request_accounting' docs/AXI_IAL2_MANAGER_COUNTED_ADMISSION_CAPACITY_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.210` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.211`, a bounded implementation owner for
counted same-ID request capacity substrate while preserving the existing
family-wide same-ID request onehot assertion.

Counted same-direction admission belongs in the shared capacity/status matrix
because that matrix owns public `pending_reads`, `pending_writes`,
`*_slots_available`, `*_full`, and `*_can_accept` outputs. A detached
same-ID-only overlay would either duplicate those outputs or admit request
pulses that the public pending/status rules cannot count.

The next implementation should add report fields such as
`request_accounting.mode: counted_same_id_selected_requests`,
`counted_request_events`, `request_count_expression`, and
`over_capacity_policy: reject_current_request_set`. It must preserve current
one-request-per-direction-per-cycle behavior for legal public samples until a
later group-local onehot owner narrows the assertion.
