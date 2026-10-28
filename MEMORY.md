# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `ISF-REDUCTION-DELIVERY.3.4.3.2.3.4.2.5.2.1.2`
- next_action: Repair RAM-guard owned descendant containment and over-limit startup, preserving stdin, descriptors, metrics and cutoffs. Restore graph paths only after that repair; exact packet and stash are in the owning task.
- in_flight_uncommitted: None after the diagnosis checkpoint commits. Graph prototype is parked in the tracked ram-race audit; derive exact paths with git status --short.
- in_flight_background: None.
- blockers: Heavy runtime work is suspended pending RAM-guard repair. Required feature/full/publication qualification and owned backend repairs remain open.
