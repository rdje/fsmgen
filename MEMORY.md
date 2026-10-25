# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.13`
- next_action: After the current-admission intake commits clean, inspect exclusive full5 slots/current admission, then launch capture_live.py local-full-ci-5 with FSMGEN_T296_CHECKPOINT=.artifacts/t296/push-readiness-20261025-full5.json, no outer guard and durable console. Read its journal before any resume.
- in_flight_uncommitted: Derive exact paths with git status --short; .13 owns intake/book/metadata until committed.
- in_flight_background: Native book confirmation21245 completed0 and consumed. Derive staged/commit jobs from their exclusive receipts/consoles; derive full5 from .artifacts/push-readiness-20261025/local-full-ci-5.state.json.
- blockers: Complete local full CI is still required before authorized push/exact-SHA hosted success and post-push macOS review. Current-admission points are a candidate, not an original cause or future guarantee; retain88/4096 and do not touch unrelated processes.
