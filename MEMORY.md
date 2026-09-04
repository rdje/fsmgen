# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.5`
  (`active`; common profile-specific backend adapter seams)
- next_action: Commit this continuity-only activation, then implement the
  shared typed v2 preflight/adapter contract across the four selected profiles.
- in_flight_uncommitted: continuity-only `.19.1.5` activation candidate.
- in_flight_background: none.
- blockers: none.
