# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2` (`active`; resumed complete-CI and push qualification)
- next_action: commit this clean-boundary `.3.2` activation, then resume the
  authoritative RAM-guarded complete-CI suffix at exact `t/1545`.
- in_flight_uncommitted: `.3.2` activation metadata only.
- in_flight_background: none
- blockers: none; retained complete-CI evidence remains green/skipped through
  `t/1544`, and committed repair `d630261e6` owns the exact `t/1545` restart.
