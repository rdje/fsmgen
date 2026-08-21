# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2`
- next_action: implement `.17.2.6.2.4` with a T=22 expectation-loss RED control,
  exact T=21 admission, and fail-closed unsupported-shape negotiation.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
