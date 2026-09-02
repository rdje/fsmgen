# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.1`
  (`active`; current-evidence and representative-promotion contract selection)
- next_action: Audit candidate profiles/current applicability and compare full
  recapture with a narrower versioned promotion corpus before measurement.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
