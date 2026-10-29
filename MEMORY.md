# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `ISF-REDUCTION-DELIVERY.3.4.3.2.3.4.3.2.2.2`
- next_action: Publish current staged source bitwise tree births without a semantic revision only after direct Parser or complete facade success. Qualify failure/partial publication/reuse and dependent helper epochs before backend attachment.
- in_flight_uncommitted: None after the normal commit workflow; derive paths with git status --short.
- in_flight_background: None.
- blockers: No technical blocker to next Parser publication slice. Required feature/full/publication qualification and owned backend repairs remain open.
