# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2.3` (`active`; consume the exact first hosted push)
- next_action: consume every remaining job in exact regression run 33023589424;
  preserve green evidence and open a task-owned repair child for any new root cause.
- in_flight_uncommitted: none; exact-run consumption has a dedicated active leaf.
- in_flight_background: exact GitHub regression run 33023589424 is still
  running; Pages 33023589417 and Knowledge Map 33023589413 are successful.
- blockers: none; both known failure roots have committed repairs, and the
  remaining hosted jobs continue producing evidence without cancellation.
