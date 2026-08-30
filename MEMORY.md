# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.9`
  (`active`; measured-family calibration closure)
- next_action: implement `.17.3.9.1` from the clean activation commit: independent
  raw-record/statistics derivation and pinned-host/tool candidate budgets.
- in_flight_uncommitted: none after the `.17.3.9` activation commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
