# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.3`
  (`active`; immutable common semantic-family envelope)
- next_action: Commit the continuity-only `.19.1.3` activation, then inspect
  the selected v2 and phase contracts and implement only their common envelope.
- in_flight_uncommitted: continuity-only `.19.1.3` activation candidate.
- in_flight_background: none.
- blockers: none.
