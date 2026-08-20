# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5.2`; bounded disposition
  outcomes and required-complete migration groups are doctrine-gated.
- next_action: review all 72 root-document candidates, record exact outcomes,
  and make the root_documents disposition group required-complete.
- in_flight_uncommitted: none after the `.5.1` disposition-gate commit.
- in_flight_background: none
- blockers: none.
