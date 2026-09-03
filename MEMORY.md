# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.2.1`
  (`active`; exact ordinal-8 portable-runtime correctness repair)
- next_action: Trace the independently isolated 4 x 24 portable lifecycle
  projection differences to their causal process-telemetry fields, then add
  exact fail-closed RED/GREEN coverage before changing stable admission.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
