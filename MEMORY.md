# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7`
  (`active`; exact OSVVM runtime measurement)
- next_action: audit the selected runtime-stream, callback-scoped provider,
  adapter-emission, GHDL-lifecycle, and qualification authorities; then select
  the smallest ordered implementation decomposition before changing code.
- in_flight_uncommitted: none after the activation commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
