---
id: task-acceptance-portable-contract
title: Portable task acceptance uses project-declared evidence registries
answers:
  - "how is TASK-ACCEPTANCE made project-neutral?"
  - "where are task-acceptance evidence tokens declared?"
  - "what checklist does a code-changing task need?"
  - "how does task acceptance prevent an old checklist from passing new work?"
  - "why was PGEN TASK-ACCEPTANCE not copied directly?"
  - "is TASK-ACCEPTANCE enforced in FSMGen?"
  - "how do same-repository task-acceptance index probes work?"
date: 2026-10-12
status: current
tags: [doctrine, task-acceptance, evidence, checklist, portability]
evidence: t/lib/FSM/Test/TaskAcceptanceIndexRuntime.pm; t/2068-task-acceptance-index-runtime.t; TASK_ACCEPTANCE.md; docs/decisions/0026-task-acceptance-uses-project-declared-evidence-registries.md; docs/tasks/TASK-ACCEPTANCE-PORTABLE-DOCTRINE.md
reverify: (scripts/decision_records.py read 0026 && cat TASK_ACCEPTANCE.md) | rg -n 'change_paths.tsv|evidence_signatures.tsv|Current-Slice Freshness|ROOT CAUSE|NO REGRESSION'
---

`0026` and `TASK_ACCEPTANCE.md` define a neutral checker; no project tool names. Projects declare path EREs in `doctrine/task_acceptance/change_paths.tsv`
and scoped signature families in `doctrine/task_acceptance/evidence_signatures.tsv`.

Matching staged changes need fresh checked ROOT CAUSE, ADDRESSED and NO
REGRESSION boxes in one staged task file. Root-cause/no-regression signatures
must match inside their own boxes. Every required header must change in the
staged diff; other task edits cannot reuse old checklists.

`scripts/check_doctrines.sh` supplies pre-commit/hosted enforcement of evidence
presence, freshness, scope and shape. Tests/CI establish truth.

`FSM::Test::TaskAcceptanceIndexRuntime` uses bounded fixed cases and an alternate
index in this repository. T2068 checks native status, evidence and cleanup.
