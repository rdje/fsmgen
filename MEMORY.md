# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.2`
- next_action: answer the owning task's Open Question on the binding,
  execution-type, and source-map levels, then author them.
- in_flight_uncommitted: none
- in_flight_background: none
- blockers: none; the remaining execution-graph levels need a level-selection
  answer first (owning task Open Questions).
