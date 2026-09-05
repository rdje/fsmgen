# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.2.2`
  (`active`; contained production HDL external validation)
- next_action: Select one existing reviewed process mechanism and seal fixed
  HDL-validation policy without duplicating VIAL or test-only authority.
- in_flight_uncommitted: none after the activation commit.
- in_flight_background: none.
- blockers: Pre-push qualification cannot pass until T313's PATH-selected,
  unbounded no-op stub is repaired and the full gate reaches a terminal result.
