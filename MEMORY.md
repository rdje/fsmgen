# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.16`
  (`blocked`; fresh authenticated Rust-only observation)
- next_action: Await a fresh READY helper from
  bash scripts/await_fixture_kernel_samples.sh, then run the fixed guarded
  run_fixture_startup_sequence.py with that session and --target-family rust.
- in_flight_uncommitted: none after the .8.15 selector commit workflow.
- in_flight_background: none; focused qualification and control cleanup consumed.
- blockers: The previous helper stopped and invalidated authentication.
  A fresh root sampler needs OS administrator authentication; engineering is authorized.
  Startup repair, parent wire/runtime qualification, full CI and push remain gated.
