# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.3`
  (`proposed`; immutable common semantic-family envelope)
- next_action: Commit completed `.19.1.2`, then activate `.19.1.3` from the
  clean tree and implement only its common cross-phase envelope boundary.
- in_flight_uncommitted: completed `.19.1.2` parser/projection candidate.
- in_flight_background: none.
- blockers: none.
