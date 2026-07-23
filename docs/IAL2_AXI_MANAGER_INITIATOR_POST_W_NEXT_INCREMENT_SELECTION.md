# IAL2 AXI manager initiator — post-W next-increment selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.11` (no-behavior selector).

Date: 2026-07-23

Status: selection recorded. No parser, generator, public source, support entry,
manifest, test, generated artifact, or runtime/HDL behavior changes in this
leaf.

## Decision

Select a **bounded AXI manager B write-response-channel acceptor** as the
smallest safe increment after the shipped independent AW and single-beat W
drivers.

The immediate next owner is
`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.12`, a behavior-neutral readiness audit.
It must fix the safe first-slice boundary and owner map before public-contract
selection. In particular, the audit must decide whether the primitive is
explicitly armed for one response or continuously ready within a bounded
single-outstanding policy; `.11` does not guess that externally visible
contract.

This direction completes the set of independent bus-side primitives needed by
the bounded write path:

```text
manager -> AWVALID/AW payload -> subordinate
manager -> WVALID/W payload   -> subordinate
manager <- BVALID/B payload   <- subordinate
```

The new primitive will own only the physical B-channel acceptance boundary:
manager-driven `BREADY`, subordinate-driven `BVALID`, and capture/reporting of
the response payload on `BVALID && BREADY`. Coordination with AW/W and the
capacity/status core remains later work.

## Evidence Read

The selector read and compared:

- `ppif/axi_aw_driver.ppif`,
  `perl/FSM/IAL2/ProtocolIntent/AxiAwDriver.pm`, and
  `t/1499-ial2-axi-aw-driver.t`;
- `ppif/axi_w_driver.ppif`,
  `perl/FSM/IAL2/ProtocolIntent/AxiWDriver.pm`, and
  `t/1500-ial2-axi-w-driver.t`;
- the exact six-state accept-over-launch schedules and generated-HDL
  exactly-once/stall-stability invariants shipped by `.7` and `.10`;
- decision `0017` (Valid-Ready monitor bundles are aggregate review artifacts,
  not transaction coordination) and decision `0020` (future layered,
  composable transactors; not yet activated);
- the tracked Arm AXI Issue L reference, especially A2.3/A2.3.1/A2.3.2.1 and
  A3.3/A3.3.1;
