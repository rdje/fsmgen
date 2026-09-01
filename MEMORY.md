# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7`
  (`active`; common-controller hardening continues)
- next_action: Inject sustained `EINTR` into `.17.4.7` bounded-host-observer
  `sysread`; prevent the inner retry from suspending its enclosing monotonic
  deadline.
- in_flight_uncommitted: none after the interrupted owned-child poll commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
