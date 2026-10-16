# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `TASK-ACCEPTANCE-AUDIT-SOURCE-COVERAGE.1.1.3` (pending)
- next_action: From clean committed state, own the overdue artifact cleanup, then qualify the original bounded index/source-owner contract in .1.1.3 before audit scope.
- in_flight_uncommitted: derive with `git status --short`; commit any owned slice before activating its successor.
- in_flight_background: None; consume delivery/normal-commit receipts before selecting any successor.
- blockers: Knowledge Map collection rollover debt forbids widening its allowance; preserve all unique facts/questions through governed compaction. Historical native EPERM remains P1-open under HIAL .3.2.10; SIP denies the requested probes. No authentication is pending.
  Historical startup/parent qualification and full CI/push remain gated; Push whenever useful is explicitly authorized by user steering on 2026-10-11; required HIAL/full-CI qualifications still gate it. Visual mdBook QA remains pending.
