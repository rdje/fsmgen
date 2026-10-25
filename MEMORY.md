# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.69.3`
- next_action: After PUBLICATION .5 commits clean, derive full3 journal state; if absent launch checkpointed capture_live.py local-full-ci-3 with env FSMGEN_T296_CHECKPOINT=.artifacts/t296/push-readiness-20261025-full3.json ./bin/ci-regression full. Monitor and own failures; after qualified local full CI push and consume every exact-SHA GitHub workflow/job, then assess macOS relevance.
- in_flight_uncommitted: derive with `git status --short`; any remaining .5 evidence/doc routing belongs to PUBLICATION-REGRESSION-REPAIRS.5 until its verified commit.
- in_flight_background: Derive from .artifacts/push-readiness-20261025/local-full-ci-3.state.json when present; absent means not launched. Never replay a nonterminal journal. Full2 is interrupted143, without full-suite/checkpoint credit.
- blockers: Fresh qualifying full CI precedes push. Current query-observation/disposition requirements qualify under PUBLICATION .7; original causes remain owned. Exact-SHA hosted success precedes macOS relevance review, then the owned linked-worktree gate repair and PUBLICATION .6 guide repair before the saved POD return.
