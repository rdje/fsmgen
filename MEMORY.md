# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.4` (`proposed`; activation is the next clean-boundary action)
- next_action: activate `.17.3.5.4` from the clean qualification closeout, then
  route applicable portable-Verilator runtime profiles through the shared
  lifecycle and common measurement controller.
- in_flight_uncommitted: none after the current commit workflow completes.
- in_flight_background: none
- blockers: none. Decision `0084` closes the host follow-up with a guarded
  diagnostic only; the backend, security/signing, retry, and deadline contracts
  remain unchanged.
