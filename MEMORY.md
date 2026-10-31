# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `ISF-REDUCTION-DELIVERY.22.2`
- next_action: After the clean PUBLICATION .18.1 intake commit, activate the existing declaration-aware reserved-identifier repair; preserve SV grammar and generic source-scope/namespace guards, restore T114/APB/OUT native analysis, then publication .18.2 integration and fresh full7/push.
- in_flight_uncommitted: None after the normal intake commit workflow; derive paths with git status --short.
- in_flight_background: None. Full6 settled143; unchanged T114 RED and exact GHDL original1/control0 analyses are consumed and retained in full6-t114-intake-20261101.
- blockers: The reserved-target generation defect now satisfies .22.2 earlier activation. No user input needed; complete full CI, push and hosted/Pages publication remain pending. Saved private concat frontier .3.4.3.3.3.5.4.2 remains pending.
