# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.1`
  (`active`; cross-layer resource-cap and bounded-failure contract selection)
- next_action: complete the declared-versus-earliest cap inventory, resolve
  dominated and unreachable limits under decisions `0056`/`0072`, and record
  the no-behavior-change selection before activating semantic enforcement.
- in_flight_uncommitted: `.17.4` activation documents only; no code change.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none; immutable `.17.3` evidence is the selection input.
