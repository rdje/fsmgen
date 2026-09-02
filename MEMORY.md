# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.3`
  (`active`; complete store/coordinator done, CLI closeout child active)
- next_action: Implement `.17.5.2.3.3` from a RED public CLI watcher, deriving
  repository root from the tracked script and retaining synthetic-only tests.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
