# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `ISF-REDUCTION-DELIVERY.3.4.3.2.3.4.2.5.2`
- next_action: Wire graph declaration intent into actual one-pass range emission, symbolic guard rank and separate final complete-target ledger comparison.
- in_flight_uncommitted: None after this slice commits; derive exact paths with git status --short.
- in_flight_background: None.
- blockers: None for the next source slice. Required feature/full/publication qualification remains owned; known symbol/backend lifetime, VHDL-keyword, auxiliary-type and no-transition state-hold repairs precede .6.
