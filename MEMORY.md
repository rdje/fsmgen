# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1`
- next_action: after the clean `.17.3.5.1.3` implementation commit, activate
  proposed child `.17.3.5.1.4` and rederive every portable scale source
  identity and the threatened 16-MiB boundary.
- in_flight_uncommitted: `.17.3.5.1.3` implementation and closure.
- in_flight_background: none
- blockers: none.
