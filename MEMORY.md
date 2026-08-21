# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.30`
- next_action: reproduce the through-line original-constant cohort defect in
  `t/1637`, then implement exact adoption-time identity membership.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
