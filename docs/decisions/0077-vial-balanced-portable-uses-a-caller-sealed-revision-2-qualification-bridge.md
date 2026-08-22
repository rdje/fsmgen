# 0077 — VIAL balanced portable uses a caller-sealed revision-2 qualification bridge

- Date: 2026-08-22
- Type: verification architecture/scalability
- Status: selected by `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.2.1`
- Refines: [0035](0035-hial-vial-bridge-is-produced-from-reviewable-hial-routes.md), [0043](0043-vial-portable-systemverilog-is-a-deterministic-known-value-profile.md), [0055](0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md), [0060](0060-vial-bridge-scale-uses-a-qualification-only-direct-ial1-profile.md), [0061](0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md)
- Implementation owners: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.2.2` through `.17.2.7.2.4`

## Context

Decision `0055` fixes one conservative `balanced_portable_v1` interaction
candidate with one unit/domain, 128 manifest endpoints, 16 transaction aliases,
128 events, 32 probes, and exactly 2,048 ExecutionIR bindings. The existing
portable AHB annotation admits only one six-field/six-event transaction. The
existing architecture-scale revision-1 annotation admits one transaction field
and is deliberately classified `qualification_only` / `private_nonportable` by
its private execution binder.

The binding formula is authoritative in `FSM::VIAL::ExecutionBuilder`:

```text
unit + domains + bound data endpoints + probes + transactions
+ transaction fields + event-input bindings + events
+ event adapter-state bindings
```

For the balanced source, clock/reset belong to the one domain rather than the
ordinary data-endpoint binding set. The closed shape therefore uses 126 data
endpoints, 32 probes, 16 transaction aliases, 128 events, no extra event-input
or adapter-state bindings, and 1,744 transaction fields:

```text
1 + 1 + 126 + 32 + 16 + 1,744 + 128 = 2,048
1,744 / 16 = 109 fields per transaction alias
```

Neither existing bridge contract can express that shape, and widening either
would silently change an already-qualified contract. The director authorized
the recommended separate revision-2 route on 2026-08-22 and required a
long-term, signoff-grade architecture rather than a test-only count shortcut.

## Decision

1. Preserve the checked AHB annotation, manifest identity, capability set, and
   public planning/backend behavior byte-for-byte. Preserve the revision-1
   architecture-scale profile and its private-nonportable classification.
2. Add one distinct direct-IAL1 qualification annotation:

   ```text
   protocol name: architecture_scale_probe
   profile:       balanced_portable
   revision:      2
   role:          verification
   exact facts:   scale_evidence_only = true
                  qualified_emitter = sv_portable_verilator
   capability:    hial_vial.bridge_qualification.balanced_portable_v2
   ```

   The manifest remains schema `fsmgen.hial_vial_bridge_manifest.v1` and
   profile `core_single_unit_v1`; revision 2 is an additive, private
   qualification protocol carried inside that already-versioned envelope.
3. Expose revision 2 only through a new bridge entrypoint caller-sealed to
   `FSM::VIAL::ArchitectureScaleBalancedPortable`. Public
   `Builder->build_ial1`, IAL0, and IAL2 routes reject the annotation. The
   sealed entrypoint must still parse ordinary `.isf`, consume its scheduler
   report, lower to reviewable `.fsm`, and call the canonical manifest builder;
   it accepts no caller-created actor, report, IR, manifest, or backend output.
4. Validate the complete semantic shape, not just counts: one direct
   `IAL1 -> IAL0` review route; one unit/domain; exactly 128 endpoints including
   clock/reset; 16 closed ordinal transaction aliases; 109 closed fields per
   alias; 128 closed ordinal events; 32 storage-backed read-only probes; exact
   field/endpoint type and direction agreement; and no extra event-input or
   adapter-state binding. Unknown metadata, reordered or duplicate identities,
   unreferenced records, or any cardinality change fails closed.
5. Add a separate ExecutionBuilder entrypoint caller-sealed to the same balanced
   composer. It alone admits the revision-2 capability. The public builder and
   the revision-1 scale binder reject it. Its capability-ledger record remains
   `qualification_only` and names portable SystemVerilog as its sole eligible
   structural backend; it is not a generally portable or public capability.
6. Portable-SystemVerilog emission must negotiate the revision-2 capability
   explicitly. Admission requires both the exact capability-ledger
   classification and an independently checked bridge/ExecutionIR shape. Adding
   the capability string to a generic allow-list is insufficient. Other
   backends, direct emitter calls with altered evidence, and all unsupported
   shapes fail before artifact construction.
7. `FSM::VIAL::ArchitectureScaleBalancedPortable` is the sole composition
   authority. It generates ordinary HIAL/VIAL source, obtains fresh successful
   gate evidence from all six orthogonal families, regenerates every canonical
   stage independently, and proves the full decision-`0055` count vector. It
   cannot accept injected SemanticIR, bridge, ExecutionIR, backend inputs,
   artifacts, gate reports, or count overrides.
8. Structural emission is the end of this leaf. No external compiler or runtime
   is executed; no trace/result is materialized; and no support, performance,
   capacity, reached-boundary, protocol, public API, or general portability
   claim is added. Measurement remains `.17.3`; promotion remains `.17.5`.
9. All generated material stays below the repository-derived VIAL scale staging
   root and is removed exactly after success and consumer failure. Reports are
   closed, defensive, content-addressed, path-independent, and byte-equal on
   independent rerun.

## Claim verification

- Re-derivation: the shipped `ExecutionBuilder` resource formula plus the
  selected decision-`0055` counts derive 1,744 fields and 109 fields per alias.
- Falsification: the blocker audit exercised the AHB validator, revision-1
  scale validator/binder, public planner, and portable-backend negotiation; no
  existing route admits the required shape.
- Durability: this decision, the owning task-tree decomposition, the Knowledge
  Map card, bounded `MEMORY.md`, and the mdBook carry the same selection. The
  implementation leaves must replace design-time evidence with executable RED/
  GREEN oracles before claiming the route complete.

## Consequences

- The balanced candidate can exercise ordinary cross-family interaction without
  weakening a product protocol or turning scale infrastructure into a public
  API.
- Portability is an exact backend qualification, not a label attached to a
  private bridge capability.
- The chosen 2,048-binding count remains independently derivable and mutation-
  resistant; no opaque padding or forged IR is needed.
- Runtime and capacity claims remain impossible until their separately owned
  measurement and promotion work completes.

## Containment

This bounded rationale record fits the existing decision collection limits and
changes no containment ceiling.
