# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit (`BIN-FSMGEN-IMPORT-TREE-JUL30-IDENTIFIER-REFRESH.1: activate identifier import-map refresh`).
- active_work_unit: `BIN-FSMGEN-IMPORT-TREE-JUL30-IDENTIFIER-REFRESH.1`
  (continuity-only activation).
- current_state: the exact identifier-era import-map task tree now owns the
  measured 229-file / 228-package / 19-IAL2 note/fact synchronization; the
  stale canonical baseline is deliberately unchanged during activation.
- next_action: remeasure the live closure, synchronize only the canonical
  import-tree note/fact and continuity docs, validate, and commit `.1`.
- in_flight_uncommitted: none after this activation commit; no background job.
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
- Startup remeasurement after the identifier implementation reports 229
  project files / 228 packages / 19 IAL2 owners; selection must reconcile that
  live closure against the saved 228 / 227 / 19 import-tree baseline.
- Chapter 16c still says counts beyond four are outside the shipped surface,
  contradicting its current canonical literal 2..16 sections; the next parent
  selector must preserve or select that independent documentation repair after
  import-map synchronization.
- Decision `0027`, the audit, fact card, user docs, task tree, changelog, and
  Knowledge Map are aligned. The repository-local mdBook scratch is removed.
- Push only on explicit request (decision `0005`). PNT runs autonomously
  (decision `0003`). Consult `KNOWLEDGE_MAP.md` before re-deriving durable facts.
