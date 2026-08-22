# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7`
- next_action: after the clean `.17.2.7.2.4` implementation commit, activate
  `.17.2.7.3` in a continuity-only slice for unified provider-free qualification.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
