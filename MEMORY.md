# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.2`
  (`active`; lifecycle compiler-phase implementation)
- next_action: Audit the clean v2 compiler carrier against the selected lifecycle
  contract, then add one focused RED watcher before implementation.
- in_flight_uncommitted: none after the activation commit.
- in_flight_background: none.
- blockers: none.
