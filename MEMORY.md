# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.3`
  (`active`; shared process supervisor and sealed GHDL lifecycle)
- next_action: audit the checked GHDL qualifier and Verilator lifecycle process
  mechanism, then implement their one policy-sealed common supervisor.
- in_flight_uncommitted: none after this activation commits.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
