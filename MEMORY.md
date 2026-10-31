# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.13`
- next_action: Inspect .artifacts/push-readiness-20261025/local-full-ci-6.state.json. If absent, launch the exact committed full6-launch-plan-20261031 recorder command from clean HEAD; otherwise consume it before any replay. Keep Git state unchanged throughout native execution for T296.
- in_flight_uncommitted: None after this preflight commit; the full command must stay clean. Final recorder packets appear only after native completion; derive paths with git status --short.
- in_flight_background: Full6 is declared; derive actual state from its journal. Absent means not launched, running means consume, finished means inspect the retained result. Never replay a nonterminal run.
- blockers: No input blocker at admission. Complete full CI, authorized push and every exact-SHA hosted/Pages result remain unqualified.
