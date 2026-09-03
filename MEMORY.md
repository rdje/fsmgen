# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.3`
  (`active`; guarded hosted gate workflow and inventory closeout)
- next_action: Audit the regression workflow family boundaries and t1183, then
  add the one Decision-0098 hosted gate job with exact provider prerequisites,
  authenticated materialization/result checks, owned cleanup, aggregate
  dependency, and no change to existing test ownership.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
