# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.5.1.3`
  (`pending`; daemon-context diagnostic disclosure)
- next_action: Activate .3.2.15.5.1.3 and qualify the fixed daemon predicate and
  bounded diagnostic disclosure with explicit omissions and hostile privacy controls.
- in_flight_uncommitted: none after this commit.
- in_flight_background: none.
- blockers: Startup/containment cause and parent wire/runtime qualification remain open;
  full CI/push gated; the original observation campaign is stopped.
