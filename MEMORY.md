# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.5.4.3.3.6`
- next_action: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.5.4.3.3.6.7.2.2.2` awaits the director answer on nested cleanup/startup dependency ordering before implementing a fixed probe/tool-resolution capture.
  Read its task acceptance and the existing `.19.2.3.1.2.2.5.5.2.3.3` launch gate. Preserve the spent compiler attempt, original workspace and exact `docs/audits/native-proxy-receipt-capture-20260923/result/` evidence; never replay the compiler.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: Director sequencing question pending: qualify nested cleanup before startup, or retain the explicit coordinator launch prerequisite. Historical startup/parent qualification and full CI/push remain gated.
