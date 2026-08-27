# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.2` (`active`; repaired clean-revision exact matrix capture/reload)
- next_action: remove only the two censused superseded exact-capture directories,
  then run one guarded exact campaign from the clean active revision.
- in_flight_uncommitted: none; activation is commit-owned before artifact cleanup.
- in_flight_background: none; regression 33023589424, Pages 33023589417, and
  Knowledge Map 33023589413 are terminal.
- blockers: none; the observed 30-second zero-output qualification failure is
  the already retained Darwin pre-main boundary and is not retried or relabelled.
