# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3`
- next_action: from the clean `.17.3.5.3` implementation commit, activate
  proposed child `.17.3.5.3.1` and qualify the macOS pre-main loader-policy
  stall without retry, signing/security changes, or deadline widening.
- in_flight_uncommitted: none after the current commit workflow completes.
- in_flight_background: none
- blockers: none for the lifecycle implementation commit. Proposed child
  `.17.3.5.3.1` retains the platform-qualification prerequisite before the
  parent can close.
