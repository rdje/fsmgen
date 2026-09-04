# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.6`
  (`active`; bounded capability/support reference)
- next_action: Commit the continuity-only activation, then derive the exact
  profile matrix and troubleshooting routes from current machine authorities.
- in_flight_uncommitted: `.18.6` continuity-only activation candidate.
- in_flight_background: none.
- blockers: none.
