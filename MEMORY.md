# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.3.1`.
- next_action: revision-archive the clean revision-037e56f09 22-profile prefix,
  then implement the bounded accepted-plan random-decision transcript.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
