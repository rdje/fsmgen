# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.3`
- next_action: Finish/derive the .7 commit workflow before next change; then activate .3 and repair T1388 physical binding/dataflow assertions using the qualified authored-report intake, preserving width/handshake checks and public logical names.
- in_flight_uncommitted: derive with `git status --short`; verified normal-intake evidence/docs are owned by PUBLICATION-REGRESSION-REPAIRS.7 until its commit workflow finishes.
- in_flight_background: Both normal intakes and saved/KMap/locality checks finished successfully; derive any current book/gate/commit process before replay. Full2 finished143; full3 must use its own checkpointed live journal.
- blockers: Binding/drive-family assertions, GH locality routing and fresh checkpointed full CI precede push. Current query-observation/disposition requirements qualify under .7; original causes remain owned. SEM .69.3 owns exact-SHA hosted success, then macOS relevance review and worktree-gate repair before the saved POD return.
