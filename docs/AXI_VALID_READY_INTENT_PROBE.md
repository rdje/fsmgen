# AXI Valid/Ready Intent Probe

Status: evidence inventory complete; no IAL2 implementation selected.

Task tree:
[docs/tasks/AXI-VALID-READY-INTENT-PROBE.md](tasks/AXI-VALID-READY-INTENT-PROBE.md).

Source artifact:
`docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf`

Source SHA-256:
`20aa5f946df5fa97053689d705959b1ef6a90a88f845fa3b686a53311f680ac1`

## Purpose

This note records the first bounded source-anchor inventory for treating AXI
Valid-Ready transport as a future IAL2 protocol-intent candidate.

It is not a shipped feature. It does not select syntax, parser behavior,
lowering behavior, generated `.fsm`, HDL, or reusable library artifacts.

## Extraction Method

The tracked PDF was inspected as a repo-local reference artifact:

- `pdfinfo` confirmed a 320-page, unencrypted PDF.
- `pdftotext -layout` produced a temporary text extraction for section and
  page search.
- The write and read dependency diagrams were rendered from the PDF pages and
  visually checked against the extracted text.
- Temporary extraction and render products were kept outside the repository
  and are not tracked.

The repository keeps this curated note instead of a raw extracted text dump.
That preserves source anchors and reviewability without embedding large
copyrighted spec text.

## Source Anchors

| Anchor | PDF page | Evidence captured | Classification |
| --- | ---: | --- | --- |
| `A2.3 Valid-Ready transport` | 29 | AXI channels use a shared two-signal transfer rule: the transmitter owns `VALID`, the receiver owns `READY`, and data transfer occurs only when both are asserted in the same cycle. `VALID` is reset-low, must not be delayed until `READY`, and once asserted remains asserted until the handshake. `READY` may be asserted before or after `VALID` and may be deasserted before `VALID`. | source fact |
| `A2.3.1 Valid-Ready signals`, Table `A2.2` | 30 | The base AXI channel families expose one-bit `VALID` and `READY` pairs for write address, write data, write response, read address, and read data channels. The default `READY` state is flexible; default-high is recommended where the receiver can accept any valid request. | source fact |
| `A2.3.2.1 Write transaction dependencies`, Figure `A2.5` | 31 | Write request channels must present address/data valid independently of the matching ready. The subordinate is allowed to wait before asserting address/data ready. The write response depends on accepted address, accepted final write data, and last-write indication; the response valid is independent of response ready. The manager may wait before response ready. | source fact; visual check |
| `A2.3.2.2 Read transaction dependencies`, Figure `A2.6` | 32 | Read address valid is independent of address ready. The subordinate may wait before address ready. Read data valid depends on an accepted read address and is independent of read ready. The manager may wait before read ready. | source fact; visual check |
| `A2.5 Pipelining and register slices` | 40 | Register stages can be inserted on Valid-Ready paths. Valid/control movement must stay aligned with its payload, and different channels can use different staging. This is a future pipeline-alignment concern, not first-probe implementation behavior. | source fact; deferred design concern |
| `A14.1 Interface gating with Valid-Ready transport` | 223-224 | Wake-up signaling adds power-management timing rules around Valid-Ready channels. This extends the transport setting but is outside the first minimal valid/ready probe. | source fact; explicit residue |
| `A15.4.2 Snoop channels using Valid-Ready transport` | 250 | ACE snoop channels reuse Valid-Ready style dependencies for additional channel families. This confirms reuse pressure but remains outside the first minimal AXI4 probe. | source fact; explicit residue |

## Source Facts For The Minimal Candidate

The smallest source-supported transport facts are:

- A channel transfer has two directional roles: transmitter and receiver.
- `VALID` is transmitter-owned, reset-low, and held until a handshake.
- `READY` is receiver-owned and may be asserted before or after `VALID`.
- A transfer fires only when `VALID` and `READY` are both asserted in the same
  cycle.
- The transmitter cannot wait for `READY` before asserting `VALID`.
- The receiver is allowed to wait for `VALID` before asserting `READY`.
- Payload/control stability is coupled to the `VALID` interval through the
  requirement that the transfer be meaningful at the handshake cycle.
- Write and read transactions add dependency edges between accepted address,
  accepted data, last-data indication, and response/data channels.
- Register-stage insertion is legal only when the control path remains aligned
  with the payload path.

## Inferred Rules

These are candidate modeling rules inferred from the source facts, not source
text copied into a language design:

- A future IAL2 object would likely model a reusable
  `valid_ready_transport` relation parameterized by channel role, valid signal,
  ready signal, payload/control bundle, reset, and optional dependency edges.
- `handshake_fire = VALID && READY` is the natural scheduler-visible event for
  accepted transfer.
- `VALID` hold and payload/control stability become assertion candidates.
- `VALID` independence from `READY` is a causality rule that prevents
  deadlock-prone source models.
- `READY` fairness or eventual acceptance is not guaranteed by this source
  inventory; any liveness assumption must be explicitly authored or reported
  as an environment assumption.
- Write and read dependency diagrams can become channel-edge constraints, but
  only after a later leaf defines how those edges lower to IAL1 and IAL0.

## Explicit Abstractions For The First Probe

The first candidate is intentionally smaller than AXI:

- No full AXI manager, subordinate, or interconnect model.
- No burst semantics except the write-response dependency on the final write
  data transfer.
- No ordering, ID, exclusives, atomics, locks, QoS, regions, protection,
  cacheability, or user sidebands.
- No wake-up or power-gating behavior.
- No ACE snoop or DVM behavior.
- No credited transport behavior.
- No clock-domain crossing or asynchronous transport behavior.
- No selected FSM shape, state names, pipeline depth, or buffering policy.

## Unsupported Residue

The first future implementation leaf must explicitly carry these as residue
unless it selects them as owned scope:

- Wake-up rules from `A14.1`.
- Snoop-channel Valid-Ready reuse from `A15.4.2`.
- Credited transport from the neighboring AXI transport material.
- Pipeline insertion and retiming guarantees from `A2.5`.
- Full transaction-level AXI ordering and interconnect behavior.
- Environment liveness assumptions for `READY`.

## IAL2 Boundary Assessment

This evidence is strong enough to justify a later design/probe leaf for a
bounded protocol-intent object. It is not yet strong enough to justify an
implementation leaf.

A future IAL2 design is viable only if it can preserve all of these outputs:

- source anchors back to the tracked AXI reference,
- a fact/inference/abstraction/residue report,
- explicit role and channel dependency structure,
- generated or configured IAL1/IAL0 artifacts that remain reviewable,
- and focused validation gates for the generated handshake, hold, dependency,
  and report contracts.

If the result is only a reusable hand-written `.fsm` or `.isf` library, it is
still useful but remains below the IAL2 bar.

## Current Conclusion

The AXI Valid-Ready transport contract is the smallest useful AXI-derived
IAL2 evidence object found so far. It has real protocol semantics, channel
roles, causality rules, stability obligations, and dependency edges. The next
work must still be a new exact task-tree leaf before any source language,
lowering, or HDL behavior is selected.
