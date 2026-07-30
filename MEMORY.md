# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit (`ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.3: activate AXI assertion expectation sync`).
- active_work_unit: `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.3`
  (continuity-only activation).
- current_state: clean identifier completion commit `299db4cae` activates only
  the test-truth repair; assertion generation, emitted AXI HDL, runtime
  behavior, and t1502 expectations remain unchanged during activation.
- next_action: reproduce t1502 line 293, update only its stale pre-grouping
  exact assertion-text regex to the grouped output shipped by commit
  `80aa203ab`, then run focused AXI/assertion preservation gates.
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
- The unrelated t1502 expectation drift is durably owned by proposed inactive
  `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.3`; it is not folded into the
  identifier implementation.
- Decision `0027`, the audit, fact card, user docs, task tree, changelog, and
  Knowledge Map are aligned. The repository-local mdBook scratch is removed.
- Push only on explicit request (decision `0005`). PNT runs autonomously
  (decision `0003`). Consult `KNOWLEDGE_MAP.md` before re-deriving durable facts.
