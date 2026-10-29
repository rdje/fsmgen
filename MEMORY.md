# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `ISF-REDUCTION-DELIVERY.3.4.3.2.3.4.4.1.2.2.3.2.2.1`
- next_action: Prepare globally bounded nested literal captures with explicit birth versus completed child lookup, actual typed edges and nullable exact widths; keep live source/target integration separate.
- in_flight_uncommitted: None after the normal commit workflow; derive paths with git status --short.
- in_flight_background: None.
- blockers: None requiring user input. Required literal repair, remaining feature implementation, owned backend repairs and full/publication qualification remain open.
