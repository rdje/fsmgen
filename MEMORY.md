# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.9`
  (`active`; closed failing-family diagnostic selection)
- next_action: After the .8.8 capture evidence commit, qualify explicit legacy-only
  selection in the tracked diagnostics, then complete .8.10 prospective OS-record
  retention before another authenticated invocation.
- in_flight_uncommitted: none after the .8.8 capture checkpoint commit workflow.
- in_flight_background: none; sequence, capture, OS queries and helper consumed.
- blockers: Startup causal repair and parent wire qualification remain open;
  reserved-group launch, runtime activation, complete CI and push stay gated.
