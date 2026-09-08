# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.11`
  (`blocked`; fresh authenticated legacy capture)
- next_action: After the integration commit, await a fresh READY helper from
  bash scripts/await_fixture_kernel_samples.sh, then run the fixed guarded
  run_fixture_startup_sequence.py with that session and --target-family legacy.
- in_flight_uncommitted: none after the .8.10.2 integration commit workflow.
- in_flight_background: none; controlled/native streams, tests and helpers consumed.
- blockers: Native capture requires a fresh authenticated helper; all prior sessions
  are stopped. Startup causal repair and parent wire qualification remain open;
  reserved-group launch, runtime activation, complete CI and push stay gated.
