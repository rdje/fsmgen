# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.1`
  (`proposed`; bounded same-volume v2 single-profile publication store)
- next_action: After the clean `.17.5.2.2` partition commit, implement the
  caller-sealed synthetic-tested v2 profile-store substrate without producers.
- in_flight_uncommitted: none; `.17.5.2.2` activation is awaiting commit.
- in_flight_background: none.
- blockers: none.
