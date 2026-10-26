# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `ISF-REDUCTION-DELIVERY.3.2.1`
- next_action: Extract the existing canonical binding walk into a shared helper while preserving the strict composition wrapper; qualify focused scope/reference/static/caller controls. Core capture and backend consumers follow; full verification stays .6.
- in_flight_uncommitted: Derive exact paths with git status --short; finish the owning slice through COMMIT.md before advancing.
- in_flight_background: None.
- blockers: Remaining requests block SPECFORGE. Independent publication defects stay deferred until required validation/publication; full CI, authorized push/exact-SHA hosted qualification and post-push macOS review remain later work.
