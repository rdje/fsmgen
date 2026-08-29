# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.5`
  (`active`; immutable portable-VHDL/GHDL measurement-set publication)
- next_action: commit the verified producer-derived publication implementation,
  then run exact guarded capture and separate fresh-process reload from clean.
- in_flight_uncommitted: implementation module, runner, watcher, and live sync.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
