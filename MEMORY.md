# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.9.1`
  (`active`; measured-family derivation and candidate budgets)
- next_action: rerun guarded exact t1683 against the sealed revision-2
  backend-emission prerequisite, then seal the measured-family derivation.
- in_flight_uncommitted: none after the `.17.3.9.1` implementation commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: exact measured-family closure replay remains pending.
