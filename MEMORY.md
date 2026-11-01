# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.20.6.1`
- next_action: After clean .5 commitment, follow .6.1 for t/1345-isf-actor-param-actor-constants.t
  and t/1349-isf-actor-param-package-constants.t. Apply retained scalar-width controls, preserve all
  other assertions, then focused checks/book and commit before .6.2. The .6 tree owns
  aggregate/default proof; full9/push/hosted follows known repairs.
- in_flight_uncommitted: Derive with git status --short; finish immutable-width
  book/card/index/claim normal commitment before default-profile edits.
- in_flight_background: None. Complete T1338-T1342 focused result is retained.
- blockers: Remaining observed contract/book repairs, complete full CI, authorized push and all
  exact-SHA hosted/Pages results remain pending. No user input needed. Saved
  ISF-REDUCTION-DELIVERY.3.4.3.3.3.5.4.2 remains pending; macOS relevance follows hosted
  qualification.
