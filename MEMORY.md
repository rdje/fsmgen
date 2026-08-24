# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.4` (`active`; common-controller portable-Verilator measurement)
- next_action: audit the existing common measurement controller against
  decision `0083`, then route applicable validation and gate/qualification
  repetitions through the shared lifecycle with exact stage evidence.
- in_flight_uncommitted: none after the current commit workflow completes.
- in_flight_background: none
- blockers: none. Decision `0084` retains the host observation through a
  guarded diagnostic only; measurement keeps the unchanged backend,
  security/signing, retry, and deadline contracts.
