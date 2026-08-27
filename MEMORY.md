# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6` (`active`; portable-VHDL/GHDL runtime measurement)
- next_action: audit the tracked GHDL qualifier, runtime inputs, common
  controller/lifecycle reuse, and materialization gaps; then select children.
- in_flight_uncommitted: none; activation is the current docs-only slice.
- in_flight_background: none; regression 33023589424, Pages 33023589417, and
  Knowledge Map 33023589413 are terminal.
- blockers: none; portable-Verilator parent `.17.3.5` is closed at d21089eb6.
