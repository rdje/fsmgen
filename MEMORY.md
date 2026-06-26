# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.514: ship mixed queue read-data`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.515` audits raw-`ARLEN` burst-length readiness over generated mixed dynamic/static read burst-last same-ID issue-order queue read-data; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.514` shipped paired scalar read-data over generated mixed dynamic/static read same-ID `issue-order-queue` completions through two support-accounted PPIF samples. The implementation is bounded to exactly one dynamic read plus one concrete static read, one depth-2 generated mixed queue, no `burst_length` metadata, and queue-specific single-beat/last-beat completion-validity names. Syntax, guarded schedule JSON, support-accounting, and capability-manifest checks passed; strict/semantic and broad generator probes hit RAM-guard/stall caveats. Raw `ARLEN`, runtime validation, multi-beat output banks, broader mixed cardinality, scoreboards, backend behavior, backend-language variants, verification-code generation, external converter dependencies such as `sv2v`, and VHDL remain deferred.
- in_flight_uncommitted: none. Ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: none.
- next_action: Start `.515`: audit raw-`ARLEN` burst-length readiness over generated mixed dynamic/static read burst-last same-ID issue-order queue read-data before any further behavior change.

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
