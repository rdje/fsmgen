# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.2`
  (`active`; source/parser/SemanticIR architecture-cap hardening)
- next_action: add RED order/atomicity controls for the decision-`0093` semantic
  policy, then move avoidably late same-layer checks before dependent expansion.
- in_flight_uncommitted: none; activation is commit-owned before implementation.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none; immutable `.17.3` evidence is the selection input.
