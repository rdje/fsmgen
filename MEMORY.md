# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.1` (`active`; audit and select the central inline-runtime contract)
- next_action: census every tracked test-side Verilator launch, migrate and
  remove the exact off-volume t/1515 sample, then commit the selected bounded
  supervision and Darwin-qualification contract before implementation.
- in_flight_uncommitted: task-tree activation and durable t/1515 finding.
- in_flight_background: none
- blockers: none. Complete CI is green through t/1514; t/1515 is the exact
  resume point after the active defect tree repairs its unbounded direct run.
