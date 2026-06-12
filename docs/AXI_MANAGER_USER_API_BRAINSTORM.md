# AXI Manager User API Brainstorm

Status: captured design direction; no IAL2 implementation selected.

Task tree:
[docs/tasks/AXI-MANAGER-USER-API-BRAINSTORM-CAPTURE.md](tasks/AXI-MANAGER-USER-API-BRAINSTORM-CAPTURE.md).

Related source-anchor inventory:
[docs/AXI_VALID_READY_INTENT_PROBE.md](AXI_VALID_READY_INTENT_PROBE.md).

Related ID/order evidence inventory:
[docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md).

## Purpose

This note captures a user-facing IAL2 surface direction for a future AXI
manager. It preserves the design intent from the AXI manager discussion in
durable project documentation instead of leaving it only in the session log.

This is not a shipped feature. It does not select syntax, parser behavior,
lowering behavior, generated `.fsm`, HDL, or validation fixtures.

## IAL2 Surface Boundary

The generic IAL2 file surface must remain protocol/platform-generic. AXI
manager work should be one IAL2 vocabulary candidate, not a separate semantic
layer.

The exact extension spelling remains open. Current candidates are `.pif`
for Protocol Intent Format, `.ppi` for Protocol/Platform Intent, and `.ppif`
for Protocol/Platform Intent Format.

Protocol-specific extensions such as `.axi`, `.chi`, `.ace`, `.ahb`, `.apb`,
`.atb`, `.smbus`, or `.i2s` may also be accepted later as profile aliases
that imply a vocabulary. If `.axi` exists later, it must behave like a generic
IAL2 file that selected an AXI profile internally; it must not become a
separate layer or a direct path to `.fsm`.

Any future AXI manager IAL2 source must lower through reviewable IAL1 before
IAL0:

```text
IAL2 -> IAL1 / .isf -> IAL0 / .fsm -> HDL
```

Direct IAL2-to-`.fsm` lowering is not allowed.

## Core Principle

The future AXI manager should be a protocol-aware transaction service, not a
thin wrapper around five independent channels.

Easy mode must mean conventions over configuration, not reduced capability.
The user should submit logical transactions. The manager should own AXI
legality, scheduling, backpressure, IDs, ordering, response matching, and
status feedback.

Power mode and Raw channel mode should expose more control, but they should
normally still pass through the same AXI rule engine. The user gets more
latitude; the protocol rules do not disappear.

## User-Facing Surface Shape

The IAL2 surface should make common intent read naturally:

```text
(spawn axi0.write (addr a) (data d) (tag wr0))
(spawn axi0.read  (addr b) (into r) (tag rd0))

(await axi0.done wr0)
(await axi0.done rd0)
```

This is illustrative syntax only. The important surface rule is that users
request reads and writes; they do not manually prepare `AW`, `W`, `B`, `AR`,
and `R` choreography for ordinary use.

The manager should transparently handle:

- the five AXI channel families: write address, write data, write response,
  read address, and read data,
- outstanding read and write windows,
- ID allocation and user-specified ID validation,
- per-ID ordering constraints,
- legal interleaving and reordering where AXI permits it,
- burst tracking and default burst conventions,
- response matching and response/error reporting,
- channel-level Valid-Ready backpressure,
- max-pending limits,
- queueing and acceptance policy,
- and generated protocol assertions/reporting from the same rule set.

## Easy Mode

Easy mode should be the default user-facing IAL2 surface. It should expose the
full AXI manager through strong defaults:

```text
(axi4.manager axi0
  (interface m_axi)
  (addr-width 32)
  (data-width 64)
  (id-width 4)

  (max-pending-reads 16)
  (max-pending-writes 16)
  (submit-policy queued)
  (default-burst incr)
  (response-policy report))
```

The user should be able to submit many logical transactions without manually
tracking AXI concurrency rules:

```text
(spawn axi0.write (addr a0) (data d0) (tag w0))
(spawn axi0.write (addr a1) (data d1) (tag w1))
(spawn axi0.read  (addr r0) (into data0) (tag r0_tag))
(spawn axi0.read  (addr r1) (into data1) (tag r1_tag))
```

The manager must decide when each transaction can be legally accepted and
issued. If it cannot accept more work, the user should get clear feedback
without needing to know the low-level reason first:

