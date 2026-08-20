# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.2`; decision `0074` and leaf
  `.1` select the director-requested three-leg adoption contract.
- next_action: install the locally authoritative root policy and its bounded
  discovery routes under `CLAIM-VERIFICATION-ADOPTION.2`.
- in_flight_uncommitted: none after the `.1` selection commit.
- in_flight_background: none
- blockers: none.
