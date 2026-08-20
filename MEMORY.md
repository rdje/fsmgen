# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5.1`; the 1,417-candidate
  migration frontier is partitioned into five exact surface/topic groups.
- next_action: define and gate the bounded candidate-review disposition
  registry before applying any root-document claim dispositions.
- in_flight_uncommitted: none after the `.5` partition-selection commit.
- in_flight_background: none
- blockers: none.
