# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `ISF-SPEC-TEST-INDEX-SYNC.3` (`active`; exact t/1639 focused-test index repair before the pending push gate)
- next_action: commit the focused-green one-link repair and fresh maintained-
  reference authority, then rerun complete guarded CI; close `.3`, push, and
  qualify the exact hosted revision only after that gate is green.
- in_flight_uncommitted: none after the current commit workflow completes.
- in_flight_background: none
- blockers: none. The first complete-CI attempt found the exact t/1639 index
  drift, then the host guard terminated final strict-CLI corpus work at its
  unchanged cutoff; the clean retry follows the committed `.3` repair.
