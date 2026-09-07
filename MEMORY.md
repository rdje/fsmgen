# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2`
  (`pending`; T1545 diagnostic preservation and wire qualification)
- next_action: Expose T1545's structured supervisor failure and diagnose the
  retained failed band under `.19.2.3.1.2.2.5.5.2.3.1.2` before endpoint work.
- in_flight_uncommitted: none.
- in_flight_background: none; every diagnostic process group is gone.
- blockers: T1545's empty-output failure blocks wire qualification; nested group
  escape blocks neutral-verifier policy acceptance. RAM fixture repair and CI remain open.
  Evidence: owning task and `.artifacts/logs/coordinator-wire-20260907/`.
  Full qualification and push remain blocked; retain configured RAM limits.
