# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5.2.1`; the 72 root candidates
  are partitioned into four exact evidence-coherent review slices.
- next_action: disposition the 33 non-rationale root policy/index candidates
  against current gates, structural identities, or explicit live repairs.
- in_flight_uncommitted: none after the `.5.2` partition-selection commit.
- in_flight_background: none
- blockers: none.
