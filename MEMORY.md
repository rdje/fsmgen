# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2` (active)
- next_action: Qualify library readback namespace preservation under .49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.2, then outer-domain realization under .2.3. Follow the library-ownership and formal-product cards.
  Preserve the spent compiler workspace and `docs/audits/native-proxy-receipt-capture-20260923/result/` evidence.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: Historical startup/parent qualification and full CI/push remain gated. mdBook visual audit still lacks browser runtime access after the director enabled full CDP, Computer Use and the Chrome extension; fresh runtime checks still fail before browser discovery.
