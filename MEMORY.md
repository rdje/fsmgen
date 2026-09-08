# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.13`
  (`pending`; separate Rust proxy mode source identities)
- next_action: After .8.12 commits, allocate distinct per-mode Rust fixture
  workspaces and independently prove retained source identity and diagnostic
  admission before another causal observation.
- in_flight_uncommitted: none after the .8.12 diagnostic commit workflow.
- in_flight_background: none; assertion probes and fixed-caller controls consumed.
- blockers: Legacy capture and startup causal attribution remain unproved;
  the helper is stopped. Parent wire/runtime qualification, full CI and push
  remain gated on causal repair. No fresh authentication is needed for .8.13.
