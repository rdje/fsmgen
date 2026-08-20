# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5.4`; the immediately
  preceding slice closes all 268 general-book candidates.
- next_action: partition the 557 protocol-profile/integration candidates across
  Chapters 14f-14j, 14l, 16a, 16aa, and 16b into disjoint path- and
  evidence-family-owned children before reviewing any claim.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
