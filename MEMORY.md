# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3`
  (`pending`; Rust/Verilator fixture startup diagnosis and repair)
- next_action: Diagnose the sampled direct-Perl fixture startup boundary and select
  a bounded repair under `.19.2.3.1.2.2.5.5.2.3.1.2.2.3` before another attempt.
- in_flight_uncommitted: none.
- in_flight_background: none; the failed regression is terminal and recorded PIDs are absent.
- blockers: Rust/Verilator fixture startup timeouts block the broader band; the historical
  T1545 cause remains unknown. Wire qualification, nested containment, RAM fixture repair
  and CI remain open. Evidence: owning task and
  `.artifacts/logs/checker-launch-observation-20260907/`.
  Full qualification and push remain blocked; retain configured RAM limits.
