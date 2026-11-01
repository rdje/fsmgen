# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.20.7`
- next_action: After clean .6.5 commitment, read complete actual T1353/T1354/T1355/T1357
  imported-constant width tests and retained controls. Update only stale scheduled-source
  expectations; preserve fixed HDL/numeric reports/fixtures/adverse cases. Correct relevant
  book/spec width wording, focused actual tests and commit before .20.8; then full9/push.
- in_flight_uncommitted: Derive with git status --short; finish .6.5 normal commit before .20.7.
- in_flight_background: None. Prior passing default receipts are joined without replay.
- blockers: Remaining observed contract/book repairs, complete full CI, authorized push and all
  exact-SHA hosted/Pages results remain pending. No user input needed. Saved
  ISF-REDUCTION-DELIVERY.3.4.3.3.3.5.4.2 remains pending; macOS relevance follows hosted
  qualification.