- `docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_READINESS_AUDIT.md`, the response-demux
  fact cards, `ppif/axi_manager_capacity_status_response_demux.ppif`, and the
  physical-response gap in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`;
- the generated-child plus generated-structural-top patterns in
  `FSM::IAL2::ProtocolIntent::ApbComposition` and
  `FSM::IAL2::ProtocolIntent::AhbInterconnect`;
- current support-accounting, language-surface, task-tree, Memory, Knowledge
  Map, and AXI mdBook surfaces.

The tracked PDF pages were text-extracted, rendered, and visually inspected.
A3.3 states that every AXI transaction has response transfer(s); A3.3.1 states
that write responses travel on the B channel and that the Completion response
indicates the write result. Issue L permits `BRESP_WIDTH` values 0, 2, or 3
with default 2. The audit must therefore select a bounded AXI4 width/profile
policy rather than silently treating every current-issue option as first-slice
behavior.

## Why B Acceptance Is Smallest

### It fills an existing physical-to-logical seam

The shipped capacity/status response core already has a clean logical input
shape for an accepted write response:

```text
(write-complete axi0_write_complete)
(write (width 4) (request-id axi0_awid) (response-id axi0_bid))
...
(response-event axi0_write_complete)
```

Its generated response-demux rules consume the abstract/raw response event and
`BID`, but the core does not generate `BREADY` or define
`axi0_write_complete` as `BVALID && BREADY`. A B acceptor is the missing
wire-facing adapter: accept one physical response, preserve its payload, and
produce a bounded completion/event surface that a later composition can wire
to the existing core without changing the core's logical demux contract.

### It remains one independent Valid-Ready channel

Like AW and W, the B channel has one handshake. The direction reverses:
`BVALID` and the response payload are subordinate outputs; the manager drives
`BREADY`. The AXI dependency rules permit the manager to assert `BREADY`
without waiting for `BVALID`; the subordinate owns the dependency that delays
`BVALID` until the address and write-data obligations are satisfied.

That makes a standalone receiver/acceptor a legal bus-side primitive without
requiring it to coordinate the already-shipped AW and W actors. The exact
receiver schedule is not assumed to be the transmitter schedule used by AW/W;
`.12` must derive and execute the appropriate exactly-once capture invariant.

### It advances the chosen write path

AR drive is another bounded channel primitive, but it opens the read path and
immediately creates an R-channel completion dependency. B acceptance closes
the known physical gap on the already-selected write path and supplies the
natural source for the logical response core's raw completion event.

## Candidate Comparison

| Candidate | Size and dependency assessment | Disposition |
| --- | --- | --- |
| B write-response acceptor | One wire-facing receiver handshake; bridges the missing `BVALID && BREADY` event and response payload toward the shipped write response-demux seam. The arming/ready and capture policy still needs an audit. | **Selected; `.12` readiness audit.** |
| Coordinated single-beat AW+W write-request composition | Must fan one command into two children that can stall and complete independently, remember each completion, prevent command retirement until both complete, define aggregate busy/done semantics, and select an aggregate artifact/HDL entry. Technically feasible but larger than one B channel. | Deferred until all three independent write-side primitives are bounded. |
| Immediate AW+W+B complete write transactor | Adds both AW/W coordination and response ownership/status semantics in one slice, including the temporal boundary between request issue and response acceptance. | Deferred; too many contracts at once. |
| AR address-channel driver | Similar primitive scale, but opens a new read direction and requires later R-channel acceptance/data handling rather than closing the current write path. | Deferred. |
| Multi-beat W sequencing | Adds beat storage/sourcing, index/count progression, dynamic `WLAST`, strobe policy, and coupling to AW length. | Deferred. |
| Burst/address coupling | Couples AW length/burst/size/address semantics to W beat progression and future transaction input policy. | Deferred. |
| Capacity/status integration | Cross-generator wiring among AW, W, B, request submission, ID allocation, response demux, and capacity release; larger than establishing the missing physical response primitive. | Deferred. |

## Composition Disposition

When AW+W composition becomes the selected owner, it should **reuse the
generated `axi_aw_driver` and `axi_w_driver` child modules**, not generate a new
monolithic actor that duplicates their handshake state machines.

The repository already proves this artifact model:

1. child protocol-intent generators emit independent generated `.isf` and
   `.fsm` review artifacts;
2. a composition generator collects the child `.fsm` entries;
3. a generated structural top instantiates the child modules and wires them;
4. any behavior not owned by either child is a distinct generated coordination
   actor or interconnect artifact; and
5. the report names every child artifact and the aggregate HDL entry.

For a future AW+W writer, the new behavior is the coordinator: fan out one
accepted command, retain independent AW-done and W-done history, and pulse
aggregate done only after both handshakes. Re-implementing AW/W in one new
actor would duplicate the executable exactly-once schedules, create two
sources of truth, and make later fixes drift. Decision `0017` does not provide
this write-transaction controller; its bundle contract is monitor/report
aggregation only. Decision `0020` explains the eventual higher transaction
layer but remains a future, director-activated horizon.

The selected B acceptor is not itself a composition and therefore needs no
generated child modules in its first slice.

## Exact `.12` Readiness-Audit Owner

`.12` must audit, without changing behavior:

- the precise first-slice B-channel role and public vocabulary, including a
  neutral name such as `axi-b-response-acceptor` rather than assuming a final
  spelling;
- explicit-arm versus bounded continuously-ready behavior, including command
  admission, busy/done/event semantics, and the response ownership invariant;
- manager-driven `BREADY` versus sampled `BVALID`, response ID, and response
  status signals;
- fixed first-slice `BID` and `BRESP` widths, the AXI4/profile boundary, and
  disposition of optional/extended `BRESP`, `BCOMP`, `BUSER`, response
  persistence, exclusive/atomic features, and width configurability;
- exactly one accepted/captured response per admitted bounded receive
  operation (or the exact event-cardinality rule if always-ready is selected),
  payload capture timing, and back-to-back/stall behavior;
- the generated IAL1 schedule and IAL0/HDL proof strategy, deriving receiver
  timing rather than cloning the AW/W transmitter rules;
- the seam to the existing capacity/status core: which outputs can later wire
  to `write_complete`, `BID`, and status consumers while keeping integration
  out of the first behavior slice;
- every parser, generator, public source, support-accounting, capability
  manifest, test, report, mdBook, and generated-artifact owner;
- fail-closed profile/role/width/cardinality/duplicate/mixing rules; and
- the exact following contract-selection leaf.

The audit should use the tracked AXI anchors at minimum for Valid-Ready channel
rules, write-channel dependencies, B-channel signal definitions, and A3.3.1
write-response semantics. It must render any newly relied-upon PDF pages under
the repository PDF verification workflow.

## Preserved Boundaries

This selector changes no behavior and does not activate:

- the B acceptor parser/generator/source contract;
- AW/W/B coordination or a complete write transactor;
- capacity/status-core integration or outstanding-write policy;
- multi-beat W, dynamic `WLAST`, burst/address coupling, or added AXI
  attributes;
- AR/R behavior;
- decision `0020`'s protocol-neutral transaction interface;
- `.axi` aliases, verification-output generation, direct backend lowering,
  backend-language variants, or VHDL behavior; or
- AHB/APB behavior.

The mandatory chain remains:

```text
IAL2 -> generated IAL1/.isf -> generated IAL0/.fsm -> HDL
```

## Validation And Rollback

This documentation-only slice is validated with the Knowledge Map generator
and checker, mdBook build, Memory/docs-path/whitespace checks, and the full
doctrine gate. Because no behavior changes, the focused AW/W runtime tests are
evidence read rather than regressions that must be rerun in this selector.

Rollback removes this selection note and fact card, restores `.11` to active,
removes `.12`, and restores the prior task-index/book/Memory pointers. No
parser, generator, source, test, generated artifact, or HDL rollback is
required.
