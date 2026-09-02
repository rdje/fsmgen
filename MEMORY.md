# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.3`
  (`active`; complete-corpus coordination partitioned, implementation untouched)
- next_action: After committing the continuity-only `.17.5.2.3` activation,
  activate `.17.5.2.3.1` from a clean tree and implement the bounded
  producer-free complete-corpus report-plus-manifest store.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
