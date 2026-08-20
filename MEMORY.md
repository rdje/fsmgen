# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5.2`; child `.5.2.1` closes
  the repaired non-rationale root review at this commit boundary.
- next_action: after the clean `.5.2.1` commit, activate `.5.2.2` and review
  the nine foundational rationale candidates against their exact evidence.
- in_flight_uncommitted: `.5.2.1` is complete and awaiting its staged
  acceptance/doctrine gate plus work-unit commit.
- in_flight_background: none
- blockers: none.
