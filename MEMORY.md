# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.4`
  (`blocked`; administrator-assisted targeted startup sampling)
- next_action: Await the director's launch of `bash scripts/await_fixture_kernel_samples.sh`;
  inspect the live session identity/READY record, then perform the owning node's
  bounded diagnostic invocation and submit only a freshly identified target.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: The native sampler needs local authentication in the prepared session;
  Computer Use refused Terminal access. Session command, request schema and scope:
  owning task and `scripts/fixture_kernel_sampler.py`.
  Startup causes, wire qualification, nested containment, RAM fixture repair,
  complete CI and push remain open; retain configured RAM limits.
