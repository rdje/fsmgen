# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.5`
  (`active`; immutable portable-VHDL/GHDL measurement-set publication)
- next_action: run one exact guarded capture from the clean artifact-cardinality
  repair revision, then independently reload and seal its measured evidence.
- in_flight_uncommitted: none after the artifact-cardinality repair commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
