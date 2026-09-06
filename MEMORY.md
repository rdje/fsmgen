# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5`
  (`pending`; bounded neutral live-document verifier policy)
- next_action: Select the neutral verifier and test-fixture execution policy
  under `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5`.
- in_flight_uncommitted: none after the Rust parity implementation commit.
- in_flight_background: none.
- blockers: Startup repairs `.19.2.3.1.2.2.5`/`.6` and a complete guarded
  rerun at safe host pressure are required; retain the configured limits.
  Terminal evidence: `.artifacts/logs/session-recovery-20260906/full-ci-terminal.json`.
  Full qualification and push remain blocked.
