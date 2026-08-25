# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3.2` (`active`; retained macOS pre-main standard-CI instability)
- next_action: commit recovery-child activation, capture one fresh no-retry
  guarded primary/control record under an honestly observed host condition,
  then select and verify the production-grade CI contract.
- in_flight_uncommitted: none after the current commit workflow completes.
- in_flight_background: none
- blockers: none. The t/1558 failure is reproducible and task-owned; the later
  t/296 checkpoint-activation gap remains durably recorded for repair before
  the next complete-CI attempt.
