# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.2`
  (`proposed`; HIAL/VIAL mdBook entry-path repair)
- next_action: After the `.18.1` selection commits cleanly, activate `.18.2`
  alone to implement its bounded README/SUMMARY, backlog, overview, and
  chapter-boundary repair.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
