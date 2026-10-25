# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.15`
- next_action: After .14 commits clean, diagnose each T1551 generated IAL0/direct SV/VHDL byte mismatch through current contract/history/public APIs. Preserve deterministic and behavior-invariance controls before repairing the test.
- in_flight_uncommitted: Derive exact paths with git status --short; .14 owns its focused repair/docs until committed.
- in_flight_background: Focused/fact/book jobs are complete and consumed. Derive staged/commit jobs from exclusive receipts/consoles.
- blockers: .15 repair then .13 complete fresh guarded full CI are required before authorized push/exact-SHA hosted success and post-push macOS review. Retain88/4096; no unrelated process action. .12.3 owns confirmed complete PPlugin/legacy grammar retirement and a self-contained competing test grammar.
