# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.2` (`active`; implement decision `0086`)
- next_action: add the test-only Verilator process supervisor and focused
  source watcher, then migrate the exact audited legacy callsite set without
  changing generated HDL, harness arguments, or non-Darwin behavior.
- in_flight_uncommitted: none at the recorded revision.
- in_flight_background: none
- blockers: none. Complete CI is green through t/1514; t/1515 is the exact
  resume point after the active defect tree repairs its unbounded direct run.
