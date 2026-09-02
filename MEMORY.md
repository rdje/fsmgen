# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.4.1`
  (`active`; preserve the failed clean-revision capture prefix)
- next_action: Archive the four revision-`610ed7869` profile publications with
  exact reconstruction, then clear the active v2 namespace for owned repair.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
