# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15`
  (`pending`; failed policy queue attribution)
- next_action: Independently attribute retained queue tokens
  under .3.2.15; the finite original campaign is stopped.
- in_flight_uncommitted: none after this commit.
- in_flight_background: none.
- blockers: Causal repair, queued-work attribution and parent wire/runtime qualification
  remain open; full CI/push gated; no further original or helper is selected.
