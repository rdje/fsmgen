# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit
  (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.3: activate VIAL semantic implementation`).
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.3`
  (active bounded VIAL v1 parser/SemanticIR implementation).
- current_state: clean contract commit `08f59167b` selects decision `0033` and
  activates only `.3` through this continuity transition; parser/source/report/
  capability/support/test implementation and product behavior remain unchanged.
- next_action: implement exactly four `FSM::VIAL` packages, the selected AHB
  `.vial` source, immutable typed semantic intent, defensive semantic report,
  deterministic diagnostics/limits/negative corpus, capability/support
  accounting, and focused t1550; emit no bridge/plan/backend/runtime artifact.
- in_flight_uncommitted: none after this activation commit; no background job.
- blockers: none.

## Durable context

- Decision `0032`: one public VIAL source, private SemanticIR/ExecutionIR, and
  a versioned HIAL bridge. Decision `0033`: dedicated span-aware S-expression
  parser and typed semantic records, not raw Lispish arrays.
- VIAL v1 reuses canonical `=>`/`next`/`within`; four-state values normalize
  to value/known/Z masks; `same` is exact and `value_eq` requires known values.
- `.3` may claim parse/typecheck/sanitized semantic report only. Bridge
  binding, plans, outputs, runtime, parity, UVM, VHDL, mixed-language, and
  scale remain explicit non-claims.
- `.3` activation closeout: two active trees / 864 nodes; docs
  `Files=3, Tests=40`; 37 chapters and 73-file / 16,845,901-byte build;
  Knowledge Map 1,086 facts / 5,617 keys; output removed.
- Existing inert UVM 1.2 and VHDL observation outputs remain compatibility
  surfaces. IAL2 facts still require generated-IAL1 reviewable annotation;
  direct `.ppif` verification output remains unsupported.
- Decisions `0028`-`0031` remain canonical for SourceHIR/IR policy. Public
  builder, whole-product scale, MCP-write, and director-gated owners remain
  separately proposed/inactive.
- Decision `0025` freezes both legacy status files. Push only on explicit
  request (`0005`); PNT runs autonomously (`0003`). Consult the Knowledge Map
  before re-deriving durable facts.
