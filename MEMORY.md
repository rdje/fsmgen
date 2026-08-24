# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.1`
- next_action: preserve the portable-SV backward-phase successor RED case, then
  implement general phase-aware next-cycle rollover and verify runtime results.
- in_flight_uncommitted: defect-prerequisite activation only; no product code.
- in_flight_background: none
- blockers: none.
