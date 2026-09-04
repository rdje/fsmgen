# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.1`
  (`done`; lifecycle readiness-condition compiler repair)
- next_action: Commit the verified `.19.2.3.1.1` repair, then activate
  `.19.2.3.1.2` for the portable-SystemVerilog lifecycle mapping contract.
- in_flight_uncommitted: none after the `.19.2.3.1.1` implementation commit.
- in_flight_background: none.
- blockers: none.
