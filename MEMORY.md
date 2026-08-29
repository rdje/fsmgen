# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.2`
  (`active`; authored portable-VHDL runtime candidates)
- next_action: repair the route's exact 256/255 import-map baseline, then author
  10,000/100,000 v2 candidates at reset counts 9,926/99,926.
- in_flight_uncommitted: `.17.3.6.2` records the startup repair prerequisite.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
