# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.10`
  (`active`; bounded prospective OS-record retention)
- next_action: After the .8.9 selection commit, select and qualify bounded read-only
  prospective OS-record retention before a fresh authenticated legacy capture.
- in_flight_uncommitted: none after the .8.9 selection commit workflow.
- in_flight_background: none; diagnostic controls and helper children consumed.
- blockers: Startup causal repair and parent wire qualification remain open;
  reserved-group launch, runtime activation, complete CI and push stay gated.
