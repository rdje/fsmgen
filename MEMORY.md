# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5.3.5`; the immediately
  preceding slice closes the support-matrix/non-protocol-backlog candidates.
- next_action: review the 51 implementation-blueprint, platform-intent, and
  reference-map candidates in Chapters 15, 16, and 90 against exact current
  producers, separating oracles, and historical/navigation reasons.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
