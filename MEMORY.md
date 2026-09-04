# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.3`
  (`proposed`; public VIAL source-to-result lifecycle reference)
- next_action: After `.18.2` commits cleanly, activate `.18.3` alone to publish
  the selected public lifecycle reference and its executable documentation
  watcher.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
