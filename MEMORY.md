# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `COMMIT-GATE-PERFORMANCE.2`
- next_action: Deduplicate equivalent deterministic read-only delegated verifiers within one invocation, preserving every proof role and failure. Qualify command/root distinctions and fresh-input rejection; resume ISF .3.3.1.2.2.2 after workflow completion.
- in_flight_uncommitted: Derive exact paths with git status --short; finish the owning slice through COMMIT.md before advancing.
- in_flight_background: None.
- blockers: None for gate streamlining. Required source features and their full/publication qualification remain owned by ISF-REDUCTION-DELIVERY and its coordination trees.
