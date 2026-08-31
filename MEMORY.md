# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.4`
  (`active`; execution-cap hardening under decision `0093`)
- next_action: audit serialized-plan byte authority and choose the next
  earliest-authority `.17.4.4` slice.
- in_flight_uncommitted: none after the random-attempt authority commit.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none; immutable `.17.3` evidence is the selection input.
