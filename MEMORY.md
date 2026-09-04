# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.7`
  (`proposed`; version-2 foundation closeout)
- next_action: Activate `.19.1.7`, then close public tooling, migration,
  compatibility, containment, and support truth for the version-2 foundation.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
