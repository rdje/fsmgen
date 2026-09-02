# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.8`
  (`active`; cross-family cap closeout under decision `0093`)
- next_action: Implement the caller-sealed current-lineage revalidation and
  historical calibration disposition authority defined by the topology audit.
- in_flight_uncommitted: none; the next implementation slice has not started.
- in_flight_background: none.
- blockers: none.
