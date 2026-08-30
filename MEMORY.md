# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.3`
  (`active`; provider-aware shared-GHDL lifecycle role and qualifier refactor)
- next_action: version the shared lifecycle for only the sealed OSVVM plan,
  preserve its portable role, then refactor the exact qualifier onto that role
  with byte-identical checked output and complete failure/cleanup controls.
- in_flight_uncommitted: none after the `.17.3.7.3` activation commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
