# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7`
  (`active`; runtime-state admission hardening)
- next_action: Bind persisted OSVVM emission identity to the selected workload,
  materialization, plan, source, and commands before predecessor-handle read.
- in_flight_uncommitted: none after the persisted-GHDL-provider commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
