# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.12`
  (`pending`; retain complete Rust fixture failure evidence)
- next_action: After the .8.11 evidence commit, repair the status-mismatch
  diagnostic without weakening assertions or rerunning original T1669;
  independently prove complete result retention before causal selection.
- in_flight_uncommitted: none after the .8.11 evidence commit workflow.
- in_flight_background: none; sequence, policy query and native cleanup consumed.
- blockers: Legacy capture and startup causal attribution remain unproved;
  the helper is stopped. Parent wire/runtime qualification, full CI and push
  remain gated on causal repair. No fresh authentication is needed for .8.12.
