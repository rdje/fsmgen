# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.5`
  (`active`; publish exact architecture-scale public truth)
- next_action: Query-first audit the mdBook and executable support/capability
  surfaces against the committed corpus, qualification, gate result, and
  applicability contracts; then select the smallest publication slices.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
