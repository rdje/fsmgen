# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.3`
  (`active`; public VIAL source-to-result lifecycle reference)
- next_action: Implement the selected `16dg` public lifecycle reference and
  executable `t/1797` watcher from the exact public CLI/API and machine-contract
  truth, without presenting private IR/backend plumbing as API.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
