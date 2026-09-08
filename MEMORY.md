# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.18`
  (`blocked`; authenticated fixed-budget Rust observation)
- next_action: Await a fresh READY helper from
  bash scripts/await_fixture_kernel_samples.sh, then run the fixed guarded
  run_fixture_startup_sequence.py with that session and --target-family rust.
- in_flight_uncommitted: none after the .8.17 fixed-budget commit workflow.
- in_flight_background: none; focused qualification and owned control cleanup consumed.
- blockers: Existing helpers stopped and invalidated authentication.
  The root sampler needs fresh OS administrator authentication; engineering is authorized.
  Startup causal repair, parent wire/runtime qualification, full CI and push stay gated.
