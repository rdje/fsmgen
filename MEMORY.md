# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5.4.14`; the immediately
  preceding slice closes all six extended-AXI backlog candidates.
- next_action: review the exact 40 candidates in Chapter 14l against backend
  support, external validation, generation structure, semantic export, and
  embedding/public-API evidence.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
