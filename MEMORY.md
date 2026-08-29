# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUSH-CADENCE-300-ADOPTION.1`
  (`active`; director-selected standing push-cadence revision)
- next_action: supersede decision `0062`, change every current cadence authority
  from 200 to 300 commits, preserve historical evidence, verify, and commit.
- in_flight_uncommitted: task-tree activation changes only.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
