# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.2`
- next_action: obtain the director's bridge-profile choice, then either activate
  the narrow revision-2 qualification route or revise the balanced contract.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: existing portable HIAL routes cannot jointly express the selected
  2,048 bindings/16 transactions/128 events/32 probes without a new contract.
