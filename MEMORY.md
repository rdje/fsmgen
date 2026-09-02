# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.3`
  (`proposed`; close exact same-profile resume and hostile validation)
- next_action: Audit the committed capture/store reload boundary, then implement
  same-revision/same-identity resume without producer execution.
- in_flight_uncommitted: `.17.5.2.2.2` is fully verified and awaiting its
  per-slice commit from clean predecessor `ab8afaf77`.
- in_flight_background: none.
- blockers: none.
