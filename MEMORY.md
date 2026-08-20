# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5.2.4`; clean commit
  `7cc733514` closed the bridge/execution rationale review before activation.
- next_action: map the 12 owned-shape, model, scoreboard, coverage, fault, and
  random-scale candidates to exact current producers and RED controls.
- in_flight_uncommitted: `.5.2.4` activation continuity only; no claim
  disposition or implementation change yet.
- in_flight_background: none
- blockers: none.
