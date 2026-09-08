# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.14`
  (`blocked`; fresh authenticated causal observation)
- next_action: After .8.13 commits, await a fresh READY helper from
  bash scripts/await_fixture_kernel_samples.sh, then run the fixed guarded
  run_fixture_startup_sequence.py with that session and --target-family all.
- in_flight_uncommitted: none after the .8.13 source-identity commit workflow.
- in_flight_background: none; generation probes, diagnostic controls and cleanup consumed.
- blockers: Fixed native capture needs fresh administrator authentication;
  all prior helpers are stopped. Startup causal repair, parent wire/runtime
  qualification, full CI and push remain gated. Engineering work is authorized.
