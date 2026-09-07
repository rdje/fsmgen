# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2`
  (`in_progress`; authorized host-policy experiment before verified repair)
- next_action: Inspect fixture provenance and authoritative execution-policy semantics to select
  a bounded causal discriminator for the unresolved startup failure.
- in_flight_uncommitted: none after the permission-observation checkpoint commit workflow.
- in_flight_background: none; authenticated helper is stopped and cleanup consumed.
- blockers: Original timeout attribution, verified repair, wire qualification, nested containment,
  RAM fixture repair, complete CI and push remain open. Retain configured limits.
