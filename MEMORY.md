# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4`
  (`proposed`; explicit architecture resource caps and bounded failure)
- next_action: after committing the `.17.3.9.2` exact publication seal, activate
  `.17.4` and select its first earliest-authority cap-enforcement slice.
- in_flight_uncommitted: none after the `.17.3.9.2` seal commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none; `.17.3` measurement and immutable closure are complete.
