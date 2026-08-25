# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `ISF-SPEC-TEST-INDEX-SYNC.3` (`active`; exact t/1639 focused-test index repair before the pending push gate)
- next_action: commit the task-tree-only activation, add the one missing
  authoritative mdBook source link, verify and commit `.3`, then rerun complete
  guarded CI before push and GitHub qualification.
- in_flight_uncommitted: none after the current commit workflow completes.
- in_flight_background: none
- blockers: none. The first complete-CI attempt found the exact t/1639 index
  drift, then the host guard terminated final strict-CLI corpus work at its
  unchanged cutoff; the clean retry follows the committed `.3` repair.
