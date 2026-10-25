# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `ISF-REDUCTION-DELIVERY.2.3.2.4.3`
- next_action: After .4.2 commits cleanly, join actual generated/reusable instance context in .2.3.2.4.3 with small focused checks; continue required grouped reductions and .10/.7/.8 in checked dependency order. Full verification is deferred to publication readiness by the director's 2026-10-25 instruction.
- in_flight_uncommitted: Derive exact paths with git status --short; Reduction .2.3.2.4.2 owns completed constructor changes until committed.
- in_flight_background: None; prior repair commit and its checks are complete and consumed.
- blockers: Remaining requests block SPECFORGE. Independent publication defects stay deferred until required validation/publication; full CI, authorized push/exact-SHA hosted qualification and post-push macOS review remain later work.
