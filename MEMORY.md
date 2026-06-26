# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.566: ship APB composition PPIF`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.567` is active after `.566`; select the next APB surface after requester, completer, and fixed composition `.ppif` paths shipped. No behavior changes before that selector completes.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.566` shipped `ppif/apb_composition.ppif` with one embedded requester, one embedded completer, and one explicit `(apb-composition apb_tb ...)` object. It generates `apb_requester.isf`, `apb_completer.isf`, `apb_requester.fsm`, `apb_completer.fsm`, and `apb_tb.fsm`; selects `apb_tb.fsm` as HDL entry; emits report schema `fsmgen.ial2.protocol_intent.apb_composition.v1`; support-accounts `intent.ppif_apb_composition`; and confirms semantic source root kind `top`. Requester busy/status exposure, `.apb` composition/completer aliases, multi-peripheral interconnect/decode, multi-register decode, sidebands/strobes, alternate widths, back-to-back policy, direct backend lowering, verification-output generation, backend-language variants, AXI, and VHDL remain deferred.
- in_flight_uncommitted: none. Ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The original exact `t/301` resource cliff is fixed for oversized PPIF check-json via `.2.3.1`, but a full guarded `t/301-check-json-supported-corpus.t` rerun stopped on host-memory cutoff from a high host baseline and a higher-cutoff retry was rejected by the approval layer. Do not bypass that rejection without explicit user approval; `.2.5` selected RAM-guarded or exact bounded replacement policy for any future broad `t/301`/`t/303` parity plan. During `.550`, broad `t/1436-ial2-ppif-parser-cli.t` attempts were not used as closeout: normal PATH reached an unrelated existing AXI `--verify-hdl` Verilator warning-as-error, and a reduced-path run was stopped in an existing AXI dynamic check case.
- next_action: Start `.567` by reading `.566`, `.565`, `.562`, `.550`, APB requester/completer/composition reports, current residue, README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map; then choose between `.apb` completer/composition alias exposure, requester busy/status, multi-register decode, multi-peripheral interconnect/decode, sidebands/strobes, alternate widths, back-to-back policy, or explicit deferral as the next exact owner.

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
