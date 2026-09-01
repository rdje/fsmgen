# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.8`
  (`active`; cross-family cap closeout under decision `0093`)
- next_action: Implement the caller-sealed cross-family consistency layer that
  consumes current policy authority internally and binds every selected group
  to boundary/excess, failure, cleanup, identity, and publication disposition.
- in_flight_uncommitted: none after the `.17.4.8` evidence-inventory commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none.
