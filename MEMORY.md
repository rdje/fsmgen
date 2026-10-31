# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `MDBOOK-IAL-LAYER-FRAMING.2`
- next_action: Resume SEMANTIC-INTROSPECTION-MCP-FRONTIER.69.3: resolve known publication-test blockers, run guarded full CI, push and qualify exact-SHA GitHub/Pages publication; preserve the saved required implementation frontier.
- in_flight_uncommitted: None after the normal commit workflow; derive paths with git status --short.
- in_flight_background: None.
- blockers: None requiring user input. Remaining feature implementation, owned backend repairs and full/publication qualification remain open.
