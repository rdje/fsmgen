# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.3` (pending)
- next_action: Reconcile selected R1-R3 input requirements against committed frontend, public/profile and direct/generated behavior evidence. Run saved verifiers without HDL replay; close qualified input parents and resume record outputs .60.4.3.3. Preserve X/Z, consumer and historical-native limits.
- in_flight_uncommitted: none after this owning public/corpus reconciliation commit.
- in_flight_background: none.
- blockers: Historical native EPERM remains P1-open under HIAL .3.2.10; SIP denies the requested probes. No authentication is pending.
  Historical startup/parent qualification and full CI/push remain gated. mdBook visual audit still lacks browser discovery access.
