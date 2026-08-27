# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.2.2` (`done`; exact portable-Verilator runtime matrix sealed)
- next_action: commit exact matrix closure, then activate proposed `.17.3.5.6`
  to retire the stale runtime-claim durability gaps exposed by parent closure.
- in_flight_uncommitted: closure docs/claims/checks await commit.
- in_flight_background: none; regression 33023589424, Pages 33023589417, and
  Knowledge Map 33023589413 are terminal.
- blockers: none; exact capture and standalone guarded reload pass.
