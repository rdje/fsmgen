# 0081 — Portable SystemVerilog direct drive uses root-owned zero-duration driver slots

- Date: 2026-08-24
- Type: verification backend/runtime drive semantics
- Status: accepted by `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.2`
- Refines: [0036](0036-vial-execution-is-deterministic-logical-time-above-backend-methodology.md), [0043](0043-vial-portable-systemverilog-is-a-deterministic-known-value-profile.md), [0080](0080-portable-systemverilog-rolls-backward-successors-by-logical-phase.md)
- Implementation owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.2`

## Context

Ordinary VIAL source added a public input endpoint for the checked HIAL `HSEL`
carrier and authored `(drive select #b1)`. Parsing, bridge construction, and
planning succeeded. ExecutionIR retained a `drive` operation, a normalized
one-bit value, `eligible_phase=drive`, and one `update_driver` effect, but that
effect had no target because `ExecutionBuilder::_action_target` did not project
`endpoint_id`. Portable negotiation nevertheless succeeded, and the emitted
operation task contained only `vial_inactive_barrier()`—no endpoint assignment
and no `drives` trace record.

The omission made the advertised direct action inert and also classified it as
cycle-consuming. Repair requires one coherent rule across binding, immutable
intent, backend negotiation, emitted scheduling, trace validation, result
projection, finalization, source mapping, and support accounting. Target-name
matching or a trace-only patch would conceal rather than implement the effect.

Generic ExecutionIR permits an input or inout carrier with a proved drive
relation. This first portable backend has one procedural driver slot and no
resolved inout/multiple-driver policy. Its parallel renderer also does not yet
provide a generally qualified scheduler for arbitrary child-operation kinds.
Those backend limitations must remain explicit rather than being inferred from
the broader target-neutral contract.

## Decision

1. Project a direct action's semantic `endpoint_id` as the exact
   `update_driver.target_id`. Binding discovers direct endpoint use from the
   action itself, not only from expression-reference nodes. A probe or
   sample-only endpoint therefore fails binding before ExecutionIR is
   published.
2. Independently renegotiate every direct operation before artifacts. Require
   one exact update effect, one execution endpoint binding, one public bridge
   endpoint, one drive relation, one declared portable-SystemVerilog port
   binding, and byte-exact normalized scalar type, width, value, known, and Z
   masks. The portable profile accepts only an `input` carrier; inout direct
   drive remains an explicit non-claim until a resolved-driver policy is
   selected and qualified.
3. A root-fiber direct drive is a zero-duration operation in logical `drive`.
   Its generated task sets the operation's static rank, assigns the exact
   normalized literal to the bound port, and emits one `drives` record carrying
   the owning operation ID, bridge endpoint ID, null transaction-field ID, and
   immutable effective value. It does not traverse a barrier inside the task.
4. Same-fiber direct drives retain authored/static-rank order within the same
   drive slot. A following react or check operation traverses exactly one real
   inactive-edge sample barrier; scenario finalization does the same when the
   last operation is a drive. Backward crossings retain decision `0080`.
5. Multiple live sibling fibers writing one direct endpoint fail negotiation
   once with a deterministic scenario/endpoint conflict identity, regardless
   of value equality. All non-root direct drives fail closed in this profile;
   SystemVerilog process order is never used as a winner policy.
6. Each directly driven endpoint is restored once to the selected safe zero
   after the scenario's terminal fiber record and before `scenario_end`. This
   backend lifecycle write is not an authored semantic drive and therefore
   creates no second trace record. Its dedicated source-map entry closes over
   the exact execution binding, bridge endpoint, owning operation(s), and
   authored source location(s).
7. Trace validation treats a direct record as a claim about immutable intent.
   It independently requires the exact operation, bound endpoint, null
   transaction field, canonical effective value, drive-phase rank, static
   operation rank, local index zero, and semantic endpoint identity before the
   result producer may consume it.
8. Capability/support truth publishes `input_carrier_direct_drive_only` and
   `root_fiber_direct_drive_only`; the public execution contract retains
   `inout_direct_drive` and `non_root_direct_drive` as explicit non-claims. No
   scale, four-state, methodology, performance, capacity, or general-parity
   claim follows from this repair.

## Alternatives rejected

- **Keep the barrier and add only a trace record.** This fabricates an effect
  that the DUT never received.
- **Match the VIAL name directly to `HSEL`.** Names are not binding authority;
  only the execution/bridge/backend relation chain may select target text.
- **Let assignment width or SystemVerilog casts repair a mismatch.** That
  bypasses the directional proof relation and could truncate, extend, or
  reinterpret the value.
- **Treat every direct drive as cycle-consuming.** A scalar slot update is
  zero-duration; mandatory barriers would invent cycles and destroy legal
  same-phase ordering.
- **Resolve sibling conflicts by emitted order.** Live-fiber semantics cannot
  depend on host or target scheduling, even when the values match.
- **Claim inout or nested-fiber support speculatively.** The current backend
  lacks the required resolved-driver and general child-scheduler proofs; it
  fails closed until separately owned work supplies them.
- **Leave the last value asserted after scenario completion.** That leaks one
  scenario's driver state into later execution. A deterministic unrecorded
  lifecycle finalizer preserves isolation without inventing authored intent.

## Consequences and rollback

Generated source, source-map, trace, result, backend-manifest, and public
artifact identities change only for plans containing direct endpoint drives or
for the newly explicit limitation lists. Existing checked-AHB source has no
direct endpoint action and retains its semantic behavior. Direct-drive plans
now produce an observable DUT update, one validated result record, and a safe
final value with deterministic bytes.

Rollback is one atomic slice: revert target projection/direct-use binding,
backend negotiation, zero-duration rendering and phase transitions, trace
validation, safe-zero finalization/source mapping, support truth, and their
tests/docs together. Rolling back restores the executable RED and must also
withdraw any direct-drive support statement.

## Verification legs

- **Re-derivation:** the ordinary source route reconstructs the exact parser,
  bridge, binding, normalized value, operation/effect, backend port, generated
  task, source-map, trace, and result identities. History locates the missing
  target projection at the original action-target implementation.
- **Falsification:** preserved RED assertions reject the former barrier-only
  body. Hostile effect target, relation, value type, inout carrier, probe,
  sample-only endpoint, live-sibling conflict, forged trace endpoint/value/
  phase, and non-root topology all fail at their owning boundary without
  partial artifacts.
- **Durability:** focused ExecutionIR/emission/TraceValidator tests, the real
  qualified-Verilator public-Runner subtest, both contracts, the mdBook,
  Knowledge Map, owning task, this decision, and Git history retain the rule.
