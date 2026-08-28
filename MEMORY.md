# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2.4`
  (`active`; trace-v2/portable-VHDL dependent-truth repair)
- next_action: align the two failing tests and every audited current-facing
  trace-v2/scale surface, add executable drift oracles, and run focused gates.
- in_flight_uncommitted: none; the repair leaf is the clean implementation
  frontier before the authorized exceptional push.
- in_flight_background: none; the interrupted t303 parent is uncredited.
- blockers: none.
