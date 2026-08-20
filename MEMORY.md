# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.4`; the bounded claim-record
  checker, exact markers, path locality, and positive/RED controls are gated.
- next_action: run the producer-derived current-surface claim/constant census,
  classify every candidate, and assign exact migration or debt owners.
- in_flight_uncommitted: none after the `.3` checker/doctrine commit.
- in_flight_background: none
- blockers: none.
