# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit
  (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7.1: confirm transaction type-binding blocker`).
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE`; `.7` is an
  active container, `.7.1` audit is complete, and `.7.2` is blocked.
- current_state: the checked fixture cannot bind under decision `0036`'s exact
  type-equivalence rule. Three transaction drive fields cross VIAL semantic
  types into different HIAL hardware carrier types; no binder was written.
- next_action: obtain the director's `.7.2` choice between exact cross-boundary
  type identity and the recommended proof-carrying directional representation
  adapter; synchronize all contracts/decision/book before `.7.3` implementation.
- in_flight_uncommitted: none after this audit commit; no background job and
  repository-local mdBook output was removed exactly.
- blockers: `.7.2` needs the director's semantic choice. Proposed
  `CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC.1` separately owns
  pre-existing t370 discovery-map drift.

## Durable context

- `docs/VIAL_HIAL_TYPE_BINDING_MISMATCH_AUDIT.md` proves `transfer` enum versus
  logic, `write` two-state Boolean versus four-state logic, and `wait_cycles`
  two-state unsigned versus four-state logic. Address/size/data and sampled
  endpoints/probe match.
- Recommended `.7.2` rule: known two-state same-width/signed values inject into
  four-state carriers with all-known/no-Z bits; enums inject through exact base
  encoding. No inverse X/Z collapse, width/sign change, or implicit coercion.
- Decision `0034`: VIAL is not synthesis-bounded. Qualified SV/UVM/VHDL
  targets relate to VIAL as assembly relates to C/C++ or Rust: full power
  underneath, simpler authored verification intent above.
- Decision `0035`: bridge v1 accepts direct IAL0, direct IAL1, or IAL2 only
  through generated/reparsed IAL1 and generated IAL0 review artifacts.
- Decision `0036`: target-neutral ExecutionIR uses exact drive/sample/react/
  check time, plan-time keyed SHA-256 randomness/replay, and declarative native
  artifacts; its cross-boundary type relation now requires `.7.2` amendment.
- Private `FSM::HIAL::VIALBridge::{Builder,Manifest,Report}` exposes immutable,
  defensive JSON-safe data and writes no file. The bridge correctly preserves
  HIAL scalar ports as four-state logic.
- `.5` historically proved endpoint type/access plus transaction ID/order, but
  did not compare every VIAL transaction field type to its bridge field type;
  `.7.1` narrows that overbroad claim durably.
- `.7` activation commit is `3ec8eab93824c7639ca25c96b3a2021cdf70239c`.
- Decisions `0025` freezes legacy status files. Push only on explicit request
  (`0005`); PNT runs autonomously (`0003`). Consult the Knowledge Map first.
