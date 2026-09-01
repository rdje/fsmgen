# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.8`
  (`active`; cross-family cap closeout under decision `0093`)
- next_action: Independently review and bind `execution_operation_cardinality` to
  every sealed consistency dimension; keep calibration blocked until all groups
  are verified.
- in_flight_uncommitted: none after the `.17.4.8` execution-profile-selection commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
