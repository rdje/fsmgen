# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5.4.4`; the immediately
  preceding slice closes all 35 APB width/protection/timing candidates.
- next_action: review the exact 46 candidates on Chapter 14h lines 1200-1699
  against APB multi-register, protection, queued-timing, fixed-composition,
  and multi-peripheral producers and their separating boundary cases.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
