# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5.6.10`; the immediately
  preceding slice dispositions the exact 24 plan-byte and execution-summary
  candidates and corrects stale full-family accounting from 135 to 136 tests.
- next_action: review the 59 checking-state and qualification-safety candidates
  on Chapter 16d lines 3519-3696.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
