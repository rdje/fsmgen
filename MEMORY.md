# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2`
  (`active`; portable-SystemVerilog lifecycle mapping contract selection)
- next_action: Select and independently watch the exact static-controller,
  trace/result, schema-isolation, source-map, atomicity, and rejection contract.
- in_flight_uncommitted: none after the `.19.2.3.1.2` activation commit.
- in_flight_background: none.
- blockers: none.
