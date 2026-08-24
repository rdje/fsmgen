# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: none; `.17.3.4.2` and parent `.17.3.4` are complete.
- next_action: activate proposed `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5`
  for qualified-Verilator generation/compile/run/trace/result measurement.
- in_flight_uncommitted: `.17.3.4.2` exact-closure evidence only.
- in_flight_background: none
- blockers: none.
