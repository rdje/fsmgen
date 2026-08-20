# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5.3.3`; the immediately
  preceding slice closes the intent/actor/transaction candidates.
- next_action: review the 68 control-flow, data, composition, rules, lowering,
  and type candidates in Chapters 13d-13j against their exact parser,
  lowering, and runtime evidence families.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
