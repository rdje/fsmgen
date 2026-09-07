# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.6.1`
  (`done`; selected policy checkpoint awaiting its commit workflow)
- next_action: After committing this policy checkpoint and verifying a clean tree, implement
  sibling `.19.2.3.1.2.2.6.2` with the selected admission, result and independent oracle contract.
- in_flight_uncommitted: none after this policy checkpoint commit workflow.
- in_flight_background: none.
- blockers: The separate startup causal repair and wire qualification remain open;
  nested containment, complete CI and push remain pending. Retain configured limits.
