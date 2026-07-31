# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit
  (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.3: implement VIAL semantic intent`).
- active_work_unit: none after `.3` closeout; parent
  `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE` remains active and `.4` is
  proposed/inactive.
- current_state: `.3` ships the bounded semantic-only `.vial` parser, validator,
  immutable `VIALSemanticIR`, sanitized report, checked AHB source, and exact
  support/capability accounting. It emits no bridge, plan, target artifact, or
  runtime result.
- next_action: from the clean `.3` commit, activate proposed `.4` in a separate
  continuity slice, unless a higher-priority clean-tree selection first chooses
  one of the two newly tracked regression-oracle repairs.
- in_flight_uncommitted: none after this implementation commit; no background
  job.
- blockers: none. Broader t261 and t296 failures are independently root-caused
  and durably proposed, not blockers or pass claims for `.3`.

## Durable context

- Decision `0032`: one public VIAL source, private SemanticIR/ExecutionIR, and
  a versioned HIAL bridge. Decision `0033`: dedicated span-aware S-expression
  parser and typed semantic records, not raw Lispish arrays.
- Decision `0034`: VIAL is not synthesis-bounded. It covers the expressive use
  cases of qualified SV/UVM/VHDL targets while hiding their plumbing; those
  targets relate to VIAL as assembly relates to C/C++ or Rust. Full power
  underneath, simpler intent above.
- VIAL v1 reuses canonical `=>`/`next`/`within`; four-state values normalize
  to value/known/Z masks; `same` is exact and `value_eq` requires known values.
- `.3` claims parse/typecheck/sanitized semantic report only. Bridge binding,
  plans, outputs, runtime, parity, UVM, VHDL, mixed-language, and scale remain
  explicit non-claims.
- `.3` closeout: trees=2 / nodes=865; focused Files=3 / Tests=7,055;
  adjacent Files=9 / Tests=32; docs Files=3 / Tests=40; paths Files=1 /
  Tests=2; 37 chapters and 73-file / 16,896,993-byte local build; Knowledge
  Map 1,087 facts / 5,631 keys; build output removed exactly.
- `SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC` owns stale
  t261 unary-shape expectations. `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT`
  owns t296's in-memory-entry versus CLI-aggregate top-name conflation.
- Existing inert UVM 1.2 and VHDL observation outputs remain compatibility
  surfaces. IAL2 facts still require generated-IAL1 reviewable annotation.
- Decisions `0028`-`0031` remain canonical for SourceHIR/IR policy. Public
  builder, whole-product scale, MCP-write, and director-gated owners remain
  separately proposed/inactive.
- Decision `0025` freezes both legacy status files. Push only on explicit
  request (`0005`); PNT runs autonomously (`0003`). Consult the Knowledge Map
  before re-deriving durable facts.
