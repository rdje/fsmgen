---
id: task-acceptance-portable-contract
title: Portable task acceptance uses project-declared evidence registries
answers:
  - how is TASK-ACCEPTANCE made project-neutral?
  - where are task-acceptance evidence tokens declared?
  - what checklist does a code-changing task need?
  - how does task acceptance prevent an old checklist from passing new work?
  - why was PGEN TASK-ACCEPTANCE not copied directly?
  - is TASK-ACCEPTANCE enforced in FSMGen?
  - how do same-repository task-acceptance index probes work?
  - how do audit index evidence profiles work?
  - why can a gate change raw Git index bytes?
  - which audit sources require task acceptance?
date: 2026-10-17
status: current
tags: [doctrine, task-acceptance, evidence, checklist, portability]
evidence: t/2072-task-acceptance-box-boundaries.t; t/2071-audit-source-acceptance.t; docs/audits/task-acceptance-audit-fixtures-20261017/stale-index-cache-reproduction.json.gz; t/2070-audit-index-fixture-policy.t; t/lib/FSM/Test/TaskAcceptanceIndexRuntime.pm; t/2068-task-acceptance-index-runtime.t; TASK_ACCEPTANCE.md; docs/decisions/0026-task-acceptance-uses-project-declared-evidence-registries.md; docs/tasks/TASK-ACCEPTANCE-PORTABLE-DOCTRINE.md
reverify: (scripts/decision_records.py read 0026 && cat TASK_ACCEPTANCE.md) | rg -n 'change_paths.tsv|evidence_signatures.tsv|Current-Slice Freshness|ROOT CAUSE|NO REGRESSION' && scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/2072-task-acceptance-box-boundaries.t
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

`audit_*` adds fixed evidence/doc cases. T2070 checks fixtures; declaration coverage remains separate.

Delivery gates may refresh Git stat-cache metadata without changing staged entries. Retain raw observations; native fixtures still require exact index bytes.

`docs/audits/` `.py/.pl/.pm/.sh/.c/.t` changes require fresh evidence. Document neighbors are unclassified.

Outdented siblings end boxes; tabs use four-column stops.
