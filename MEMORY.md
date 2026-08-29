# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.3`
  (`done`; shared process supervisor and sealed GHDL lifecycle)
- next_action: commit this verified implementation, then activate
  `.17.3.6.4` for common-controller portable-VHDL runtime measurement.
- in_flight_uncommitted: implementation and synchronized evidence in this commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
