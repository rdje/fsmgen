# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.12.1`
- next_action: After .12.1 inventory commits clean, activate .12.2: replace Lispish PPlugin lookup with explicit module-origin-derived canonical specs/Lispish.spec compilation; capture compiler top_rule per returned parser and remove only necessary eager/unused legacy imports. Add the declared AST/stability/CWD/dependency compatibility controls before full4.
- in_flight_uncommitted: derive with git status --short; .12.1 owns the complete contract/probe inventory, fact/book updates and metadata until its gated commit. Production, grammar and test inputs remain unchanged.
- in_flight_background: All five bounded probes and first capture84506 finished and settled. Current saved/book/staged/hook outcomes derive from their receipts and active tool sessions. Do not rerun --capture or any historical query/main.
- blockers: Fresh compatibility for the requested independent provider .12.2 and complete clean full4 precede push. Original allocation/query/native causes remain unclosed without blanket holds. Exact-SHA hosted success precedes macOS review, then worktree repair, .6/.10, general retirement .12.3 and applicable .11 before POD return.
