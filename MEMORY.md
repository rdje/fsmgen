# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-REGISTRY-PARTITION.2`
  (`in_progress`; optional finite registry-set checker contract)
- next_action: Add the pre-repair registry-set RED watcher, then implement
  decision `0094` without changing the production default registry.
- in_flight_uncommitted: leaf `.1` selection evidence and decision `0094` await
  their task-scoped commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
