# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.1`
  (`active`; exact ordinal-10 gate correctness-drift repair)
- next_action: Capture ordinal 10's fresh deterministic correctness projection,
  compare it field-by-field with the immutable qualified projection, and locate
  the first causal producer/oracle divergence before changing source.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
