# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. This file is only the
bounded current-state pointer. Git preserves its prior history.

## Resume

- latest_commit: this task-scoped commit,
  `PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.1: adopt same-volume data doctrine`;
  predecessor `2efd79375`.
- active_work_unit: `PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.2`.
- current_state: `.1` adopted decision `0022`, root
  `PROJECT_DATA_LOCALITY.md`, a Knowledge Map fact, and registered doctrine
  check `PROJECT-DATA-LOCALITY`. Exact pre-adoption match signatures pin the
  runtime, public-command, explicit-test-path, File::Temp-test, and legacy
  machine-local config debt so it cannot change without the active tree.
- next_action: implement `.2`: add repository-root/project-local storage
  helpers; move CLI and in-process IAL1/IAL2 temporary lowering, Knowledge Map
  scratch files, standard test fixture environment, and live legacy config
  paths onto the repository volume; add focused tests; verify and commit before
  `.3` public/fact-card sync and residue closeout.
- in_flight_uncommitted: none after this commit; no background job remains.
- blockers: none.

## Durable context

- Director authorization (`2026-07-29`): keep the four legacy blobs frozen,
  complete the same-volume adoption tree, then resume roadmap PNT.
- The prior active `IAL2-FEATURE-COMPLETENESS-FRONTIER` is clean and complete
  through `.811` at support `320/361/44`; it has no selected `.812` yet.
- Decision `0020` remains proposed/inactive; do not activate it implicitly.
- New proposed startup-alignment owners: `BIN-FSMGEN-IMPORT-TREE-JUL29-REFRESH`
  (saved 213/212 vs live 227/226 packages),
  `MDBOOK-VHDL-INTRODUCTION-BOUNDARY-SYNC`, and
  `TASK-TREE-FROZEN-LEGACY-DOC-WORKFLOW-SYNC`.
- Other surfaced proposed owners remain indexed in `docs/TASK_TREE.md`,
  including priority enforcement, AHB interconnect arbitration, public-sync
  drift, nested assertion precedence, t/1436 failures, mdBook rustdoc fences,
  and IAL2/mdBook coverage.
- Task-tree live truth is the node list + `docs/TASK_TREE.md` + git (decision
  `0019`). Consult `KNOWLEDGE_MAP.md` before re-deriving durable facts.
- Push only on explicit request (decision `0005`). PNT runs autonomously without
  mid-flow pauses (decision `0003`).
- Heavy commands use `scripts/run_with_ram_guard.sh` or equivalent active
  monitoring. Legacy blobs remain frozen by decision `0007`.
