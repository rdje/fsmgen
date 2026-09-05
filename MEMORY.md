# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.1`
  (`done`; verified T1553 containment-success assertion repair awaiting commit)
- next_action: Commit `.2.1`, verify a clean tree, then activate `.2.2` for
  deterministic bounded T313 stubs.
- in_flight_uncommitted: verified `.2.1` test, task, guide/book, and fact-map changes.
- in_flight_background: none.
- blockers: Pre-push qualification cannot pass until T1553's stale exact count
  and T313's PATH-selected unbounded no-op stub are repaired.
