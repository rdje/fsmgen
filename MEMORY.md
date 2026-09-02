# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2`
  (`active`; current regression-promotion publication)
- next_action: Execute `.17.5.2.5.4.2.1`'s bounded aggregate-memory diagnosis
  and validation-process isolation repair, then resume `.2.2` clean closeout.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
