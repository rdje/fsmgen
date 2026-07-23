# IAL2 AXI manager initiator — post-B next-increment selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.15` (behavior-neutral selector).

Date: 2026-07-23

Status: selection recorded. No parser, generator, public source, support entry,
manifest, test, generated artifact, runtime behavior, or HDL behavior changes
in this leaf.

## Decision

Select a bounded **single-beat AXI manager AW+W write-request composition** as
the next increment after the independent AW driver, W driver, and B response
acceptor.

The immediate next owner is
`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.16`, a behavior-neutral readiness audit.
It must derive the exact composition boundary, safe single-beat metadata policy,
coordinator schedule, structural artifact contract, executable proof, and owner
map before public-contract selection.

The composition must reuse the generated `axi_aw_driver` and `axi_w_driver`
children unchanged. Its only new behavior is a distinct generated coordinator
that launches both children once, remembers their independent completion
events, and completes the aggregate write request only after both channel
handshakes have occurred. A generated structural top must instantiate the two
children plus the coordinator and be the selected HDL entry.

The shipped `axi_b_response_acceptor` remains independent. This increment ends
at **write-request issue completion** (AW and W accepted), not AXI transaction
completion (B response accepted).

## Evidence read and live state

This selector read and compared:

- `ppif/axi_aw_driver.ppif`, `AxiAwDriver.pm`, its report, six-state schedule,
  and `t/1499` exactly-once/stall proof;
- `ppif/axi_w_driver.ppif`, `AxiWDriver.pm`, its single-beat report, six-state
  schedule, and `t/1500` exactly-once/stall/zero-strobe proof;
- `ppif/axi_b_response_acceptor.ppif`, `AxiBResponseAcceptor.pm`, its bounded-
  response report, six-state schedule, and `t/1501` unarmed/already-high/
  delayed-response proof;
- the tracked AXI transport, write-dependency, AW, W, and B source anchors and
  the completed AW/W/B readiness and contract notes;
- the physical `write_complete` + `BID` seam in
  `ppif/axi_manager_capacity_status_response_demux.ppif` and the 9,773-line
  `AxiManagerCapacityStatus.pm` generator;
- the generated-child/generated-structural-top patterns in
  `ApbComposition.pm`, `AhbInterconnect.pm`, and the Valid-Ready bundle wrapper;
- decisions `0014`, `0017`, and `0020`, the active task tree, AXI mdBook,
  Memory, and Knowledge Map.

Fresh schedule/report probes confirmed that all three shipped channel
primitives still select one generated `.isf`, one generated `.fsm`, and one
generated child HDL entry. AW and W are independent drivers; B is an explicitly
armed acceptor. The composition infrastructure already supports aggregating
child artifacts and selecting a structural `.fsm` top without bypassing the
mandatory lowering chain.

## Why AW+W coordination is now the smallest coherent step

### Its prerequisites are complete and executable

The prior post-W selector deferred AW+W composition until all three independent
write-side primitives were bounded. That condition is now satisfied:

```text
one command -> AW child -> exactly one AW handshake -> aw_done
            -> W child  -> exactly one W handshake  -> w_done

separate later arm -> B child -> exactly one B handshake -> b_done
```

The first two lines can now be composed without inventing channel behavior.
The new coordinator owns only launch and join semantics. Reusing the child
modules preserves their already-executed VALID-hold, payload-stability, and
exactly-once guarantees.

### It advances transaction coherence without claiming a full transactor

An independent AR driver would be another small primitive, but it opens the
read path before the write path can issue a coherent request. A complete
AW+W+B transactor would combine request launch, independent request completion,
response ownership, response status, and transaction completion in one step.
The selected AW+W boundary is the narrow middle: one aggregate request is not
retired until both independent request channels have transferred, while B
response acceptance remains visibly separate.

### Capacity-core integration is not a smaller semantic boundary

The capacity/status core consumes abstract `write_submit`, `write_complete`,
request-ID, and response-ID events and supports many transaction/cardinality
families. Wiring only the B acceptor into one chosen core variant would close
the response edge while leaving physical request launch unrelated to the
core's submit event. It would also require choosing among a much broader
capacity/ID/response-demux surface before an aggregate write request exists.
The AW+W request composition establishes the missing physical request unit
that a later capacity or complete-transactor composition can submit and track.

## Mandatory single-beat coherence gate

The composition is not safe if it merely forwards every current AW command
field unchanged.

The AW child accepts an eight-bit `cmd_awlen`, three-bit `cmd_awsize`, and
two-bit `cmd_awburst`. AXI burst length is `AWLEN + 1`, and transfer size is
`2^AWSIZE` bytes. The W child emits exactly one 32-bit beat with `WLAST = 1`.
Therefore an aggregate source that permits arbitrary AW length can announce a
multi-beat write while supplying one final W beat — an incoherent transaction.
Narrow/unaligned size and burst choices also interact with address and strobe
lane legality that the standalone W primitive deliberately does not own.

`.16` must select and prove one explicit safe policy before contract spelling:

- preferably a fixed single-beat/full-width address policy (`AWLEN = 0`, a
  32-bit transfer size, and a legal single-beat burst choice) generated toward
  the AW child; or
- an equally bounded fail-closed input policy whose accepted values are proven
  coherent with the one-beat W child.

The audit must not expose arbitrary AW burst metadata and call the aggregate
single-beat. Multi-beat W, dynamic `WLAST`, narrow/unaligned lane placement,
and general burst/address coupling remain separate future behavior.

