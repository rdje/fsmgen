# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HOSTED-VIAL-REGRESSION-GATE-RESULT.5`
- next_action: Give the semantic-family support contract the guidance its audit requires, or record why that contract is outside the guidance assertion. Do not invent guidance.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: Historical startup/parent qualification and full CI/push remain gated.
