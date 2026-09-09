# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.5.3.1`
  (`blocked`; administrator authentication)
- next_action: After Terminal READY, recheck the printed session and commit admission.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: No ready authenticated helper; director must run the task-recorded Terminal command.
  Startup/containment and parent qualification remain open; full CI/push gated.
