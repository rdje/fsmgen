# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `ISF-SPEC-TEST-INDEX-SYNC.3` (`active`; exact t/1639 post-partition transformation before the pending push gate)
- next_action: commit the green exact-transformation repair, then task-tree-own
  and resolve the t/1558 complete-CI timeout and activate durable t/296
  checkpointing before rerunning complete guarded CI.
- in_flight_uncommitted: none after the current commit workflow completes.
- in_flight_background: none
- blockers: none. Complete CI exposed a separate t/1558 first-run timeout and
  proved t/296 checkpointing was not active before the host guard terminated
  at its unchanged cutoff; both findings have safe next investigations.
