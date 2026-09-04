# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.6`
  (`done` candidate; bounded capability/support reference)
- next_action: Commit the verified `.18.6` publication, then activate `.18.7`
  independently from the clean predecessor.
- in_flight_uncommitted: `.18.6` implementation, watcher, synchronized book,
  Knowledge Map, claims, containment authority, task-tree, and Memory candidate.
- in_flight_background: none.
- blockers: none.
