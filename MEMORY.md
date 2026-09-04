# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19`
  (`active`; expressive VIAL frontier selection/decomposition)
- next_action: Commit the continuity-only activation, then read decision 0034
  and current VIAL syntax/IR/backend authorities to derive executable leaves.
- in_flight_uncommitted: `.19` continuity-only activation candidate.
- in_flight_background: none.
- blockers: none.
