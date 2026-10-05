# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.71` (pending)
- next_action: Repair the required ISF synchronization checklist retired-journal directives; then .72 owns Knowledge Map rollover before new source/fact publication.
- in_flight_uncommitted: derive with `git status --short`; commit any owned slice before activating its successor.
- in_flight_background: none.
- blockers: Historical native EPERM remains P1-open under HIAL .3.2.10; SIP denies the requested probes. No authentication is pending.
  Historical startup/parent qualification and full CI/push remain gated; director-directed cadence deferral is owned by SEM .69.2, eventual qualified push by .69.3. Visual mdBook QA remains pending.
