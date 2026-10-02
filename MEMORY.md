# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5` (pending)
- next_action: Qualify and repair first-operation conditional macro source intent under .2.1.5 before scalar literal repair and output-read integration. Preserve authored sample-only when activation and later branches; split safe slices as needed. No HDL invocation or record-output widening.
- in_flight_uncommitted: derive with `git status --short`; no inherited work at the .2.1.5 frontier after the current commit workflow.
- in_flight_background: none.
- blockers: Historical native EPERM remains P1-open under HIAL .3.2.10; SIP denies the requested probes. No authentication is pending.
  Historical startup/parent qualification and full CI/push remain gated. mdBook visual audit still lacks browser discovery access.
