# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3.3`
- next_action: run `.3.3` — reopen the four containment bounds pinned at their current
  actual, so an ordinary new member stops being a ceremony.
- in_flight_uncommitted: none
- in_flight_background: none
- blockers: none
