# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7`
  (`active`; provider-aware OSVVM runtime architecture selected)
- next_action: from the clean selection commit, activate `.17.3.7.1`; then
  implement the exact authored-VHDL-to-OSVVM runtime materializer before any
  execution-plan, lifecycle, tool, measurement, or publication change.
- in_flight_uncommitted: none after the selection commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
