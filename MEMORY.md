# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.17.2.4.4`
- next_action: From the clean committed handoff, activate and reproduce T1623/T1624/T1625/T1626 defaults; preserve explicit-large guards and repair only proved bridge-reference drift, then finish .5 full6 preflight.
- in_flight_uncommitted: None after the normal commit workflow; derive paths with git status --short.
- in_flight_background: None. Scenario/operation GREEN0 is consumed and sealed under docs/audits/push-readiness-20261025/.
- blockers: None requiring input. Fiber group, full CI, push and hosted publication remain pending.
