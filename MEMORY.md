# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.450: ship dynamic issue-order metadata`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.451` selects the next dynamic same-ID policy slice after dynamic issue-order queue metadata-first support; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.450` shipped metadata-first parser/report support for `dynamic-id-reuse issue-order-queue`, added `ppif/axi_manager_capacity_status_dynamic_same_id_issue_order_queue_policy.ppif` as a support-accounted public sample, reported selected-not-generated issue-order metadata with `dynamic_per_id_issue_order_queues` residue, kept dynamic `scoreboard`, generated dynamic queues, accepted reuse, HDL, VHDL, direct backend, and backend-language variants deferred, and selected `.451`. Syntax checks, guarded new-sample schedule/check/semantic probes, guarded focused dynamic sample test, guarded support-accounting test, Knowledge Map generation/check, mdBook build, docs path audit, memory architecture check, diff check, and doctrine gate passed; a guarded full `t/1437` attempt was inconclusive after manual stop at 18 minutes despite TAP reporting all 77 subtests passed before termination.
- in_flight_uncommitted: none. Ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: none.
- next_action: Start `.451`: select the next exact dynamic same-ID policy owner after `.450`, choosing between dynamic scoreboard contract/readiness, generated dynamic issue-order queue readiness, report cleanup, direct backend boundary, backend-language/VHDL prerequisite, or another narrower post-metadata slice.

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
