# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.1`
  (`active`; stable regression-gate execution and applicability contract)
- next_action: Derive the exact gate/result/entrypoint contract from the sealed
  qualification and canonical profile producers before implementation.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