## Required composition architecture

The next behavior owner must follow the repository's generated composition
model:

1. generate the existing AW child through `AxiAwDriver` and retain its
   `axi_aw_driver.isf` / `axi_aw_driver.fsm` review artifacts;
2. generate the existing W child through `AxiWDriver` and retain its
   `axi_w_driver.isf` / `axi_w_driver.fsm` review artifacts;
3. generate a distinct coordinator `.isf`, lower it with the ISF scheduler to
   a distinct coordinator `.fsm`, and report its schedule;
4. generate a structural `.fsm` top that instantiates the AW, W, and coordinator
   children, declares the public ports, and wires the aggregate command,
   independent bus channels, child busy/done events, and shared clock/reset;
5. expose aggregate `generated_ial1.items[]`, `generated_ial0.items[]`, child
   artifact lists, schedule reports, and a selected structural HDL entry; and
6. keep direct IAL2-to-IAL0 lowering forbidden.

A monolithic replacement actor is rejected. It would duplicate the two proven
handshake state machines, create a second source of truth for AW/W behavior,
and make later fixes drift between standalone and composed forms.

The existing monitor-only Valid-Ready bundle is not this composition: decision
`0017` aggregates review artifacts but owns no launch/join controller.
Decision `0020` explains how this bus-side composition can later sit beneath a
protocol-neutral transaction interface, but that director-gated horizon is not
activated here.

## Candidate comparison

| Candidate | Assessment | Disposition |
| --- | --- | --- |
| AW+W single-beat write-request composition | Reuses two proven children; adds one launch/join coordinator and one structural top. Requires an explicit safe AW metadata policy for the one-beat W child. | **Selected; `.16` readiness audit.** |
| B acceptor + capacity/status integration | Must choose a capacity/ID/demux variant and relate physical response acceptance to abstract completion while request submission remains unwired. | Deferred until a coherent request unit exists. |
| Complete AW+W+B single-beat write transactor | Adds request join, B arming/ownership, response status, and transaction completion at once. | Deferred; too many contracts in one increment. |
| AR address-channel driver | Primitive-sized, but opens a new read path and immediately requires R acceptance/data semantics. | Deferred while closing the selected write path. |
| R response/data acceptor | Must choose single/multi-beat scope, RLAST, data/status capture, and response ownership. | Deferred. |
| Multi-beat W + burst/address coupling | Requires beat sourcing/storage, counters, dynamic WLAST, strobe/lane policy, and AW metadata coupling. | Deferred. |
| Protocol-neutral transaction interface | Architectural North Star from decision `0020`, not PNT-eligible until director-activated. | Preserved, not activated. |

## Exact `.16` readiness owner

`.16` must audit, without changing behavior:

- the aggregate command and status boundary, including idle-only admission,
  aggregate busy, and one-cycle aggregate done;
- exact single-beat address metadata: `AWLEN`, `AWSIZE`, `AWBURST`, 32-bit
  address/data, four-bit `WSTRB`, alignment/lane policy, and zero-strobe
  preservation;
- shared `AWID` width 4 and the fact that BID matching/B completion remain
  outside the request composition;
- launch fanout to both children exactly once, including already-high
  AWREADY/WREADY and independently stalled channels;
- completion-history storage so a one-cycle `aw_done` or `w_done` cannot be
  lost when the other child completes later;
- a generated coordinator ISF schedule and priority policy, including
  simultaneous child completion and command-while-busy behavior;
- structural top syntax, public ports, child instance names, explicit wiring,
  artifact lists, aggregate report schema, semantic root, HDL entry, and
  `--outdir` behavior;
- whether the public composition clause embeds exact child contracts or uses a
  bounded aggregate vocabulary, while preserving the standalone public
  sources unchanged;
- fail-closed profile/role/cardinality/shared-clock-reset/width/name/mixing
  diagnostics and `.axi` alias rejection;
- executable generated-HDL scenarios covering simultaneous READY, AW-first,
  W-first, long independent stalls, exactly one handshake per child, exactly
  one aggregate done after both, stable child payloads, and final busy/valid
  low; and
- every parser, generator, source, support, manifest, test, mdBook, fact-card,
  validation, rollback, and following contract-selection owner.

## Preserved boundaries

This selector changes no behavior and does not activate:

- the AW+W composition parser/generator/source contract;
- B arming, AW/W/B response ownership, BRESP interpretation, or complete write
  transaction completion;
- capacity/status submit/completion integration or outstanding-write policy;
- multi-beat W, dynamic `WLAST`, general burst/address generation, narrow/
  unaligned lane placement, or added AXI attributes;
- AR/R behavior;
- decision `0020`'s transaction interface;
- `.axi` aliases, verification-output generation, direct backend lowering,
  backend-language variants, or VHDL behavior; or
- AHB/APB behavior.

The mandatory chain remains:

```text
IAL2 -> generated IAL1/.isf children -> generated IAL0/.fsm children
     -> generated structural .fsm top -> HDL
```

## Validation and rollback

This documentation-only slice is validated with the Knowledge Map generator
and checker, mdBook build, bounded Memory/docs-path/whitespace checks, and the
full doctrine gate. The focused AW/W/B tests are evidence read; no behavior
changed that requires rerunning them.

Rollback removes this selection note and its fact card, restores `.15` to
active, removes `.16`, and restores the prior task-index/book/Memory pointers.
No parser, generator, source, test, generated artifact, or HDL rollback is
required.
