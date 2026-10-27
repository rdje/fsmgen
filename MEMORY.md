# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `COMMIT-GATE-PERFORMANCE.3`
- next_action: Compose README routing with the already required live-document gate through explicit successful-prerequisite semantics; keep standalone README validation complete. Resume ISF .3.3.1.2.2.2 after workflow qualification.
- in_flight_uncommitted: Derive exact paths with git status --short; finish the owning slice through COMMIT.md before advancing.
- in_flight_background: None.
- blockers: None for gate streamlining. Required source features and their full/publication qualification remain owned by ISF-REDUCTION-DELIVERY and its coordination trees.
