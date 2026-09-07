# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2`
  (`blocked`; causal fixture-startup evidence and independently falsified repair)
- next_action: Read the owning task's service-band recurrence and select a contemporaneous
  causal discriminator before another startup qualification run.
- in_flight_uncommitted: none after the service admission commit workflow.
- in_flight_background: none after consuming the service commit checks.
- blockers: Startup causal repair and parent wire qualification remain open;
  reserved-group launch, runtime activation, complete CI and push stay gated.
