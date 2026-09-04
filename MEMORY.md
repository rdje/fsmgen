# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.1`
  (`active`; documentation and migration closeout audit)
- next_action: From the clean `.18` activation, build the exact retain/merge/
  repair/supersede matrix across public docs, runnable examples, legacy
  migration, profile truth, claims, and containment before changing prose.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
