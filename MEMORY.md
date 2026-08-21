# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.6`; migration is closed at
  zero open owners and the original constant cohort is identity-reconciled.
- next_action: run the complete current-surface adoption audit and close the
  authoritative policy, discovery, registry, task, book, and handoff surfaces.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
