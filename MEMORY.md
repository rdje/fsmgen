# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.2`
- next_action: finish the implementation commit, then activate proposed child
  `.17.3.5.3` for the shared staged Verilator lifecycle.
- in_flight_uncommitted: `.17.3.5.2` implementation, tests, fixtures, and
  synchronized durable documentation.
- in_flight_background: none
- blockers: none.
