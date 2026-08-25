# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3.2` (`done` after the current commit; explicit Darwin runtime qualification)
- next_action: complete focused/doc/doctrine gates and commit `.17.3.5.3.2`,
  run the pre-push complete-CI gate, then activate proposed `.17.3.5.5` for
  immutable portable-runtime matrix publication.
- in_flight_uncommitted: none after the current commit workflow completes.
- in_flight_background: none
- blockers: none. The t/296 checkpoint-activation gap remains durably recorded
  for repair if the pre-push complete-CI gate reproduces it.
