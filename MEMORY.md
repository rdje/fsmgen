# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2`
  (`pending`; T1545 launch evidence and wire qualification)
- next_action: Select bounded checker launch observation under `.19.2.3.1.2.2.5.5.2.3.1.2.2`
  before another diagnostic attempt or endpoint implementation.
- in_flight_uncommitted: none.
- in_flight_background: none; every diagnostic process group is gone.
- blockers: T1545's unexplained historical failure blocks wire qualification; nested group
  escape blocks neutral-verifier policy acceptance. RAM fixture repair and CI remain open.
  Evidence: owning task and `.artifacts/logs/task-acceptance-diagnostics-20260907/`.
  Full qualification and push remain blocked; retain configured RAM limits.
