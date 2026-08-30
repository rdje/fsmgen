# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.8.2`
  (`done`; immutable balanced measurement-set seal)
- next_action: activate `.17.3.9` from the clean seal commit to close measured
  families, derived views, and pinned-host/tool candidate budgets.
- in_flight_uncommitted: none after the `.17.3.8.2` seal commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
