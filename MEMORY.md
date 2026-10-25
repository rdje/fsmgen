# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.4`
- next_action: Finish .4 staged/normal gates and commit; after clean state activate .5 and durably route the completed GH cache migration, then return to SEM .69.3 checkpointed full CI/push.
- in_flight_uncommitted: derive with `git status --short`; shared-datapath DTO inspection/golden repair is owned by PUBLICATION-REGRESSION-REPAIRS.4 until verified commit.
- in_flight_background: Shared DTO focused/book checks finished successfully; derive any current gate/commit process before replay. Full2 finished143; full3 must use its own checkpointed live journal.
- blockers: GH locality routing and fresh checkpointed full CI precede push. Current query-observation/disposition requirements qualify under .7; original causes remain owned. SEM .69.3 owns exact-SHA hosted success, then macOS relevance review and worktree-gate repair before the saved POD return.
