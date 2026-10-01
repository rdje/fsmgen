# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5` (pending)
- next_action: From clean committed generated execution reconciliation, read supported VHDL/backend packed-input contracts and current feature/capability/discovery records. Split bounded profile/refusal/public/signoff work under .5.5 before changes, preserving binary/X/Z and historical-native limits. Complete record-input delivery only from independent profile and complete public/baseline evidence.
- in_flight_uncommitted: none after this owning generated execution reconciliation commit.
- in_flight_background: none.
- blockers: Historical native EPERM remains P1-open under HIAL .3.2.10; SIP denies the requested probes. No authentication is pending.
  Historical startup/parent qualification and full CI/push remain gated. mdBook visual audit still lacks browser discovery access.
