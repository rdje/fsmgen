# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.4.1`
  (`proposed`; resolve legacy semantic/bridge coordinator isolation risk)
- next_action: After the `.17.5.2.2.3` commit, query the Knowledge Map and
  reproduce semantic/bridge revision-1 reload under the unchanged RAM guard.
- in_flight_uncommitted: `.17.5.2.2.3` exact-profile resume is fully verified
  and belongs to this work-unit commit from predecessor `41808b11d`.
- in_flight_background: none.
- blockers: none.
