# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HOSTED-VIAL-REGRESSION-GATE-RESULT.19`
- next_action: Stop the next ordinary hosted OSVVM reader from dying when the ignored provider cache is absent. Do not invent a hosted pass.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: Historical startup/parent qualification and full CI/push remain gated.
