# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5`; the producer-derived
  current-surface inventory and its independent census/RED controls are gated.
- next_action: split the 1,417-candidate migration frontier into bounded
  governed-surface leaves, then begin with the mandatory root-policy claims.
- in_flight_uncommitted: none after the `.4` inventory/doctrine commit.
- in_flight_background: none
- blockers: none.
