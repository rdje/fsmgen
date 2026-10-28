# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `ISF-REDUCTION-DELIVERY.3.4.3.2.3.4.2.5.2.1.3`
- next_action: Restore only the 14 graph prototype paths from the tracked ram-race packet, verify hashes and preserve new safety records, then rerun the five unmonitored cases and unfinished graph controls under repaired session containment.
- in_flight_uncommitted: None after the containment repair commits. Graph prototype remains parked in the ram-race audit; derive exact paths with git status --short.
- in_flight_background: None.
- blockers: No blocker to graph restoration. Required feature/full/publication qualification and owned backend repairs remain open.
