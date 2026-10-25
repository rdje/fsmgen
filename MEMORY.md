# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.4`
- next_action: Finish/derive .3 commit workflow first; then activate .4, inspect complete public shared-datapath DTO/schema and update T139/T140 nullable pulse_delay_cycles goldens with all strong binding/drive-intent checks retained.
- in_flight_uncommitted: derive with `git status --short`; verified local-do test/book repair is owned by PUBLICATION-REGRESSION-REPAIRS.3 until its commit workflow finishes.
- in_flight_background: Local-do/formal report and native book checks finished successfully; derive any current gate/book/commit process before replay. Full2 finished143; full3 must use its own checkpointed live journal.
- blockers: Drive-family goldens, GH locality routing and fresh checkpointed full CI precede push. Current query-observation/disposition requirements qualify under .7; original causes remain owned. SEM .69.3 owns exact-SHA hosted success, then macOS relevance review and worktree-gate repair before the saved POD return.
