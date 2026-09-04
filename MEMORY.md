# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.2`
  (`active`; HIAL/VIAL mdBook entry-path repair)
- next_action: Implement the `.18.1`-selected bounded README/SUMMARY,
  future-only backlog, stable overview, and chapter-boundary repair with its
  t1796 executable reader-path watcher.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
