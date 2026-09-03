# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.2.3`
  (`active`; selected-important-step and local-full gate entrypoints)
- next_action: Audit `bin/ci-regression` and its inventory watcher, then add
  the authenticated materialize/validate/gate/cleanup sequence exactly once
  to the explicit selected mode and unsharded local full path under the common
  RAM guard without changing quick, smoke, ISF, or hosted shard ownership.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
