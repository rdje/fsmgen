# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `ISF-REDUCTION-DELIVERY.22.2`
- next_action: Finish the .22.2 repair commit, then return clean to PUBLICATION-REGRESSION-REPAIRS.18.2 integration and fresh full7/push; preserve the saved private concat frontier.
- in_flight_uncommitted: Canonical .22.2 verified repair/docs pending normal commit; derive paths with git status --short.
- in_flight_background: None. Full6 settled143; unchanged T114 RED and exact GHDL original1/control0 analyses are consumed and retained in full6-t114-intake-20261101.
- blockers: No user input needed; complete full CI, push and hosted/Pages publication remain pending. Saved private concat frontier .3.4.3.3.3.5.4.2 remains pending.
