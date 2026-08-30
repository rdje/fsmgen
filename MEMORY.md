# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.8.1`
  (`active`; balanced portable structural measurement)
- next_action: implement the caller-sealed one-validation/three-record balanced
  adapter on the common controller; keep external execution inapplicable.
- in_flight_uncommitted: none after the activation commit; the next slice starts clean.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
