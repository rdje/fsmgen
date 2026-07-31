# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit
  (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7: activate VIAL execution implementation`).
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE`; `.7` is
  active for private no-backend implementation.
- current_state: decision `0036` selects target-neutral ExecutionIR/logical-
  time/random-replay/native/plan/result/parity semantics; this commit activates
  implementation continuity only. VIAL remains unbound.
- next_action: implement the selected private binder, immutable ExecutionIR,
  deterministic random/replay, defensive plan/result schema support, and
  focused oracles under active `.7`, with no target backend.
- in_flight_uncommitted: none after this activation commit; no background job
  and repository-local mdBook output was removed exactly.
- blockers: none for `.6`. Proposed
  `CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC.1` separately owns
  pre-existing t370 discovery-map drift; it does not block bridge completion.

## Durable context

- Decision `0034`: VIAL is not synthesis-bounded. Qualified SV/UVM/VHDL
  targets relate to VIAL as assembly relates to C/C++ or Rust: full power
  underneath, simpler authored verification intent above.
- Decision `0035`: bridge v1 accepts direct IAL0, direct IAL1, or IAL2 only
  through generated/reparsed IAL1 and generated IAL0 review artifacts. PPIF
  AST/report data cannot feed the bridge directly.
- Decision `0036`: ExecutionIR is a target-neutral operation graph with exact
  drive/sample/react/check time. Random values are fixed at plan time through
  keyed SHA-256 rejection/replay; native implementations are declarative typed
  artifacts, never Perl callbacks or UVM/VHDL lifecycle vocabulary.
- Private `FSM::HIAL::VIALBridge::{Builder,Manifest,Report}` exposes immutable,
  defensive, JSON-safe 27-key manifest data and writes no file. Public
  embedding/tooling remains `.8`; binding/execution remains `.6`/`.7`.
- The base AHB generator emits additive `(verification-bridge ...)` protocol,
  transaction/event, probe, and residue metadata. Generated IAL1 is 4,174
  bytes / SHA-256 b0f3446874367787d0dd134701ff9e89a3b24af6ef9c03d6eb9dc484093f9e4c.
- Generated IAL0 remains 5,854 bytes / SHA-256
  3d8fa7ac7c3a7f2c9ca063aca2cf707106b511219243d8b277ac3e2e8cf47bcf;
  direct normalized-date SV and exact VHDL preservation hashes also pass.
- The scalar-only profile leaves transaction `type_id` null and uses field
  type IDs; bridge events use a closed backend-neutral canonical expression
  record because the public IAL1 report has no reusable expression AST.
- `.7` activation closeout: trees=2/nodes=865; docs Files=4/Tests=51; all 37
  chapters test; build 73 files/17,011,689 bytes; Knowledge Map 1,090 facts/
  5,658 keys; Memory/diff/docs-only acceptance/all doctrines/cleanup pass. No
  binding/file/backend/runtime/parity behavior is claimed.
- Guarded wider AHB verification stopped at 88.1% host use without a test
  failure; no unfinished broad-suite pass is claimed. t370 is durably parked.
- Decisions `0025` freezes legacy status files. Push only on explicit request
  (`0005`); PNT runs autonomously (`0003`). Consult the Knowledge Map first.
