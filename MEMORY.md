# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-REGISTRY-PARTITION.3`
  (`in_progress`; atomic production claim-registry rollover)
- next_action: Add the finite production manifest and empty second shard,
  switch the no-argument doctrine default, and close every governance surface.
- in_flight_uncommitted: leaf `.2` checker, watcher, and transition docs await
  their task-scoped commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
