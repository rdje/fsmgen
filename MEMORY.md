# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2.5`
  (`active`; pre-push closure and hosted requalification)
- next_action: remove and census exact generated residue, commit complete
  pre-push evidence, then perform the authorized exceptional repair push.
- in_flight_uncommitted: none after this activation commit; pre-push evidence
  is complete and exact cleanup is next.
- in_flight_background: none; the guarded suffix and mdBook build are terminal.
- blockers: none.
