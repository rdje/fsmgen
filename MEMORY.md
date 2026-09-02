# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2`
  (`active`; current-corpus publication parent, profile transaction complete)
- next_action: From the clean `.17.5.2.2` closeout commit, query the Knowledge
  Map and activate `.17.5.2.3` as the separate complete-corpus coordination
  owner before changing implementation.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
