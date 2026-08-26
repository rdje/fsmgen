# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3` (`active`; complete CI and due push qualification)
- next_action: resume the RAM-guarded complete-CI suffix at `t/1515` under the
  standard Darwin guard, repair any exact failure, then push the clean due
  revision and consume every expected hosted workflow/job.
- in_flight_uncommitted: none at the recorded revision.
- in_flight_background: none
- blockers: none. Complete CI is green through `t/1514`; bounded, explicitly
  qualified `t/1515` is focused-green and is the exact suffix resume point.
