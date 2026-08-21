# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6`
- next_action: audit the four negotiated canonical emitters, scale catalog, and
  structural-oracle authorities before selecting the implementation slices.
- in_flight_uncommitted: none after the `.17.2.6` activation commit.
- in_flight_background: none
- blockers: none.
