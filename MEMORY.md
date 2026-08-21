# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5.4.6`; the immediately
  preceding slice closes all 37 generalized APB register-set candidates.
- next_action: review the exact 28 candidates on Chapter 14h lines 2000-end
  against five- and six-register 16/32-bit protected and unprotected count,
  stride, width, generated-artifact, and adjacent-excess-bound evidence.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
