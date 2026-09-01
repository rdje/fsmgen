# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7`
  (`active`; common-controller hardening continues)
- next_action: Falsify `.17.4.7` selected-tool timeout against a non-completing
  post-SIGKILL reap; bound exact-leader `waitpid` without weakening group
  absence or wait-status authority.
- in_flight_uncommitted: none after the monotonic-containment commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
