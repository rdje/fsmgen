# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.2.2`
  (`pending`; implement inactive endpoint filesystem identity)
- next_action: Implement and independently verify the selected endpoint filesystem leaf .3.2.2.
- in_flight_uncommitted: none after this approval checkpoint commit workflow.
- in_flight_background: none; checkpoint doctrine results are consumed.
- blockers: Startup causal repair and parent wire qualification remain open;
  runtime activation, complete CI and push stay gated. Inactive endpoints are approved.
