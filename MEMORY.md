# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.3`
  (`proposed`; repository-local fixture repair selection)
- next_action: Select the smallest fixture repair preserving native assertions and fixed bounds.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: Startup/parent qualification and full CI/push remain gated.
