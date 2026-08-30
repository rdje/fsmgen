# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3`
  (`active`; completed child `.17.3.7`, proposed child `.17.3.8` next)
- next_action: activate `.17.3.8` to measure the caller-sealed revision-2
  balanced portable composition without widening a public contract.
- in_flight_uncommitted: none; `.17.3.7.5` seal is ready for its durable commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
