# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.3.2`
  (`in_progress`; bounded HDL-validator output-policy implementation)
- next_action: Implement amended decision 0101's Yosys quiet argv and byte-exact
  per-stream failure excerpts, then run T313/T1524 and the prior supervisor band.
- in_flight_uncommitted: selection docs are ready for their task-scoped commit;
  no implementation change has begun.
- in_flight_background: none.
- blockers: T1524 falsified the fixed 8 MiB aggregate-capture policy with valid
  Yosys synthesis output; push remains withheld pending repair and complete CI.
