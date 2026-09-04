# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.7`
  (`active`; version-2 public-foundation closeout)
- next_action: Commit this continuity-only activation, then implement additive
  v2 check/format/plan, migration, compatibility, and support truth.
- in_flight_uncommitted: continuity-only `.19.1.7` activation candidate.
- in_flight_background: none.
- blockers: none.
