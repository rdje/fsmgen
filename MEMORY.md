# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2`
  (`blocked`; director decision on the inactive-endpoint implementation prerequisite)
- next_action: Obtain the director's decision on the exact proposal in this leaf's
  Blocked by field; change no endpoint dependency or runtime route before that decision.
- in_flight_uncommitted: none after this decision-handoff checkpoint commit workflow.
- in_flight_background: none; all diagnostic, test, book and commit results are consumed.
- blockers: Startup causal repair and wire qualification remain open; the proposal
  permits only inactive endpoint implementation. Runtime activation, complete CI and push stay gated.
