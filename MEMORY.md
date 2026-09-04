# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.4`
  (`done`; implementation verified, pending commit)
- next_action: Commit `.19.1.4`, clear the brief, then activate `.19.1.5` for
  common portable-SV, native-UVM, and VHDL/OSVVM backend adapter seams.
- in_flight_uncommitted: completed `.19.1.4` implementation and closeout.
- in_flight_background: none.
- blockers: none.
