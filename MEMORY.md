# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.4` (`done`; completion commit is the required 200-commit push boundary)
- next_action: complete the full-CI, push, and GitHub workflow qualification
  chain for `.17.3.5.4`, then activate `.17.3.5.5` for immutable portable
  runtime-matrix publication and independent reload.
- in_flight_uncommitted: none after the current commit workflow completes.
- in_flight_background: none
- blockers: none. Exact common-controller measurement is green; decision
  `0084` continues to retain the intermittent host observation without a
  backend workaround, retry, signing/security change, or deadline widening.
