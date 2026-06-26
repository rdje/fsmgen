# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.553: select APB alias contract`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.554` is active after `.553`; implement the selected bounded APB `.apb` profile-alias requester-transfer contract.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.553` selected `.554`, direct bounded implementation of the first APB `.apb` profile-alias suffix. The selected contract mirrors `ppif/apb_requester_transfer.ppif` at future path `ppif/apb_requester_transfer.apb`, keeps explicit `(profile apb)` with no suffix inference, lowers through generated `apb_requester.isf` before `apb_requester.fsm`, support-accounts the alias as `intent.apb_profile_alias_requester_transfer` with source kind `ial2_profile_alias`, and reserves focused `t/1470-ial2-apb-profile-alias.t` coverage. `.apb` remains unsupported until `.554` implements the contract.
- in_flight_uncommitted: none. Ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The original exact `t/301` resource cliff is fixed for oversized PPIF check-json via `.2.3.1`, but a full guarded `t/301-check-json-supported-corpus.t` rerun stopped on host-memory cutoff from a high host baseline and a higher-cutoff retry was rejected by the approval layer. Do not bypass that rejection without explicit user approval; `.2.5` selected RAM-guarded or exact bounded replacement policy for any future broad `t/301`/`t/303` parity plan. During `.550`, broad `t/1436-ial2-ppif-parser-cli.t` attempts were not used as closeout: normal PATH reached an unrelated existing AXI `--verify-hdl` Verilator warning-as-error, and a reduced-path run was stopped in an existing AXI dynamic check case.
- next_action: Start `.554` by reading `.553`, `.552`, `.550`, `.540`, decisions `0015`-`0018`, APB `.ppif` behavior, `.apb` known-unsupported rejection, suffix dispatch, PPIF profile validation, LanguageSurfaceSection, RegressionCorpus, t/1436, t/1469, t/248, t/297, README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map; then implement only the selected `ppif/apb_requester_transfer.apb` alias contract and preserve `.ppif`, `.axi`, AXI, APB `.ppif`, direct backend, verification-output, and VHDL behavior.

## Notes
- Before re-deriving a logged fact, consult `KNOWLEDGE_MAP.md` (derived question→fact
  index; cards under `docs/knowledge/`, bundle `knowledge-map/`). Write a fact card
  whenever you establish a durable fact or catch archaeology — lazily, never a sweep
  (`docs/tasks/KNOWLEDGE-MAP-ADOPT.md`).
- Push only on explicit user request (no commit-count cadence) — `docs/decisions/0005`.
- PNT autonomously; do not pause mid-flow — `docs/decisions/0003`.
- Heavy broad Perl/`prove`/`fsmgen` commands must run under
  `scripts/run_with_ram_guard.sh` or equivalent monitoring; default cutoff is
  host RAM 88% / descendant RSS 4096 MiB, below the user's 90% danger zone.
  `.295` used documented 90% host-cutoff retries only after default host-memory
  trips; a 92% retry request was rejected as too risky and was not run.
- Optional `slang` HDL validation is a future backend-validation candidate only;
  no `--verify-hdl` policy changed in `.194`
  (`docs/knowledge/hdl-validation-slang-candidate.md`).
- Legacy prose blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`) are FROZEN — git is the audit trail (`docs/decisions/0007`).
