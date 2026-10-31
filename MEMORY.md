# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `ISF-REDUCTION-DELIVERY.3.4.3.3.3.3.4.3.3.5`
- next_action: Close exact owned annotation transitions through actual normalization, checking fixed/mutable guard and RHS applicability before registry replacement.
- in_flight_uncommitted: None after the normal commit workflow; derive paths with git status --short.
- in_flight_background: None.
- blockers: None requiring user input. Remaining feature implementation, owned backend repairs and full/publication qualification remain open.
