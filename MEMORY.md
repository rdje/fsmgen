# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit (`FSMGEN-HIR-ROADMAP-FRONTIER.5: keep SourceHIR private through IAL1 proof`).
- active_work_unit: `FSMGEN-HIR-ROADMAP-FRONTIER.6` (proposed; not active).
- current_state: `.5` retains the healthy private IAL2 valid-ready prototype;
  decision `0029` defers promotion until a concrete-control-to-IAL1 proof and
  keeps public builder ownership separate.
- next_action: after this audit commit is clean, activate `.6` continuity-only
  to select the exact private concrete-control-to-IAL1 boundary and golden.
- in_flight_uncommitted: none after this audit commit; no background job.
- blockers: none.

## Durable context

- Director direction (`2026-07-30`) is implemented by decision `0025`:
  `CHANGES.md` updates every slice, `DEVELOPMENT_NOTES.md` only when warranted,
  and `ROADMAP_STATUS.md` plus `LIVE_ACHIEVEMENT_STATUS.md` remain untouched.
  Proposed `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1` owns their later
  four-file lifecycle discussion.
- The quoted June TASK-ACCEPTANCE non-port statement is stale. Decision `0026`
  and completed `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.1`-.3 ship the neutral
  standard, FSMGen-owned token registries/probes, checker, and seventh-doctrine
  integration.
- Identifier implementation verification: t1546 `Files=1, Tests=7`; full APB
  t1472 `Files=1, Tests=101`; focused AHB/library/ATL/composition/emitter
  preservation tests pass; ten changed Perl/test files report `syntax OK`.
  All 36 mdBook chapters pass test/build; documentation audits pass at
  `Files=3, Tests=40`; Knowledge Map passes at 1,072 facts / 5,523 keys.
- `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.3` is complete: t1502 passes at
  `Files=1, Tests=4`; t1410-t1412+t1544 pass at `Files=4, Tests=22`; test syntax
  is clean, and `.artifacts/tmp/tests` is empty.
- The identifier-era import-map baseline is current at 229 project files / 228
  packages / 19 IAL2 owners and Support 71.
- The Chapter 16c counts-beyond-four contradiction is resolved through clean
  documentation commit `3fb84b23e` without behavior/accounting changes.
- Decisions `0028`/`0029`, the architecture/audit records, and v1 contract are
  canonical. `.6` remains proposed; public builder, HIAL/VIAL, scale,
  MCP-write, and every director-gated owner remain inactive.
- Decision `0027`, the audit, fact card, user docs, task tree, changelog, and
  Knowledge Map are aligned. The repository-local mdBook scratch is removed.
- Push only on explicit request (decision `0005`). PNT runs autonomously
  (decision `0003`). Consult `KNOWLEDGE_MAP.md` before re-deriving durable facts.
