# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.496: audit RLAST depth3 runtime readiness`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.497` implements runtime beat-count/RLAST validation over generated all-dynamic read burst-last RID/RLAST depth-3 same-ID issue-order queue raw-ARLEN read-data; `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` and `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` also remain active/pending.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.496` selected `.497`, direct bounded implementation of runtime beat-count/RLAST validation over the `.494` depth-3 dynamic RLAST queue raw-ARLEN read-data surface. The unmodified candidate failed closed at the local coverage diagnostic; a RAM-guarded out-of-tree one-line predicate overlay proved existing runtime helpers enumerate r0/r1/r2 expected-beat storage, read-beat counters, six rules, and twelve beat-count/RLAST assertion names. No parser, generator, PPIF sample, support accounting, generated artifact, report JSON, test, HDL/runtime behavior, external converter dependency such as sv2v, backend behavior, multi-beat behavior, arbitrary cardinality, or VHDL behavior changed.
- in_flight_uncommitted: none. Ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: none.
- next_action: Start `.497`: implement runtime beat-count/RLAST validation over depth-3 dynamic RLAST queue raw-ARLEN read-data; first update only the audited local coverage predicate, then add the support-accounted PPIF sample, focused tests, behavior docs, mdBook, Memory, task tree, and Knowledge Map. Preserve external converter dependencies such as sv2v, backend behavior, multi-beat output banks, mixed queues, arbitrary cardinality, and VHDL.

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
