# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.10`
  (`pending`; original pre-exec containment failure diagnosis)
- next_action: Diagnose .3.2.9's pre-exec containment rejection under .3.2.10; separate
  syscall return, actual group membership and diagnostic errno before repair.
- in_flight_uncommitted: none after this commit.
- in_flight_background: none; original, collector, fixtures and postcheck all consumed.
- blockers: Causal repair, legacy startup failure and parent wire/runtime
  qualification remain open; full CI/push gated; engineering work authorized.
