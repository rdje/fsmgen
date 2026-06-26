# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4: select passive UVM monitor skeleton`.
- active_work_unit: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7` selects the public CLI/artifact-layout/report/manifest/support-accounting/validation contract for the passive UVM monitor skeleton before any SV/UVM files are emitted; `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remains active/pending.
- recently_done: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` selected a bounded passive UVM monitor skeleton package as the first SV/UVM output target derived from shipped `verification_observations[]`. The selected contract permits inert UVM 1.2 snapshot item and monitor class declarations only; it defers DUT sampling, `run_phase`, virtual interfaces/config DB, transaction publication, assertions/properties, coverage, agents/envs/tests, scoreboards, reusable VIP, VHDL output, direct IAL2 routing, and every public emission surface to `.7`.
- in_flight_uncommitted: none. Ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: none.
- next_action: Start `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7`: select the public CLI, artifact layout, report/manifest, support-accounting, and validation gates for the selected passive UVM monitor skeleton before any verification-code-generation behavior changes.

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
