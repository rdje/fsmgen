# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.11`
  (`pending`; passive census identity-rejection diagnosis)
- next_action: Diagnose .3.2.9's passive identity rejection under .3.2.11 with controlled
  native exit/reparent cases; .3.2.12 owns complete legacy failure retention.
- in_flight_uncommitted: none after this commit.
- in_flight_background: none; native/focused/mutant/original/HDL controls and postcheck consumed.
- blockers: Causal repair, legacy startup failure and parent wire/runtime
  qualification remain open; full CI/push gated; engineering work authorized.
