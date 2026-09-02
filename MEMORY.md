# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3`
  (`active`; current regression-budget qualification)
- next_action: Repair `.17.5.3.1.1`'s performance-applicability identity before
  deriving budgets from the independently closed v2 corpus.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
