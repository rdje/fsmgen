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
  - how are selected index fixture native rejections observed?
date: 2026-10-18
status: current
tags: [doctrine, task-acceptance, evidence, checklist, portability]
evidence: t/2072-task-acceptance-box-boundaries.t; t/2071-audit-source-acceptance.t; docs/audits/task-acceptance-audit-fixtures-20261017/stale-index-cache-reproduction.json.gz; t/2070-audit-index-fixture-policy.t; t/lib/FSM/Test/TaskAcceptanceIndexRuntime.pm; t/2068-task-acceptance-index-runtime.t; TASK_ACCEPTANCE.md; docs/decisions/0026-task-acceptance-uses-project-declared-evidence-registries.md; docs/tasks/TASK-ACCEPTANCE-PORTABLE-DOCTRINE.md
reverify: (scripts/decision_records.py read 0026 && cat TASK_ACCEPTANCE.md) | rg -n 'change_paths.tsv|evidence_signatures.tsv|Current-Slice Freshness|ROOT CAUSE|NO REGRESSION' && scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/2072-task-acceptance-box-boundaries.t
---

`0026`/`TASK_ACCEPTANCE.md`: neutral checker; path EREs/scoped families use `change_paths.tsv` and `evidence_signatures.tsv` in `doctrine/task_acceptance/`.

Staged work needs fresh checked ROOT CAUSE/ADDRESSED/NO REGRESSION in one task. Root/regression signatures stay box-scoped; every header must change in the staged diff; other edits cannot reuse old boxes. `scripts/check_doctrines.sh` enforces presence/freshness/scope/shape in hooks/CI; tests establish truth.

`FSM::Test::TaskAcceptanceIndexRuntime` uses fixed bounded cases in this repo's alternate index. T2068 checks status/evidence/cleanup; T2070 `audit_*` evidence/doc fixtures leave declaration coverage separate. Gates may refresh stat-cache, never staged entries; retain raw observations and exact native index bytes. Audit `.py/.pl/.pm/.sh/.c/.t` under `docs/audits/` needs fresh evidence; doc neighbors are unclassified. Outdented siblings end boxes; tabs use four-column stops.

`verify_failure.py` in `docs/audits/task-acceptance-index-observer-20261017/` retains failure; prior controls pass; cause unknown. Approved intake: `docs/audits/task-acceptance-index-prospective-20261018/contract.json`. Empty log query: `docs/audits/index-observer-host-correlation-20261018/verify.py`.
