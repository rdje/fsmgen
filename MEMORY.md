# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2` (pending)
- next_action: From the committed detached parser-origin proof, qualify actual import/formal/generated/domain association and independent-load authenticity before adopting source metadata; safe normalization .5.4.2 and branching .5.3 stay closed. No HDL invocation or output widening.
- in_flight_uncommitted: derive with `git status --short`; any remaining dirty paths belong to .5.2.1 and must finish its commit workflow before activating .2.
- in_flight_background: none.
- blockers: Historical native EPERM remains P1-open under HIAL .3.2.10; SIP denies the requested probes. No authentication is pending.
  Historical startup/parent qualification and full CI/push remain gated. mdBook visual audit still lacks browser discovery access.
