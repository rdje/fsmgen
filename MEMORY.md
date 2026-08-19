# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.3`
- next_action: select what the remaining binding, execution-type, and source-map
  execution-scale levels mean, and record it in a decision record.
- in_flight_uncommitted: none
- in_flight_background: none
- blockers: `.17.2.4.2` is blocked until `.17.2.4.3` selects; nothing blocks
  `.17.2.4.3`.
