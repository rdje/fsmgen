# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.3`
  (`blocked`; fresh capture after native query-race repair)
- next_action: Await READY from `bash scripts/await_fixture_kernel_samples.sh`,
  then invoke guarded `scripts/run_fixture_startup_observation.py` with that
  exact session directory; consume original test, capture and helper outcomes.
- in_flight_uncommitted: none after the query-race repair commit workflow.
- in_flight_background: none; focused controls consumed and helper stopped.
- blockers: Startup causal repair and parent wire qualification remain open;
  reserved-group launch, runtime activation, complete CI and push stay gated.
