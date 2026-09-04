# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2`
  (`active`; lifecycle-control delivery container)
- next_action: From the clean `.19.1.7` closeout commit, activate proposed
  `.19.2.1` alone for lifecycle semantics and target-free source selection.
- in_flight_uncommitted: `.19.1.7` implementation closeout candidate.
- in_flight_background: none.
- blockers: none.
