# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5.4.7`; the immediately
  preceding slice closes all 28 expanded APB register-bound candidates and
  completes the Chapter 14h APB review.
- next_action: review the exact 40 candidates on Chapter 14i lines 1-1070
  against foundational AHB endpoint, interconnect, HBURST, BUSY, byte-lane,
  profile-alias, support, generated-artifact, and runtime evidence.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
