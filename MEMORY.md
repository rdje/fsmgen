# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.1`
  (`active`; lifecycle semantic and target-free source selection)
- next_action: Audit lifecycle authorities and select the exact target-neutral
  semantics, normal/terse forms, bounds, defaults, diagnostics, and nonclaims.
- in_flight_uncommitted: none; activation commits before selection work begins.
- in_flight_background: none.
- blockers: none.
