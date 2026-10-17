# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `TASK-ACCEPTANCE-CHECKLIST-BODY-BOUNDARY.1.2.2` (pending committed preparation)
- next_action: After .1.2.1 preparation commits cleanly, consume the sole approved prospective qualification: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/task-acceptance-index-prospective-20261018/run.py controls. Retain its first result; no second attempt.
- in_flight_uncommitted: derive with `git status --short`; commit any owned slice before activating its successor.
- in_flight_background: None; consume delivery/normal-commit receipts before selecting any successor.
- blockers: Historical native EPERM retains after-return context without kernel cause; HIAL P1/SIP boundary applies. Director approval permits one prospective observer qualification with historical causality retained. Knowledge Map rollover debt forbids allowance growth; preserve all facts/questions. No authentication is pending.
  Historical startup/parent qualification and full CI/push remain gated; Push whenever useful is explicitly authorized by user steering on 2026-10-11; required HIAL/full-CI qualifications still gate it. Visual mdBook QA remains pending.