```text
(axi0.can_accept read)
(axi0.can_accept write)
(axi0.full read)
(axi0.full write)
(axi0.pending_reads)
(axi0.pending_writes)
(axi0.read_slots_available)
(axi0.write_slots_available)
(axi0.accept_blocked_reason write)
```

Expected submission policies:

- `blocking`: wait until the manager can accept the transaction.
- `try`: return accepted/full status immediately.
- `queued`: accept into an internal queue until the declared queue or pending
  depth is full.

The easy path should still use AXI's concurrency model. It should not collapse
the interface to one transaction at a time unless the user configured the
manager with one available slot.

## Power Mode

Power mode should keep the same transaction verbs while allowing explicit
overrides:

```text
(spawn axi0.read
  (addr base)
  (len 15)
  (size 3)
  (burst wrap)
  (id stream_id)
  (cache cache_attr)
  (prot prot_attr)
  (qos qos_level)
  (tag linefill0))
```

The manager should still validate, queue, stall, or reject requests according
to declared policy when an override violates capacity, ordering, ID, or other
AXI legality constraints.

Power mode should expose capability, not responsibility transfer. The user may
choose fields and policies; the manager remains the protocol authority.

## Supervised Raw Channel Mode

Raw channel access may be necessary for protocol experiments, adapters, and
edge-case verification work. It should normally be supervised raw mode:

- users can get closer to `AW`, `W`, `B`, `AR`, and `R` channel operations,
- the manager/rule engine still enforces source-anchored AXI rules where it
  can,
- generated assertions should flag rule violations that cannot be resolved at
  compile time,
- and the lowering report should identify which protections were active.

An unsafe raw escape hatch may exist later for verification-only work, but it
cannot claim full AXI correctness. Guaranteed legality and unrestricted raw
bypass are incompatible.

## AXI Rule Engine Requirement

All user-facing levels should be backed by one AXI rule engine:

| Surface | User controls | Manager responsibility |
| --- | --- | --- |
| Easy | logical read/write intent, tags, optional status handling | choose legal IDs/defaults, queue, schedule, enforce ordering, track responses |
| Power | transaction fields, IDs, burst/cache/prot/qos/strb choices, policies | validate choices, enforce AXI rules, report stalls/rejections |
| Supervised Raw | lower-level channel timing and payload choices | supervise legal channel behavior and emit checks/reporting |

The rule engine likely needs:

- an ID allocator and user-ID validator,
- per-ID outstanding scoreboards,
- read and write pending queues,
- response matchers,
- per-ID ordering queues,
- legal interleaving/reordering policy,
- burst and last-beat trackers,
- `AW/W/B` and `AR/R` channel schedulers,
- backpressure/status signals,
- policy-controlled accept/stall/reject behavior,
- generated assertions,
- and a source-anchor/report contract for defaults, assumptions, and residue.

## ID/Ordering Evidence Boundary

The first source-anchored ID/order inventory is now recorded in
[docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md).
It confirms the high-level API direction without selecting syntax or lowering:
Easy mode can remain fully concurrent if the manager owns source-anchored ID
allocation, outstanding scoreboards, same-ID ordering, response matching,
read-data interleaving policy, and clear flow-control feedback.

The evidence also sharpens the boundary. A future manager design must not
treat "same ID" as a blanket serialization rule or "different ID" as an
unconditional freedom rule; the source anchors qualify ordering by channel,
destination, location/region, memory type, component role, and transaction
class.

## Source-Anchor Boundary

The remaining exact AXI ID, ordering, interleaving, outstanding, and response
rules must not be designed from memory. Future task-tree leaves must continue
extracting those rules from the tracked AXI specification and classify each
rule as one of:

- statically enforceable at IAL2 authoring time,
- enforceable by generated scheduler/scoreboard behavior,
- enforceable by generated runtime assertions,
- an environment assumption,
- unsupported residue,
- or an explicit simplification selected by the user.

Only after the remaining source-anchored rule matrix exists can the AXI
manager API be promoted from brainstorm to design.

## Current Conclusion

The intended IAL2 direction is a high-quality user-facing AXI manager surface:
simple logical transactions by default, full AXI power through structured
overrides, and supervised raw access for advanced cases. The manager should be
the AXI expert so users do not have to internalize every concurrency and ID
rule to stay legal.

The next technical prerequisite is no longer the first evidence extraction; it
is a later exact design/rule-matrix leaf that turns the source anchors into a
bounded rule-engine proposal. No implementation is selected by this note.
