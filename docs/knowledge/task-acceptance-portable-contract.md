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
date: 2026-07-30
status: current
tags: [doctrine, task-acceptance, evidence, checklist, portability]
evidence: TASK_ACCEPTANCE.md; docs/decisions/0026-task-acceptance-uses-project-declared-evidence-registries.md; docs/tasks/TASK-ACCEPTANCE-PORTABLE-DOCTRINE.md
reverify: rg -n 'change_paths.tsv|evidence_signatures.tsv|Current-Slice Freshness|ROOT CAUSE|NO REGRESSION' TASK_ACCEPTANCE.md docs/decisions/0026-task-acceptance-uses-project-declared-evidence-registries.md
---

Decision `0026` and `TASK_ACCEPTANCE.md` select a neutral data-driven contract.
The checker embeds no PGEN or FSMGen tool names. An adopting project declares
implementation-path EREs in `doctrine/task_acceptance/change_paths.tsv` and
root-cause/no-regression evidence families in
`doctrine/task_acceptance/evidence_signatures.tsv`.

A matching staged change must carry fresh checked ROOT CAUSE, ADDRESSED, and NO
REGRESSION boxes in one staged task file. Root-cause and no-regression evidence
must match a declared signature inside the corresponding box body. Each
required box header must be added or changed in the current staged diff, so an
old completed checklist cannot satisfy a later slice merely because its task
file changed.

The checker establishes presence, freshness, box scope, and declared evidence
shape. FSMGen registers it in `scripts/check_doctrines.sh`, so the existing
pre-commit hook and hosted workflow run it. Existing deterministic test/CI
commands remain the truth oracle.
