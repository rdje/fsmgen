# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.1.1`
  (`proposed`; repair stale repository-default claim-registry census watcher)
- next_action: After the clean `.17.5.2.2.1` profile-store commit, update
  t1750's proven stale 26/25 expectation to the current exact 27/26 census.
- in_flight_uncommitted: none; `.17.5.2.2.1` is verified and awaiting commit.
- in_flight_background: none.
- blockers: none.
