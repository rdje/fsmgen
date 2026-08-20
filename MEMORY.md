# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5.4.2`; the immediately
  preceding slice closes all 65 AXI-manager-core/dynamic-identity candidates.
- next_action: review the exact 11 candidates in Chapter 14h lines 1-850 and
  Chapter 16b against foundational profile/APB producers, separating current
  endpoint behavior from profile-alias chronology and navigation identifiers.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
