# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.2`
  (`pending`; tracked T1669 startup observer)
- next_action: Implement and qualify the tracked T1669 observer over committed target
  admission, then request a fresh authenticated capture session.
- in_flight_uncommitted: none after the sampler admission commit workflow.
- in_flight_background: none after consuming the sampler admission checks.
- blockers: Startup causal repair and parent wire qualification remain open;
  reserved-group launch, runtime activation, complete CI and push stay gated.
