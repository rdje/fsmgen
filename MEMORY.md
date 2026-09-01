# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.8`
  (`proposed`; awaiting clean activation)
- next_action: From the clean `.17.4.7` closure commit, activate only `.17.4.8`
  cross-family cap consistency, atomic-failure, cleanup, and durable closeout;
  change no product behavior in the activation slice.
- in_flight_uncommitted: none after the `.17.4.7` closure commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
