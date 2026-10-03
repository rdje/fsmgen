# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.2` (pending)
- next_action: Split the formal resource/reusable/reservation cohort under .60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.2 into safe source-owned leaves, beginning with T1944; read exact helpers/callers/contracts and book, probe genuine causes with independent source/product/cold limits, own repairs before edits and commit per slice.
- in_flight_uncommitted: derive with `git status --short`; commit any owned slice before activating its successor.
- in_flight_background: none.
- blockers: Historical native EPERM remains P1-open under HIAL .3.2.10; SIP denies the requested probes. No authentication is pending.
  Historical startup/parent qualification and full CI/push remain gated. Visual mdBook QA remains pending.
