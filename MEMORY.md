# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.24`
- next_action: After .23.1 commits clean, create bounded request15 receiver ownership from
  incoming-request15; review exact clock/reset/event/hold requirements and actor-level owner.
  Reproduce current positive/refusal through the public interface, record self-reset
  non-vacuity obligation, sync book/feedback/KMap and commit before .25/.27/.26.
- in_flight_uncommitted: Derive with git status --short; finish .23.1 normal commit before .24.
- in_flight_background: None; recovered focused/public check processes have exited.
- blockers: No user input needed. Full10 remains nonpassing; fresh full11/push/hosted remain
  .26/.13 after .24/.25/.27. Required SPECFORGE delivery and saved private frontier remain
  open after publication; focused source repair is not full qualification.
