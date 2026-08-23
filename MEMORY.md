# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.3`.
- next_action: commit serialized-plan preflight ownership, revision-archive the
  incompatible 57-profile prefix plus execution-family seal, then prove and
  implement the general byte-exact preflight before restarting the matrix.
- in_flight_uncommitted: none.
- in_flight_background: none
- blockers: none.
