# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `ISF-REDUCTION-DELIVERY.2.3.3.4.1.2.2`
- next_action: Bind canonical expression observations to actual scoped top/default/instance identities at .2.3.3.4.1.2.2, then IR propagation before width/source emission; continue required grouped reductions and .10/.7/.8, with full verification deferred to publication readiness.
- in_flight_uncommitted: Derive exact paths with git status --short; finish the owning slice through COMMIT.md before advancing.
- in_flight_background: None; focused resolver checks are complete and consumed.
- blockers: Remaining requests block SPECFORGE. Independent publication defects stay deferred until required validation/publication; full CI, authorized push/exact-SHA hosted qualification and post-push macOS review remain later work.
