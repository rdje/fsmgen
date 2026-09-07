# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2`
  (`blocked`; original startup attribution and independently verified repair missing)
- next_action: After the checkpoint is committed and the tree is clean, select
  independent sibling `.19.2.3.1.2.2.6` RAM-guard fixture policy from a clean tree.
- in_flight_uncommitted: none after this checkpoint commit workflow.
- in_flight_background: none after observed test/policy/cleanup results are consumed.
- blockers: Startup causal repair and wire qualification remain open; nested containment,
  RAM fixture repair, complete CI and push are pending. Retain configured limits.
