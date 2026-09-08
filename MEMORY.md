# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.3`
  (`pending`; fixed normal-user policy-only launcher qualification)
- next_action: Qualify the fixed policy-only launcher under .3.2.3, reusing
  original release/result/cleanup ownership without sudo or kernel sampling.
- in_flight_uncommitted: none after this commit.
- in_flight_background: none; observation and native cleanup results consumed.
- blockers: Causal repair, legacy startup failure and parent wire/runtime
  qualification remain open; full CI/push gated; engineering work authorized.
