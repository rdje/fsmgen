# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.8`
  (`active`; cross-family cap closeout under decision `0093`)
- next_action: Independently review and bind `semantic_repeat_layering` to
  every sealed consistency dimension; keep calibration blocked until all groups
  are verified.
- in_flight_uncommitted: none; semantic-action-shape evidence is complete and
  the semantic-repeat-layering audit has not started.
- in_flight_background: none.
- blockers: none.
