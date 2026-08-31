# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4`
  (`active`; `.17.4.1` selected the layered architecture resource-cap policy)
- next_action: activate proposed `.17.4.2` from a clean tree, then harden source,
  parser, and SemanticIR caps under decision `0093` without changing accepted bytes.
- in_flight_uncommitted: none; `.17.4.1` is complete and commit-owned.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none; immutable `.17.3` evidence is the selection input.
