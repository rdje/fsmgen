# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit (`ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.3: synchronize grouped AXI assertion expectation`).
- active_work_unit: none after this completion commit; the assertion repair
  tree is exhausted through `.3`.
- current_state: t1502 now freezes the grouped AXI write-request coordinator
  implication emitted since `80aa203ab`; product assertion generation,
  generated HDL, and runtime behavior are unchanged.
- next_action: from this clean boundary, select the next parent
  `IAL2-FEATURE-COMPLETENESS-FRONTIER` leaf before any further behavior work.
- in_flight_uncommitted: none after commit; no background job.
- blockers: none. A confirmatory guarded preservation rerun was stopped before
  test execution because host memory was 95.4% above the configured 88% cutoff;
  the same focused preservation files had already passed in this slice.

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
- Decision `0027`, the audit, fact card, user docs, task tree, changelog, and
  Knowledge Map are aligned. The repository-local mdBook scratch is removed.
- Push only on explicit request (decision `0005`). PNT runs autonomously
  (decision `0003`). Consult `KNOWLEDGE_MAP.md` before re-deriving durable facts.
