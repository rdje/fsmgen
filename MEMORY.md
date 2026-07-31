# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit
  (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.2: select spanned VIAL semantic contract`).
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.3`
  (proposed exact VIAL v1 parser/SemanticIR implementation; selected, inactive).
- current_state: `.2` is complete under decision `0033`; the closed spanned
  `.vial` v1 grammar, `core_directed_single_clock_v1`, types/four-state masks,
  declarations/fixture semantics, private immutable `VIALSemanticIR`,
  defensive report/diagnostics, first AHB source, limits, negatives, and exact
  `.3` packages/source/t1550 ownership are selected without behavior changes.
- next_action: after this clean commit, activate only proposed `.3` through a
  separate continuity commit; then implement exactly the selected bounded
  parser, builder, IR, report, AHB source, support/capabilities, and t1550.
- in_flight_uncommitted: none after this commit; no background job.
- blockers: none for `.3`; later bridge/UVM/VHDL/mixed-language leaves retain
  their separately recorded prerequisites.

## Durable context

- Decision `0032`: one public VIAL source, private SemanticIR/ExecutionIR, and
  a versioned HIAL bridge. Decision `0033`: dedicated span-aware S-expression
  parser and typed semantic records, not raw Lispish arrays.
- VIAL v1 reuses canonical `=>`/`next`/`within` property operators; four-state
  values normalize to value/known/Z masks; `same` is exact and `value_eq`
  requires known values.
- `.3` may claim parse/typecheck/sanitized semantic report only. Bridge
  binding, plans, outputs, runtime, parity, UVM, VHDL, mixed-language, and
  scale remain explicit non-claims.
- Contract closeout: two active trees / 864 nodes; docs `Files=3, Tests=40`;
  paths `Files=1, Tests=2`; 37 chapters and 73-file / 16,842,038-byte build;
  Knowledge Map 1,086 facts / 5,617 keys; exact output removed.
- Existing inert UVM 1.2 and VHDL observation outputs remain compatibility
  surfaces. IAL2 verification facts still require generated-IAL1 reviewable
  annotation; direct `.ppif` verification output remains unsupported.
- Decisions `0028`-`0031` remain canonical for SourceHIR/IR policy. Public
  builder, whole-product scale, MCP-write, and director-gated owners remain
  separately proposed/inactive.
- Decision `0025` freezes both legacy status files. Push only on explicit
  request (`0005`); PNT runs autonomously (`0003`). Consult the Knowledge Map
  before re-deriving durable facts.
