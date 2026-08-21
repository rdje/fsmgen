# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7`
- next_action: after the clean `.17.2.6.3.6` commit, activate `.17.2.7` for
  runtime-stream construction and balanced portable integration.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
