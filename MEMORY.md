# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2`.
- next_action: isolate each execution/checking profile capture or resume
  validation in a guard-visible child, prove the bounded coordinator protocol,
  then continue the exact matrix from nineteen immutable profiles.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
