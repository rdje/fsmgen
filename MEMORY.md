# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5.3.4`; the immediately
  preceding slice closes the control/data/composition/lowering candidates.
- next_action: review the 71 feature-matrix and non-protocol backlog candidates
  in Chapters 13k and 14-14k against support-accounting producers, negative
  controls, and exact backlog-identity reasons.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
