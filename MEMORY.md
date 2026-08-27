# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5` (`active`; publish and independently reload the portable-Verilator measurement matrix)
- next_action: audit the completed runtime producer and sibling structural
  publisher, then implement the smallest closed immutable capture/reload seam.
- in_flight_uncommitted: none; activation is commit-owned before implementation.
- in_flight_background: none; regression 33023589424, Pages 33023589417, and
  Knowledge Map 33023589413 are terminal.
- blockers: none; Darwin repair requalification remains deferred to cadence.
