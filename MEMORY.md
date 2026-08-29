# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.4`
  (`active`; common-controller portable-VHDL runtime measurement)
- next_action: audit the common measurement controller and portable-runtime
  materializer, then implement exact GHDL lifecycle-backed measurement.
- in_flight_uncommitted: activation metadata in this commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
