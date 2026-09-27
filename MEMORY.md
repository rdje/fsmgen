# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1.1` (active)
- next_action: Consume the read collision regression and commit its qualification under .49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1.1, then retain read plans under .1.2. Follow the scope and pre-allocation cards and decision 0109.
  Preserve the spent compiler workspace and `docs/audits/native-proxy-receipt-capture-20260923/result/` evidence.
- in_flight_uncommitted: .49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1.1 read handoff block collision repair.
- in_flight_background: T1904/T1911/T1949/T1255 confirmation; .artifacts/formal-parent-read-products/collision-regression.log.
- blockers: Historical startup/parent qualification and full CI/push remain gated. mdBook visual audit still lacks browser runtime access after the director enabled full CDP, Computer Use and the Chrome extension; fresh runtime checks still fail before browser discovery.
