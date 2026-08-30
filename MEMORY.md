# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.9`
  (`active`; measured-family calibration closure)
- next_action: activate `.17.3.9.2` for atomic closure publication and
  independent fresh-process reload.
- in_flight_uncommitted: none after the `.17.3.9.1` derivation seal.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none; `.17.3.9.2` remains proposed until the clean pivot.
