# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit
  (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7.3: activate bounded VIAL execution implementation`).
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE`; `.7` is an
  active container, `.7.1` audit and `.7.2` selection are complete, and `.7.3`
  is active for private no-backend implementation.
- current_state: director-approved decision `0037` resolves the VIAL-semantic-
  to-HIAL-carrier seam with closed compiler-proved directional relations. This
  commit activates implementation continuity only; no binder exists yet.
- next_action: establish fresh `.7.3` task-acceptance root-cause evidence, then
  implement the selected private binder, immutable ExecutionIR, deterministic
  random/replay, defensive plan/result support, and focused no-backend oracles.
- in_flight_uncommitted: none after this activation commit; no background job
  and repository-local mdBook output was removed exactly.
- blockers: none for active `.7.3`. Proposed `CAPABILITY-MANIFEST-
  VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC.1` separately owns pre-existing t370
  discovery-map drift.

## Durable context

- Decision `0037` keeps VIAL semantic types and HIAL hardware carrier types
  independently authoritative. Binding records stable IDs and closed proofs;
  target casts or caller-asserted compatibility are forbidden.
- Version 1 admits only `bit_domain_identity_v1`, drive-only
  `known_value_injection_v1`, and drive-only `enum_encoding_injection_v1`.
  Four-state-to-two-state sampling, X/Z collapse, width/sign change, implicit
  enum decode, and broader coercion fail before plan construction.
- The checked AHB transaction uses identity for address/size/data, enum
  injection for transfer, and known-value injection for write/wait_cycles;
  sampled outputs/probe use identity and the probe adapter remains required.
- Decision `0034`: VIAL is not synthesis-bounded. Qualified SV/UVM/VHDL
  targets relate to VIAL as assembly relates to C/C++ or Rust: full power
  underneath, simpler authored verification intent above.
- Decision `0035`: bridge v1 accepts direct IAL0, direct IAL1, or IAL2 only
  through generated/reparsed IAL1 and generated IAL0 review artifacts.
- Decision `0036`: target-neutral ExecutionIR uses exact drive/sample/react/
  check time, plan-time keyed SHA-256 randomness/replay, and declarative native
  artifacts; decision `0037` supplies its directional type-binding seam.
- Private `FSM::HIAL::VIALBridge::{Builder,Manifest,Report}` exposes immutable,
  defensive JSON-safe data and writes no file. The bridge correctly preserves
  HIAL scalar ports as four-state logic.
- `.5` historically proved endpoint type/access plus transaction ID/order, but
  did not compare every VIAL transaction field type to its bridge field type;
  `.7.1` narrows that overbroad claim durably.
- `.7` activation commit is `3ec8eab93824c7639ca25c96b3a2021cdf70239c`.
- Decisions `0025` freezes legacy status files. Push only on explicit request
  (`0005`); PNT runs autonomously (`0003`). Consult the Knowledge Map first.
