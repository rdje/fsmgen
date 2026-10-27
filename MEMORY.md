# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `ISF-REDUCTION-DELIVERY.3.3.3.2`
- next_action: Emit prepared source-declared ranges in actual direct storage rows, including assignment targets absent from module signals. Preserve one-bit rank and fixed/type controls; leave backend-generated helpers and VHDL specialization to their owners.
- in_flight_uncommitted: Derive exact paths with git status --short; finish the owning slice through COMMIT.md before advancing.
- in_flight_background: None.
- blockers: None for the next source slice. Required feature/full/publication qualification remains owned; known symbol/backend lifetime, VHDL-keyword and auxiliary-type consistency repairs precede .6.
