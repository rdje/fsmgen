# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.17.2.4.5`
- next_action: From the clean committed handoff, reconcile original/current exact candidates and unrun opt-ins, establish current admission and unique full6/checkpoint preflight, commit it, then launch full CI before authorized push/hosted verification.
- in_flight_uncommitted: None after the normal commit workflow; derive paths with git status --short.
- in_flight_background: None. Fiber/aggregate-operation GREEN0 is consumed and sealed under docs/audits/push-readiness-20261025/.
- blockers: None requiring input. Full6 preflight/full CI, push and hosted publication remain pending.
