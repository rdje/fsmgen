# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2`
  (`blocked`; causal fixture-startup evidence and bounded repair)
- next_action: Read the owning blocked node and its prerequisite investigation;
  obtain a causal startup discriminator before selecting a repair or qualification run.
- in_flight_uncommitted: none.
- in_flight_background: none; the observed focused band and its guard are terminal.
- blockers: Retained Rust/Verilator startup failures remain unexplained; fresh passing
  observations cannot establish a repair. The historical T1545 cause is also unknown.
  Wire qualification, nested containment, RAM fixture repair and complete CI remain open.
  Evidence: owning task and `.artifacts/logs/fixture-startup-20260907/`.
  Full qualification and push remain blocked; retain configured RAM limits.
