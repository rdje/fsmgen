# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.2.1`.
- next_action: implement the owned truthful-failure and lexer-throughput repair,
  prove exact profile 55 completes below the unchanged 120-second ceiling, then
  restart the clean-revision 108-profile capture from an exact empty census.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
