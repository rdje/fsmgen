# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.3.1`
  (`in_progress`; finite HDL-validator output-policy selection)
- next_action: Measure T1524's valid Yosys output volume and select a bounded
  retention/diagnostic policy before implementation child `.3.2` begins.
- in_flight_uncommitted: continuity-only task-tree activation; no implementation
  change has begun.
- in_flight_background: none.
- blockers: T1524 falsified the fixed 8 MiB aggregate-capture policy with valid
  Yosys synthesis output; push remains withheld pending repair and complete CI.
