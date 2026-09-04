# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.4`
  (`done`; runnable AHB HIAL/VIAL tutorial and backend/parity walkthrough)
- next_action: Commit completed `.18.4`, then separately activate `.18.5` for
  explicit legacy-observation and handwritten-fixture migration guidance.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
