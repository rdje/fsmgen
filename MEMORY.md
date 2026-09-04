# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.6`
  (`proposed`; target-free usability and generated-artifact quality)
- next_action: Activate `.19.1.6`, then make its target-free author and
  deterministic readable generated-artifact requirements executable.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
