# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.2`
  (`proposed`; implement isolated current-profile dispatch and admission)
- next_action: After committing the verified `.17.5.2.2.1.1` watcher repair,
  query the Knowledge Map, then audit the public adapters and profile-store API.
- in_flight_uncommitted: `.17.5.2.2.1.1` test/task/frontier repair is verified
  and awaiting its dedicated commit.
- in_flight_background: none.
- blockers: none.
