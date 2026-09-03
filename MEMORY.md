# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5`
  (`active`; architecture-scale regression stabilization and closeout)
- next_action: From the clean committed `.17.5.4` production-gate closeout,
  activate proposed `.17.5.5` to publish exact commands, envelopes,
  variability policy, capability truth, and nonclaims.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
