# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.5.4.5`; the immediately
  preceding slice closes all 46 APB multi-register/protection/composition
  candidates.
- next_action: review the exact 37 candidates on Chapter 14h lines 1700-1999
  against generalized two-peripheral register-set width, stride, window,
  count, protection-policy, generated-artifact, and adjacent-boundary evidence.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
