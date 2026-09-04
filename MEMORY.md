# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2`
  (`active`; `.19.2.1` done, `.19.2.2` proposed next)
- next_action: From the clean `.19.2.1` selection commit, activate `.19.2.2`
  for lifecycle SemanticIR, binding, execution, plan, result, and source maps.
- in_flight_uncommitted: none after the selection commit.
- in_flight_background: none.
- blockers: none.
