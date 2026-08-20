# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5.4.1`; the immediately
  preceding slice partitions all 557 protocol candidates into 16 children.
- next_action: review the exact 65 candidates in Chapters 14f and 14g against
  AXI-manager-core and dynamic-identity producers, separating executable
  behavior from selector chronology and historical support checkpoints.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
