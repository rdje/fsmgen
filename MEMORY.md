# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2`
  (`active`; selection complete with trace-isolation repair child proposed)
- next_action: Run full pre-push CI for the 300th local commit, push and consume
  exact-SHA hosted qualification, then activate `.19.2.3.1.2.1`.
- in_flight_uncommitted: none after the `.19.2.3.1.2` selection commit.
- in_flight_background: none.
- blockers: none.
