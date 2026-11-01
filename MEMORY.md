# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.13`
- next_action: Read full11-launch-plan-20261102 and inspect its unique journal/checkpoint first.
  Launch the recorded programme once only from clean committed source if all slots are absent;
  otherwise observe/consume its existing result. Keep Git/source unchanged during native CI.
  Complete Perl/VIAL/book0 precedes normal push, all exact-SHA hosted jobs and rendered Pages.
- in_flight_uncommitted: Derive with git status --short; preflight must commit before launch.
- in_flight_background: Derive .artifacts/push-readiness-20261025/local-full-ci-11.state.json;
  live log shares the basename. Never replay existing journal/checkpoint; full10 is settled.
- blockers: No user input needed. Full1-10 remain nonpassing; full11 and publication are pending.
  Request15 implementation and saved ISF-REDUCTION-DELIVERY.3.4.3.3.3.5.4.2 wait behind
  existing publication/required-delivery order; macOS relevance follows qualification.
