# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.5`
  (`active`; legacy observation and handwritten-fixture migration guidance)
- next_action: Audit the exact legacy observe, UVM 1.2, inert VHDL package, and
  handwritten AHB surfaces before writing 16di and its t1799 watcher.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
