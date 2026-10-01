# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.5.5.3.2.2` (pending)
- next_action: Qualify the precise record-input Verilog profile: valid standards-qualified lowering or contextual refusal. Preserve SystemVerilog/scalar/storage behavior and original native evidence. Split any new HDL admission before execution; then finish selected-input signoff.
- in_flight_uncommitted: none after this owning record-input scope reconciliation commit.
- in_flight_background: none.
- blockers: Historical native EPERM remains P1-open under HIAL .3.2.10; SIP denies the requested probes. No authentication is pending.
  Historical startup/parent qualification and full CI/push remain gated. mdBook visual audit still lacks browser discovery access.
