# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `TASK-ACCEPTANCE-CHECKLIST-BODY-BOUNDARY.1.2.4.2` (pending committed preparation)
- next_action: After .1.2.4.1 commits cleanly, consume the approved corrected intake once: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/task-acceptance-index-prospective-20261018/run.py controls. Preserve its first corrected-prefixed result; no second attempt.
- in_flight_uncommitted: derive with `git status --short`; commit any owned slice before activating its successor.
- in_flight_background: None; consume delivery/normal-commit receipts before selecting any successor.
- blockers: Historical native EPERM retains after-return context without kernel cause; HIAL P1/SIP boundary applies. Sole approved attempt failed observer copy preservation; its causal tooling correction passes inert copy controls.
  Director approval permits committed corrected preparation then one qualification; no decision or authentication is pending. Knowledge Map rollover debt forbids allowance growth; preserve all facts/questions.
  Historical startup/parent qualification and full CI/push remain gated; Push whenever useful is explicitly authorized by user steering on 2026-10-11; required HIAL/full-CI qualifications still gate it. Visual mdBook QA remains pending.
