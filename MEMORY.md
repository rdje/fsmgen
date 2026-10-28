# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `ISF-REDUCTION-DELIVERY.3.4.3.2.2.2.2.3`
- next_action: Qualify exact source-reference/classifier transitions from current birth events and publish only after complete Parser/facade success; clear failure/reuse state before factorizer integration.
- in_flight_uncommitted: None after this slice commits; derive exact paths with git status --short.
- in_flight_background: None.
- blockers: None for the next source slice. Required feature/full/publication qualification remains owned; known symbol/backend lifetime, VHDL-keyword, auxiliary-type and no-transition state-hold repairs precede .6.
