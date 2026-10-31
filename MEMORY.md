# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.17.2.4.3`
- next_action: From the clean committed handoff, activate and reproduce T1616/T1617/T1618/T1619/T1620/T1622 defaults; preserve exact original sources and repair only proved bridge-reference drift before the fiber group and full publication qualification.
- in_flight_uncommitted: None after the normal commit workflow; derive paths with git status --short.
- in_flight_background: None. Plan/random retry0 is consumed and sealed under docs/audits/push-readiness-20261025/.
- blockers: None requiring input. Remaining candidate groups, full CI, push and hosted publication remain pending.
