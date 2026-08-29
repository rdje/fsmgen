# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.4`
  (`done`; verified common-controller portable-VHDL runtime measurement)
- next_action: commit the verified `.17.3.6.4` slice, clear the message file,
  then activate immutable measurement-set publication `.17.3.6.5` from clean.
- in_flight_uncommitted: staged `.17.3.6.4` implementation and closure evidence.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
