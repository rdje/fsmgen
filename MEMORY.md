# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.2`
  (`proposed`; version-2 parsing and equivalent normal/terse projections)
- next_action: Commit completed `.19.1.1`, then activate `.19.1.2` from the
  clean tree and implement only its selected parser/projection boundary.
- in_flight_uncommitted: completed `.19.1.1` contract-selection candidate.
- in_flight_background: none.
- blockers: none.
