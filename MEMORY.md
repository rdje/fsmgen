# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.5`
  (`pending`; actual T1669 workspace admission repair)
- next_action: Qualify T1669 admission against the actual Perl allocator
  with independent native process controls.
- in_flight_uncommitted: none after the capture checkpoint commit workflow.
- in_flight_background: none; test, helper and diagnostic commands consumed.
- blockers: Startup causal repair and parent wire qualification remain open;
  reserved-group launch, runtime activation, complete CI and push stay gated.
