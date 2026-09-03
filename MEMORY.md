# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.2.1`
  (`active`; immutable current-evidence transport bundle and source verifier)
- next_action: Import Decision 0098's fifteen byte-identical canonical JSON
  payloads, freeze their closed manifest and bundle identity, and add a
  producer-independent read-only verifier plus copied hostile watcher before
  any generated-coordinate materializer or CI driver changes.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
