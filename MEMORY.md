# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7`
  (`active`; common-controller hardening continues)
- next_action: Audit the adjacent destructive cleanup path after bounded census:
  determine whether path replacement or post-census growth can make
  `remove_tree` reclaim an unauthenticated or unbounded tree, then add the exact
  `.17.4.7` RED before any repair.
- in_flight_uncommitted: none after the interrupted-stage recovery census commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
