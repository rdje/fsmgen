# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: none; `CLAIM-VERIFICATION-ADOPTION.6` closes the complete
  three-leg claim adoption from a clean, fully tracked state.
- next_action: from the clean closure commit, activate the already proposed
  `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6` backend-emission leaf.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
