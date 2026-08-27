# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2.1` (`done locally`; hosted OSVVM provider routing commit in flight)
- next_action: finish the .3.2.2.1 staged gates and commit, then activate Linux
  logical-core repair .3.2.2.2 while consuming exact run 33023589424.
- in_flight_uncommitted: provider routing implementation, decision 0088,
  closed watcher, Knowledge Map, workflow docs, mdBook, and task evidence.
- in_flight_background: exact GitHub regression run 33023589424 is still
  running; Pages 33023589417 and Knowledge Map 33023589413 are successful.
- blockers: none; provider routing is focused-green, Linux repair remains
  separately proposed, and remaining hosted jobs continue producing evidence.
