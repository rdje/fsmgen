# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.2`
  (`pending`; shared asynchronous process engine)
- next_action: Extract the shared asynchronous process state machine under
  `.19.2.3.1.2.2.5.5.2.2`, preserving the synchronous facade and current callers.
- in_flight_uncommitted: none.
- in_flight_background: none; every diagnostic process group is gone.
- blockers: Nested group escape blocks neutral-verifier policy acceptance.
  Startup repair `.19.2.3.1.2.2.6` and fresh complete guarded CI also remain open.
  Evidence: owning task and `.artifacts/logs/live-document-policy-20260906/`.
  Full qualification and push remain blocked; retain configured RAM limits.
