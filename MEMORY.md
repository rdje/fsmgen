# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.3`
  (`active`; complete store and ordered coordinator done, CLI closeout next)
- next_action: From the clean `.17.5.2.3.2` implementation commit, activate
  `.17.5.2.3.3` for the repository-relative CLI and adversarial closeout.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
