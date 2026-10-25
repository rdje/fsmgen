# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.2`
- next_action: Finish/derive the .1 commit workflow before any next change; then activate .2 and align T1330 quiet strict-outdir assertions, retaining one nonquiet progress control and all generated file-domain checks.
- in_flight_uncommitted: derive with `git status --short`; verified aggregate test/book repair is owned by PUBLICATION-REGRESSION-REPAIRS.1 until its commit workflow completes.
- in_flight_background: Focused aggregate and native book checks finished successfully; derive any current gate/commit process before replay. Full2 finished143; a later full3 must derive status from its own live journal.
- blockers: Follow-up aggregate/quiet/binding/drive-family assertions, GH log-locality durable routing and fresh checkpointed full CI precede push. SEM .69.3 owns exact-SHA hosted success, then macOS relevance review and worktree-gate repair before the saved POD return.
