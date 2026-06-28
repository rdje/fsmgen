# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the full system. This file is ONLY the bounded
resume pointer: current state + the single next action. Never append to it; its
prior 38,776-line history is preserved in git (recoverable via `git log -- MEMORY.md`).

## How to resume (any model, any harness)
- Read `README.md` (project) and `MEMORY_ARCHITECTURE.md` (the memory system — MANDATORY).
- Work is tracked in task-trees under `docs/tasks/` (index `docs/TASK_TREE.md`); commit per `COMMIT.md`.
- Durable cross-cutting facts/decisions live in `docs/decisions/` (index `docs/decisions/INDEX.md`).
- Before committing, run `scripts/check_memory_architecture.sh` (git hooks + CI run it too).

- latest_commit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.615: ship APB sideband composition back-to-back`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.616` is active after `.615`; audit the next APB sideband-aware back-to-back timing-policy owner after fixed composition shipped.
- recently_done: `IAL2-FEATURE-COMPLETENESS-FRONTIER.615` shipped the selected bounded APB sideband-aware completer and fixed-composition back-to-back contract. The new public sources are `ppif/apb_completer_sideband_back_to_back.ppif`, `ppif/apb_completer_sideband_back_to_back.apb`, `ppif/apb_composition_sideband_status_back_to_back.ppif`, and `ppif/apb_composition_sideband_status_back_to_back.apb`. The sideband completer accepts adjacent setup for the one-register 32-bit family with `PPROT width 3` and `PSTRB width 4`; the fixed composition combines the `.612` sideband requester queue with that completer and sideband-aware wiring. Reports remove broad `apb_back_to_back_policy_deferred` for the selected sideband completer and fixed-composition surfaces and retain narrowed future-policy residue. Sideband multi-peripheral timing propagation, data16/protection variants, multi-register timing policy, deeper queues, alternate overflow, accepted-less requesters, multiple active APB transfers, direct backend, verification-output, backend-language variants, AXI, AHB, and VHDL remain deferred.
- in_flight_uncommitted: none. Ignored local-only mirrors remain at `.cache/local-references/accellera/uvm/uvm-1.2`, `.cache/local-references/sv/1800-2017`, and `.cache/local-references/sv/1800-2023`.
- blockers: The original exact `t/301` resource cliff is fixed for oversized PPIF check-json via `.2.3.1`, but a full guarded `t/301-check-json-supported-corpus.t` rerun stopped on host-memory cutoff from a high host baseline and a higher-cutoff retry was rejected by the approval layer. Do not bypass that rejection without explicit user approval; `.2.5` selected RAM-guarded or exact bounded replacement policy for any future broad `t/301`/`t/303` parity plan. During `.569`, broad `t/1436-ial2-ppif-parser-cli.t` attempts were not used as closeout: the APB-relevant focused tests and direct probes passed, but the broad run sat in an unrelated AXI subprocess/pipe wait after all visible subtests had passed.
- next_action: Execute `.616`: read `.615` behavior, `.614` contract, `.613` readiness audit, `.612` requester behavior, `.609` multi-peripheral behavior, APB sideband/data16/protection behavior docs, current APB reports/residue, generators, support catalog, language surface, focused tests, README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and relevant decisions; decide whether the next exact owner is sideband multi-peripheral timing propagation, data16/protection timing variants, multi-register timing policy, queue policy broadening, or explicit deferral; do not change parser/generator/sample/support/report/HDL behavior in `.616`.

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
