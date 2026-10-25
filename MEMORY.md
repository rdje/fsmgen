# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.8.1`
- next_action: After .8.1 commits clean, activate .8.2; inspect .artifacts/push-readiness-20261025/t1437-focused-1.state.json. If absent launch capture_live.py t1437-focused-1 with the exact command array in docs/audits/t1437-memory-20261025/plan.json. Consume its verbose guarded outcome and own observations before any repair/full4.
- in_flight_uncommitted: derive with git status --short; .8.1 owns current preflight/continuity/book/metadata changes until its gated commit.
- in_flight_background: Derive the focused run from its t1437-focused-1 journal; absent means unlaunched, nonterminal means consume without replay. Preflight gate/hook completion derives from receipts and any active tool session. Full3 remains terminal137 without full-suite credit.
- blockers: Current full3 host-capacity interruption owns .8 diagnosis after cleanup .9 commit; fresh qualifying full CI precedes push. Historical native/query causes impose no blanket hold. Exact-SHA hosted success precedes macOS review, then worktree repair and PUBLICATION .6/.10 before saved POD return.
