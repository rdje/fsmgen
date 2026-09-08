# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.8`
  (`pending`; passive census integration into fixed policy-only caller)
- next_action: Integrate the qualified passive census into the fixed policy-only caller,
  preserving original result and each independent cleanup before observation.
- in_flight_uncommitted: none after this commit.
- in_flight_background: none; all diagnostic control results and cleanup consumed.
- blockers: Causal repair, legacy startup failure and parent wire/runtime
  qualification remain open; full CI/push gated; engineering work authorized.
