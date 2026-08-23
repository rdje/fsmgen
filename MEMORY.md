# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2`.
- next_action: commit the bounded per-profile coordinator, independently
  revalidate the nineteen revision-c7493e3d reports through it, preserve them
  under a verified revision-keyed same-volume archive, then capture a fresh
  exact 72-profile matrix at the clean repaired revision.
- in_flight_uncommitted: isolated coordinator code, adversarial tests, and
  synchronized task/book/fact/rationale records.
- in_flight_background: none
- blockers: none.
