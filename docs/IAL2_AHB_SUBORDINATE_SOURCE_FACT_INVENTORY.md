# IAL2 AHB Subordinate Source Fact Inventory

Date: 2026-06-29

Owning task-tree leaf: `IAL2-FEATURE-COMPLETENESS-FRONTIER.707`

Source reference:
`docs/vendor/arm/amba/ahb/IHI0033_C_2021-09_AMBA_5_AHB_Protocol_Specification.pdf`

## Purpose

This inventory extracts the first source-backed facts needed before selecting
a lower-layer direct `.fsm` AHB subordinate seed contract. It does not select
or add that seed, and it does not change parser, generator, public source,
support-accounting, manifest, test, generated-artifact, HDL/runtime,
direct-backend, verification-output, backend-language variant, AXI, APB, or
VHDL behavior.

## Source Scope

The imported reference states that, unless otherwise qualified, AHB refers to
both AHB-Lite and AHB5 and common signals apply to both families. That makes a
first lower-layer seed safest when it targets a named common AHB/AHB-Lite
subset and leaves AHB5 optional features behind explicit later owners.

Source anchor: section `1.2`, page `1-17`.

## Subordinate Interface Facts

The common subordinate-side shape is:

- Inputs from manager/interconnect/decode: `HSELx`, `HADDR`, `HTRANS`,
  `HWRITE`, `HSIZE`, `HBURST`, `HPROT`, `HMASTLOCK`, `HREADY`, and `HWDATA`.
- Outputs toward the multiplexor/manager path: `HREADYOUT`, `HRESP`, and
  `HRDATA`.
- Optional or property-gated signals such as `HNONSEC`, `HEXCL`, `HMASTER`,
  `HEXOKAY`, `HWSTRB`, user signals, and parity/check signals must not be
  silently included in the first seed unless a later contract selects their
  property boundary.

Source anchors: sections `2.2`, `2.3`, `2.4`, `2.5`, pages `2-21` to `2-25`;
Appendix `A.1`, page `A-98`.

## Selection And Address Phase Facts

Each subordinate has its own `HSELx`. For a non-IDLE transfer, `HSELx` is
asserted with the address and control signals. When a subordinate is initially
selected, it also monitors `HREADY` so it only responds after the previous bus
transfer has completed.

A subordinate cannot extend the address phase. It must be capable of sampling
address/control in the address phase. The subordinate can extend only the data
phase by driving `HREADYOUT` low, which contributes to the overall `HREADY`
stall behavior through the interconnect.

Source anchors: sections `1.3`, `2.4`, `3.1`, pages `1-18`, `2-24`, `3-28`.

## Transfer Type Facts

`HTRANS[1:0]` classifies transfers as `IDLE`, `BUSY`, `NONSEQ`, or `SEQ`.
For `IDLE` and `BUSY`, a subordinate must provide a zero-wait OKAY response
and ignore the transfer. `NONSEQ` represents a single transfer or the first
transfer of a burst. `SEQ` represents remaining burst transfers with related
addresses and unchanged control information.

Source anchor: section `3.2`, page `3-30`.

## Read And Write Data Facts

`HWRITE` selects direction. On writes, the manager drives `HWDATA`; if a write
transfer is extended, the manager holds write data valid until completion. On
reads, the subordinate drives `HRDATA`; if the subordinate extends the read
transfer, it only needs valid read data in the final completion cycle.

For narrower transfers, only active byte lanes are required to be valid. Read
data is required only for a transfer that completes with OKAY; ERROR responses
do not require valid read data.

Source anchors: sections `3.1`, `6.1`, pages `3-28`, `3-29`, `6-64`.

## Response Timing Facts

The subordinate status response is driven by `HRESP` and completion by
`HREADYOUT`:

- OKAY plus completion means the transfer completed successfully.
- OKAY with `HREADYOUT` low represents a pending transfer or wait state.
- During wait states before successful completion, `HRESP` remains OKAY.
- ERROR is a two-cycle response: first ERROR with `HREADYOUT` low, then ERROR
  with `HREADYOUT` high to complete the transfer.
- If more latency is needed before reporting ERROR, the subordinate inserts
  initial OKAY wait states first.
- For read ERROR, the reference recommends driving `HRDATA` to zero because a
  manager can still observe read data on an ERROR response.

Source anchor: section `5.1`, pages `5-60` and `5-61`.

## Reset And Validity Facts

`HRESETn` is the only active-low protocol signal. Reset can assert
asynchronously and deasserts synchronously after a rising `HCLK` edge. During
reset, subordinates must drive `HREADYOUT` high.

Signals are sampled on rising `HCLK`, and output changes occur after the
rising edge. The always-valid set includes `HTRANS`, `HADDR`, `HSEL`,
`HMASTLOCK`, `HREADY`, `HREADYOUT`, and `HRESP`. Address/control auxiliaries
such as `HBURST`, `HPROT`, `HSIZE`, and `HWRITE` are valid when `HTRANS` is
not `IDLE`. `HWDATA` is valid during a write data phase; `HRDATA` is valid in
a read data phase only when `HREADY` is high and `HRESP` is OKAY.

Source anchors: sections `7.1`, `8.1`, `8.2`, pages `7-72`, `8-74`, `8-75`.

## First-Seed Implications

The source facts support a next contract-selection leaf for a bounded
AHB-Lite/common-AHB subordinate seed. The first seed should stay below IAL2 and
select a reviewable lower-layer `.fsm` fixture before any IAL2
completer/subordinate source surface exists.

The contract selector should decide:

- whether the seed is named `AHB-Lite subordinate`, `common AHB subordinate`,
  or a narrower memory-mapped subordinate subset;
- whether the first fixture accepts only `NONSEQ` single transfers, or also
  selected `SEQ` burst behavior;
- the exact selected input/output port set and defaults for optional
  address/control inputs;
- whether storage is a single register, a small register bank, or only
  response behavior;
- how unsupported addresses, unsupported transfer types, and write/read policy
  errors map to the two-cycle ERROR response;
- how reset drives `HREADYOUT`, `HRESP`, and `HRDATA`;
- whether `HREADYOUT` is always high in the first seed or whether bounded wait
  states are selected.

## Selected Next Owner

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.708` as lower-layer AHB
subordinate seed contract selection. That leaf must choose the exact source
shape, direct `.fsm` fixture shape, selected subset, diagnostics/report
expectations, validation scope, docs/book updates, and residue before any seed
file or behavior is added.

Later status: `.708` selected `fsm/ahb_lite_subordinate.fsm`, module
`ahb_lite_subordinate`, and support-accounting identity
`protocol.ahb_lite_subordinate` as the first lower-layer AHB-Lite/common-AHB
subordinate direct seed target. `.709` shipped that direct seed.

## Non-Changes

This slice does not add a source reference, seed, parser, generator, source
sample, support-accounting entry, manifest behavior, test behavior,
schedule/check/semantic JSON behavior, generated artifact, HDL/runtime
behavior, direct-backend behavior, verification-output generation,
backend-language variant, AXI, APB, or VHDL behavior.
