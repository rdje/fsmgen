# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.3`
  (`active`; complete store done, ordered coordinator child active)
- next_action: Implement `.17.5.2.3.2` with a RED bounded-worker coordinator
  test before adding production coordination behavior.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
