# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5.2.2`; clean commit
  `1f0443b3a` closed the non-rationale root review before this activation.
- next_action: map the nine foundational rationale candidates to exact ledger,
  book-partition, roadmap-archive, UVM-resource, and provider-profile evidence.
- in_flight_uncommitted: `.5.2.2` activation continuity only; no claim
  disposition or implementation change yet.
- in_flight_background: none
- blockers: none.
