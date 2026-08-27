# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.1` (`active`; portable-VHDL sample-snapshot trace v2)
- next_action: implement the decision-0090 v2 trace emitter/validator and
  regenerate the exact portable-VHDL qualification evidence.
- in_flight_uncommitted: decision-0090 selection/docs slice; no product code.
- in_flight_background: none; regression 33023589424, Pages 33023589417, and
  Knowledge Map 33023589413 are terminal.
- blockers: none; portable-Verilator parent `.17.3.5` is closed at d21089eb6.
