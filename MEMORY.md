# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.20.2.2`
- next_action: After clean .20.2.1 commitment, verify allocation-public-native-plan-20261101 source/tool hashes. If its exclusive journal is absent, create only the ignored output directory and launch the exact recorder once; if present, consume its state/log. Require actual original PPIF --verify-hdl success before closing .20.2, then .20.3-.9 focused contract/book repairs and .20.10 full9 preflight.
- in_flight_uncommitted: Derive with git status --short; finish .20.2.1 source/book/index/claim checks and normal commitment before launching native confirmation.
- in_flight_background: Conditional after clean source handoff: .artifacts/push-readiness-20261025/allocation-public-native-20261101.state.json owns recorder/guard/command recovery. No native job has launched while that journal is absent.
- blockers: Original public PPIF confirmation, remaining observed contract/book repairs, fresh complete local full CI, authorized push and every exact-SHA hosted/Pages result remain pending. No user input needed. Saved ISF-REDUCTION-DELIVERY.3.4.3.3.3.5.4.2 remains pending; macOS relevance follows hosted qualification.
