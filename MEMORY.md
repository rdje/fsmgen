# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.13`
- next_action: After .16 commits clean, inspect exclusive full6 slots and current capacity, then launch capture_live.py local-full-ci-6 with fresh FSMGEN_T296_CHECKPOINT=.artifacts/t296/push-readiness-20261025-full6.json, no outer guard and durable console; read its journal before any resume.
- in_flight_uncommitted: Derive exact paths with git status --short; .16 owns its focused report repair/evidence/docs until committed.
- in_flight_background: Focused/fact/book jobs are complete and consumed. Derive staged/commit jobs from exclusive receipts/consoles.
- blockers: .13 complete fresh guarded full CI is required before authorized push/exact-SHA hosted success and post-push macOS review. Retain88/4096; no unrelated process action. .12.3 owns confirmed complete PPlugin/legacy grammar retirement and a self-contained competing test grammar.
