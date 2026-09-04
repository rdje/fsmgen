# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3`
  (`active`; portable-SystemVerilog lifecycle implementation)
- next_action: Audit the current portable-SystemVerilog scheduler, trace, result,
  and runner boundaries, then task-tree the smallest honest lifecycle mapping slices.
- in_flight_uncommitted: none after the `.19.2.3` activation commit.
- in_flight_background: none.
- blockers: none.
