# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3.1`
- next_action: census the exact host/OS/tool/generated-executable metadata and
  run quiet-host plus unaffected controls to falsify macOS policy contention,
  generated-binary construction, and other pre-main causes independently.
- in_flight_uncommitted: none after the current commit workflow completes.
- in_flight_background: none
- blockers: none. The active child forbids retry, signing/security changes,
  deadline widening, unrelated-workload termination, and failed-result
  promotion while causality is unproved.
