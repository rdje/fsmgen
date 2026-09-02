# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.3.1`
  (`active`; bounded producer-free complete-corpus store)
- next_action: After committing this clean leaf activation, implement the
  caller-sealed canonical report-plus-manifest store and synthetic adversarial
  watcher without invoking profile workers or real capture.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
