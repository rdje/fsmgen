# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.8`
  (`blocked`; fresh authentication for the qualified diagnostic sequence)
- next_action: After READY from `bash scripts/await_fixture_kernel_samples.sh`,
  run guarded `scripts/run_fixture_startup_sequence.py` with that exact session;
  consume every result and verify helper/process cleanup before committing.
- in_flight_uncommitted: none after the sequence qualification commit workflow.
- in_flight_background: none; unprivileged controls consumed and helpers gone.
- blockers: Startup causal repair and parent wire qualification remain open;
  reserved-group launch, runtime activation, complete CI and push stay gated.
