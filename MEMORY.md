# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.2.1`.
- next_action: commit the verified truthful-failure/parser-throughput repair,
  remove the exact 54-file old-revision incomplete publication, then re-prove
  profile 55 at the clean implementation revision and close this child leaf.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
