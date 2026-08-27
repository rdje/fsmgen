# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.2` (`active`; exact matrix capture/reload parent)
- next_action: commit completed child `.2.2.1`, then activate proposed child
  `.2.2.2` from the clean dispatcher-repair revision for one exact recapture.
- in_flight_uncommitted: dispatcher repair/docs/checks are verified and await commit.
- in_flight_background: none; regression 33023589424, Pages 33023589417, and
  Knowledge Map 33023589413 are terminal.
- blockers: none; the exact-capture dispatcher defect is repaired and tested.
