# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.12.2`
- next_action: Consume .12.2 session79420 and parser-provider-capacity receipt after the source commit; commit its outcome, then launch fresh clean full4 if qualified.
- in_flight_uncommitted: .12.2 fact-verification follow-up pending normal gated commit; derive exact paths with git status --short.
- in_flight_background: Tool session79420 runs capture.py parser-provider-capacity under unchanged guard; result is not yet observed. Consume it before full4 or clearing context.
- blockers: Complete clean full4 precedes authorized push/exact-SHA hosted qualification, then macOS review. General legacy retirement .12.3 remains later; no historical blanket hold.
