# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.10.9` (active)
- next_action: Qualify unprivileged native context recording only after child setpgid rejection, using the committed helper and bounded controls; commit before a separately owned use.
  Return to `SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.1` after containment qualification.
  Preserve the spent compiler workspace and `docs/audits/native-proxy-receipt-capture-20260923/result/` evidence.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: Historical T1972 EPERM remains unexplained; the administrator reports SIP denial of the requested syscall probes. No authentication request is pending.
  Historical startup/parent qualification and full CI/push remain gated. mdBook visual audit still lacks browser discovery access.
