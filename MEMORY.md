# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit
  (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.5: activate bridge manifest implementation`).
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.5`
  (private in-process/no-file bridge-manifest implementation).
- current_state: clean contract commit `0366dfe30` completes `.4`; this
  continuity transition activates only `.5`. No parser, generated-IAL1
  annotation, bridge object/report, artifact, HIAL output, VIAL binding, or
  runtime has changed.
- next_action: implement the selected bounded review-routed bridge producer,
  report, generated/reparsed IAL1 annotation, exact t1551 evidence, and
  capability/support accounting without adding a public file/API or binding.
- in_flight_uncommitted: none after this activation commit; no background job.
- blockers: none. The separately proposed t261/t296 oracle repairs remain
  outside this task tree and do not alter the bridge contract.

## Durable context

- Decision `0032`: one public VIAL source, private SemanticIR/ExecutionIR, and
  a versioned HIAL bridge. Decision `0033`: dedicated spanned VIAL source and
  typed semantic records. `.3` ships the semantic-only first profile.
- Decision `0034`: VIAL is not synthesis-bounded. Qualified SV/UVM/VHDL
  targets relate to VIAL as assembly relates to C/C++ or Rust: full power
  underneath, simpler authored intent above.
- Decision `0035`: bridge v1 accepts direct IAL0, direct IAL1, or IAL2 only
  through generated/reparsed IAL1 and generated IAL0 review artifacts. PPIF
  AST/report data may not feed the bridge directly.
- Generated IAL1 `(verification-bridge ...)` metadata carries protocol,
  domain, transaction/event, probe, and residue meaning without scheduling
  hardware behavior. Exact AHB IDs match the checked `.vial` source.
- `core_single_unit_v1` selects stable semantic IDs, normalized four-state
  scalar types/values, backend name bindings, full field source maps, honest
  semantic-path provenance, defensive immutable data, diagnostics, and caps.
- Active `.5` exposes private in-process build/report only and writes no bridge
  file. VIAL binding/ExecutionIR remains `.7`; public CLI/API/artifact
  discovery remains `.8`; backend runtime/parity remains later.
- `.4` selection closeout: evidence Files=3 / Tests=21; trees=2 / nodes=865;
  docs Files=4 / Tests=42; 37 chapters and 73-file / 16,930,263-byte local
  build; Knowledge Map 1,088 facts / 5,640 keys; doctrines and cleanup pass.
- `.5` activation closeout: trees=2 / nodes=865; docs Files=4 / Tests=42;
  37 chapters and 73-file / 16,932,359-byte local build; Knowledge Map 1,088
  facts / 5,640 keys; doctrines and cleanup pass; implementation is unperformed.
- `SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC` owns stale
  t261 unary-shape expectations. `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT`
  owns t296's pipeline-versus-CLI top-name conflation.
- Decisions `0028`-`0031` remain canonical for SourceHIR/IR policy. Public
  builder, whole-product scale, MCP-write, and director-gated owners remain
  separately proposed/inactive.
- Decision `0025` freezes both legacy status files. Push only on explicit
  request (`0005`); PNT runs autonomously (`0003`). Consult the Knowledge Map
  before re-deriving durable facts.
