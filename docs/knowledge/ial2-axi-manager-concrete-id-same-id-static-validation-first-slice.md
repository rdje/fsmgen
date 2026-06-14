---
id: ial2-axi-manager-concrete-id-same-id-static-validation-first-slice
title: Concrete-ID same-ID static validation rejects unsupported same-family reuse
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.88 ship?"
  - "does FSMGen currently allow two concrete transactions with the same AXI ID?"
  - "what is the concrete-ID same-ID reuse diagnostic?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.88?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.89?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, concrete-id, ordering, diagnostic, task-tree]
evidence: docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_STATIC_VALIDATION_FIRST_SLICE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.88|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.89|CONCRETE_ID_SAME_ID_STATIC_VALIDATION_FIRST_SLICE|concrete read ID value 3 is reused|same-family concrete-ID reuse|same_id_ordering.residue' docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_STATIC_VALIDATION_FIRST_SLICE.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.88` shipped fail-closed static validation
for unsupported same-family concrete-ID reuse in the AXI manager
capacity/status IAL2 contract.

FSMGen no longer accepts two concrete-ID transactions in the same `read` or
`write` response family that use the same numeric ID value. The diagnostic is:

```text
AXI manager capacity/status IAL2 contract concrete read ID value 3 is reused by transactions 'r0' and 'r1'; concrete same-ID reuse requires a selected same-ID ordering policy or per-ID issue-order queue
```

Read/write family separation remains intact, duplicate concrete assertion event
diagnostics still take precedence, generated auto-ID same-ID avoidance is
unchanged, and valid single-concrete-ID samples keep their generated artifacts
and report residue behavior.

The next active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.89`, a selector for
the next AXI manager feature-completeness owner after this static validation.
