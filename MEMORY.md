# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.5.2`
  (`active`; exact human-facing scale-regression publication)
- next_action: Audit the completed machine contract against current README,
  mdBook, Knowledge, and claim surfaces, then publish exact runnable commands,
  envelopes, applicability, cleanup, supported scope, and nonclaims.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
