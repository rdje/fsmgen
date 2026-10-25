# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.69.3`
- next_action: After .12.2 capacity outcome commits clean, launch capture_live.py local-full-ci-4 with FSMGEN_T296_CHECKPOINT=.artifacts/t296/push-readiness-20261025-full4.json, unchanged guard and no outer guard. Inspect its exclusive journal before any resume.
- in_flight_uncommitted: Derive exact paths with git status --short; .12.2 owns the capacity outcome/book/gate handoff until committed.
- in_flight_background: Before full4, inspect parser-provider-capacity-staged-recovery receipt and .artifacts/push-readiness-20261025/parser-provider-capacity-staged-recovery-console.log; original staged session90122 was lost without an outcome. Capacity79420 completed; derive new full4 work from its journal.
- blockers: Complete local full CI precedes authorized push and every exact-SHA expected hosted workflow/job; then macOS relevance, worktree, .6/.10, legacy retirement .12.3/applicable .11 and POD return. No historical blanket hold.
