# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.5.1`
  (`active`; publish bounded machine-readable scale-regression truth)
- next_action: Implement and falsify one artifact-independent public VIAL
  architecture-scale regression capability record, cross-checked against the
  tracked evidence bundle and executable gate/qualification authorities.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
