# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.1`
  (`active`; current-evidence transport and hosted provider selection)
- next_action: Audit the exact 15-file/7,012,284-byte ignored corpus and
  qualification census, evaluate bounded repository-owned transport choices,
  and record the non-recalibrating materialization/provider decision before
  implementing CI entrypoints.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
