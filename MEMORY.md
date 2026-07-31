# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit
  (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7.3: implement private VIAL execution plan`).
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE`; `.7` and
  implementation leaf `.7.3` are complete. Proposed `.8` is the next frontier.
- current_state: the private exact-class binder now produces immutable
  target-neutral ExecutionIR and a defensive in-process plan from checked VIAL
  SemanticIR plus the review-routed HIAL bridge. No backend/runtime ships.
- next_action: from the clean `.7.3` implementation commit, activate only `.8`
  for public VIAL CLI/API, repository-local artifact, manifest/report,
  capability, diagnostic, support-accounting, and compatibility selection.
- in_flight_uncommitted: none after this implementation commit; no background
  job and repository-local mdBook output is removed exactly.
- blockers: none for proposed `.8`. Proposed `CAPABILITY-MANIFEST-
  VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC.1` separately owns pre-existing t370
  discovery-map drift.

## Durable context

- `.7.3` ships private `FSM::VIAL::{ExecutionBuilder,ExecutionIR,
  ExecutionRandom,ExecutionReport}` plus exact capability discovery. It writes
  no file and exposes no supported public embedding API.
- The checked AHB plan has 21 operations, four total fibers, three maximum
  simultaneous fibers, ten directional relations, 22 bindings, two scalar
  state cells, scoreboard capacity four, and two materialized coverage bins.
- Version 1 admits only `bit_domain_identity_v1`, drive-only
  `known_value_injection_v1`, and drive-only `enum_encoding_injection_v1`.
  Four-state-to-two-state sampling, X/Z collapse, width/sign change, implicit
  enum decode, and broader coercion fail before plan construction.
- Events bind through logical transaction-adapter inputs and opaque adapter
  state; raw actor storage and HDL literal spelling do not enter ExecutionIR.
- Random choices use arbitrary-width `sha256_counter_rejection_v1`; strict
  replay validates identity, type, distribution, normalized value, range, and
  authored constraints before plan construction.
- Result-manifest and parity-report schemas are selected future contracts with
  explicit `.10`/`.11` owners, not satisfied `.7.3` capabilities.
- Decision `0034`: VIAL is not synthesis-bounded. Qualified SV/UVM/VHDL
  targets relate to VIAL as assembly relates to C/C++ or Rust: full power
  underneath, simpler authored verification intent above.
- Decision `0035`: bridge v1 accepts direct IAL0, direct IAL1, or IAL2 only
  through generated/reparsed IAL1 and generated IAL0 review artifacts.
- Decision `0036`: target-neutral ExecutionIR uses exact drive/sample/react/
  check time; decision `0037` supplies its directional type-binding seam.
- Private `FSM::HIAL::VIALBridge::{Builder,Manifest,Report}` exposes immutable,
  defensive JSON-safe data and writes no file. The bridge correctly preserves
  HIAL scalar ports as four-state logic.
- Focused/adjacent execution evidence passes at Files=10/Tests=7135. The known
  t370 failure is unrelated verification-output presence-map drift.
- Decisions `0025` freezes legacy status files. Push only on explicit request
  (`0005`); PNT runs autonomously (`0003`). Consult the Knowledge Map first.
