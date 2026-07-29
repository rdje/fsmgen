# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. This file is only the
bounded current-state pointer. Git preserves its prior history.

## Resume

- latest_commit: this task-scoped commit,
  `PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.2: localize runtime and test storage`;
  predecessor `d9bfeb61d`.
- active_work_unit: `PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.3`.
- current_state: `.2` centralizes repository-root/temp/output containment in
  `FSM::ProjectDataLocality`; CLI/in-process IAL1/IAL2 handoffs, Knowledge Map
  scratch, standard test/gate temp and cache environment, legacy config, and
  affected mdBook commands are repository-local. Runtime/test/config migration
  baselines are retired; the exact remaining public-command signature is pinned
  for `.3`.
- next_action: implement `.3`: update README, TOOLBOX, active fact-card
  reverification and generated Knowledge Map paths; inventory exact local and
  off-volume residue; remove only provably FSMGen-owned residue; retire the
  final doctrine migration signature; run closeout gates and commit before
  returning to roadmap PNT.
- in_flight_uncommitted: none after this commit; no background job remains.
- blockers: no implementation blocker. The final broader gate must wait for
  safe host pressure: an unrelated `pgen` rustc held 9,123,344 KiB RSS and the
  RAM guard stopped confirmatory runs at 94.0%/97.9%; the known t/1436 APB
  expectation remains owned by proposed `IAL2-T1436-PREEXISTING-FAILURES`.

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
