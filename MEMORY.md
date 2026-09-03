# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.2.2.2`
  (`active`; complete production regression-gate closeout)
- next_action: From the clean committed ordinal-9 repair, run the complete
  public exact-pinned gate and independently authenticate its result and
  cleanup before exercising unmatched-host and provider-unavailable routes.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
