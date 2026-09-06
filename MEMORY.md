# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.3.2`
  (`in_progress`; complete-CI qualification of focused-green output policy)
- next_action: Consume the running complete pre-push gate's terminal result
  from `.artifacts/logs/session-recovery-20260906/full-ci.log` and `full-ci.exit`.
- in_flight_uncommitted: none after this recovery-pointer commit.
- in_flight_background: RAM-guarded `./bin/ci-regression full`, launched
  2026-09-06; guard PID 43485, driver PID 43550, prove PID 43641.
  Check live process identity and the exit file before restarting any work.
- blockers: Startup hangs are owned by `.19.2.3.1.2.2.4` (Rust parity)
  `.19.2.3.1.2.2.5` (live-document verifiers), and `.19.2.3.1.2.2.6` (RAM-guard fixtures);
  the gate retains failed/interrupted T1467/T1554/T1595 results; push is unqualified.
