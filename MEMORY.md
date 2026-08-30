# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7`
  (`active`; exact OSVVM runtime measurement chain)
- next_action: activate `.17.3.7.4`, then measure the applicable OSVVM runtime
  profiles through the common controller and provider-aware GHDL lifecycle.
- in_flight_uncommitted: `.17.3.7.3` implementation and synchronized evidence
  are ready for focused gates and commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
