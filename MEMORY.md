# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.29`
  (`in_progress`; exact task-narration containment and HIAL/VIAL root rollover)
- next_action: Commit clean activation, then RED-to-green bounded live task
  narration, exact predecessor recovery, and the HIAL/VIAL rollover.
- in_flight_uncommitted: task/index/Memory activation only; implementation has
  not started.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none; immutable `.17.3` evidence is the selection input.
