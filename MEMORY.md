# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5.4.8`; the immediately
  preceding slice closes all 40 foundational Chapter 14i AHB candidates.
- next_action: review the exact 49 candidates on Chapter 14i lines 1071-1406
  against AHB wrap progression, phase ownership, error timing, conditional
  exact-two/three BUSY insertion, aliases, generated HDL, and integration evidence.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
