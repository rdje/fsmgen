# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.2`
  (`active`; authored portable-VHDL runtime candidates)
- next_action: author exact 10,000/100,000 v2 candidates at reset counts
  9,926/99,926, then prove twice-rebuilt route/emission identity and limits.
- in_flight_uncommitted: none after the import-map repair.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
