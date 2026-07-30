# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.1: activate architecture audit`).
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.1`
  (active architecture audit; continuity-only activation complete).
- current_state: clean parent selector `031b21d4f` activates only the HIAL/VIAL
  architecture audit; no architecture finding or product behavior changed.
- next_action: execute `.1`: audit the live hardware/verification stack and AHB
  fixture, decide the architecture, then create exact implementation leaves.
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
  standard, FSMGen-owned token registries/probes, checker, and seventh doctrine.
  `.843` adds `TASK-TREE-INTEGRITY` as the eighth registered doctrine.
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
- Decisions `0028`-`0031` and the private HIR records remain canonical. HIAL/
  VIAL `.1` is active for architecture audit only; public builder,
  whole-product scale, MCP-write, and every director-gated owner remain
  proposed/inactive.
- Live ledger is 844 numbered nodes / 844 unique root references. `.73` is
  canonical `done`; `.705` is live `done` after `.706`-.709; `.758` has its
  canonical commit field. The checker reports one active tree / 845 total nodes.
- `.843` verification: t1549 `Files=1, Tests=11`; docs audits `Files=3,
  Tests=40`; all 36 mdBook chapters and 72-file / 16,665,035-byte build pass;
  Knowledge Map is current at 1,084 facts / 5,589 keys; all output is removed.
- `.844` selection verification: one active tree / 845 nodes; docs `Files=3,
  Tests=40`; 36 chapters and 72-file / 16,670,326-byte build; Knowledge Map
  1,085 facts / 5,594 keys; exact outputs removed.
- HIAL/VIAL `.1` activation: two active trees / 847 nodes; docs `Files=3,
  Tests=40`; 36 chapters and 72-file / 16,671,894-byte build; Knowledge Map
  1,085 facts / 5,594 keys; exact output removed.
- Decision `0027`, the audit, fact card, user docs, task tree, changelog, and
  Knowledge Map are aligned. The repository-local mdBook scratch is removed.
- Push only on explicit request (decision `0005`). PNT runs autonomously
  (decision `0003`). Consult `KNOWLEDGE_MAP.md` before re-deriving durable facts.
