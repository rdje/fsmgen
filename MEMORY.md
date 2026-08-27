# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2.1` (`active`; hosted OSVVM provider routing)
- next_action: consume all remaining jobs in exact failed regression run
  33023589424 while auditing and implementing the complete default
  provider-backed dedicated route; commit before activating Linux repair .2.
- in_flight_uncommitted: none
- in_flight_background: exact GitHub regression run 33023589424 is still
  running; Pages 33023589417 and Knowledge Map 33023589413 are successful.
- blockers: none; two exact failure mechanisms are separately task-owned and
  the remaining hosted jobs continue producing evidence.
