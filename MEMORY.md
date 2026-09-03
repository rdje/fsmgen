# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.2.2`
  (`active`; transactional fixed-coordinate evidence materialization)
- next_action: Build the root-derived explicit materializer around the
  authenticated version-1 transport, starting with the nonblocking lock and
  identity-scoped same-volume stage/journal lifecycle before any local CI
  driver change.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
