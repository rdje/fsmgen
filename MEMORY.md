# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.3` (pending)
- next_action: Qualify and repair owned first-when activation action loss through actual source/public contracts before output-read integration. Preserve activation samples, later branches and precise source refusals. No HDL invocation or record-output widening.
- in_flight_uncommitted: derive with `git status --short`; finish .2.1.1 evidence and commit gates before activating .3. No .3 source change has begun.
- in_flight_background: none.
- blockers: Historical native EPERM remains P1-open under HIAL .3.2.10; SIP denies the requested probes. No authentication is pending.
  Historical startup/parent qualification and full CI/push remain gated. mdBook visual audit still lacks browser discovery access.
