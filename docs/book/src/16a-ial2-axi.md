# AXI IAL2 Examples

AXI is the first shipped IAL2 protocol profile. It is not the definition of
IAL2. The generic IAL2 rules, including the mandatory generated `.isf` then
generated `.fsm` review-artifact chain, are in
[IAL2 Protocol and Platform Intent](16-ial2-protocol-platform-intent.md).

Every example in this chapter is checked in under `ppif/`. The examples are
organized by authoring mode, not by implementation module.

## Mode Map

| Mode | Start with | What it demonstrates |
| --- | --- | --- |
| Guided mode | `ppif/axi_aw_valid_ready.ppif` and `ppif/axi_aw_valid_ready.axi` | A single AXI AW Valid-Ready monitor, source anchors, generated assertions, and `.ppif`/`.axi` profile-alias parity for the selected first alias. |
| Initiator mode | `ppif/axi_aw_driver.ppif`, `ppif/axi_w_driver.ppif`, `ppif/axi_w_burst4_driver.ppif`, `ppif/axi_b_response_acceptor.ppif`, `ppif/axi_write_request_composition.ppif`, `ppif/axi_write_burst4_request_composition.ppif`, `ppif/axi_write_transaction_composition.ppif`, `ppif/axi_ar_driver.ppif`, `ppif/axi_r_beat_acceptor.ppif`, `ppif/axi_read_transaction_composition.ppif`, and `ppif/axi_read_burst4_transaction_composition.ppif` | Bounded AXI manager AW/W/AR channel **drivers**, including fixed-four W payload progression, explicitly armed B-response and R-beat **acceptors**, and fixed-single-beat plus fixed-four-beat request/full-transaction **compositions**. |
| More-control mode | `ppif/axi_manager_capacity_status.ppif`, `ppif/axi_manager_capacity_status_id_family.ppif`, and `ppif/axi_manager_capacity_status_transaction_envelope.ppif` | Bounded manager capacity/status, ID-family metadata, and logical transaction metadata while staying in the public AXI manager shell. |
| Raw/full-control mode | `ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif` | A deep shipped AXI manager shape with dynamic read transactions, same-ID issue-order queueing, burst-last response demux, runtime beat-count/`RLAST` validation, and multi-beat read-data output banks. |

Raw/full-control mode is still IAL2. It does not mean raw HDL, direct backend
generation, or bypassing generated review artifacts.

## Guided Mode

The smallest AXI source is the AW Valid-Ready monitor:

```text
(protocol-platform-intent axi_aw_valid_ready
  (profile axi4)
  (source
    (object axi-valid-ready-aw)
    (anchor (document IHI0022_L_2025-08) (section A3.2.1) (page A3-40)))
  (valid-ready-channel axi_aw
    (channel AW)
    (role manager-to-subordinate)
    (clock clk)
    (reset (rst_n active_low async))
    (valid awvalid)
    (ready awready)
    (payload
      (awaddr width 32)
      (awlen width 8))))
```

Run the generic `.ppif` source:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_aw_valid_ready.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/axi_aw_valid_ready.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_aw_valid_ready.ppif
./bin/fsmgen --quiet --outdir generated ppif/axi_aw_valid_ready.ppif
```

Run the selected `.axi` profile alias:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_aw_valid_ready.axi
```

The alias is still IAL2 over the same PPIF-backed model. It reports
`source_kind` as `ial2_profile_alias`; the generic file reports `source_kind`
as `ppif`.

The guided `--outdir` path writes these review artifacts before HDL:

```text
generated/axi_aw_valid_ready_monitor.isf
generated/axi_aw_valid_ready_monitor.fsm
```

The generated `.isf` contains the monitor transaction and the stall-stability
assertions. The generated `.fsm` contains the corresponding `+assert` carriers
and the one-cycle `axi_aw_valid_ready_monitor_done` pulse.

## Initiator Mode (Driving)

The guided AW source *observes* a handshake. The initiator source *drives* it.
`ppif/axi_aw_driver.ppif` is a bounded AXI manager AW address-channel driver: on
a one-shot command trigger it samples the command payload, asserts `AWVALID` and
drives the AW payload (`AWADDR`/`AWID`/`AWLEN`/`AWSIZE`/`AWBURST`) held stable
until the subordinate raises `AWREADY`, accepts that transfer exactly once,
then pulses a one-cycle `aw_done`.

```text
(protocol-platform-intent axi_aw_driver
  (profile axi4)
  (source
    (object axi-aw-driver)
    (anchor (document IHI0022_L_2025-08) (section A3.2.1) (page A3-40)))
  (axi-aw-driver axi_aw_driver
    (role manager-to-subordinate)
    (clock clk)
    (reset (rst_n active_low async))
    (command
      (start aw_cmd_valid)
      (address cmd_awaddr width 32)
      (id cmd_awid width 4)
      (length cmd_awlen width 8)
      (size cmd_awsize width 3)
      (burst cmd_awburst width 2)
      (ready awready))
    (channel
      (valid awvalid)
      (address awaddr width 32)
      (id awid width 4)
      (length awlen width 8)
      (size awsize width 3)
      (burst awburst width 2)
      (busy aw_busy)
      (done aw_done))))
```

The `(command …)` block is the *upstream* order (what transfer to issue) and the
`(channel …)` block is the *driven* AW bus interface — two distinct signal sets,
so the command inputs never alias the driven outputs. The generated actor asserts
`AWVALID` before waiting, holds it (and the payload) stable across the wait,
clears it on the accepted-transfer edge, and completes with a one-cycle pulse
— the same VALID-hold/payload-stable obligation the AW monitor *checks*, here
*guaranteed* by the driver.

Run it end to end:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_aw_driver.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/axi_aw_driver.ppif
./bin/fsmgen --quiet --outdir generated ppif/axi_aw_driver.ppif
./bin/fsmgen --verify-hdl ppif/axi_aw_driver.ppif
```

The schedule report uses `fsmgen.ial2.protocol_intent.axi_aw_driver.v1` and
reports `mode` `driver`. The `--outdir` path writes
`generated/axi_aw_driver.isf` then `generated/axi_aw_driver.fsm` before HDL, and
`--verify-hdl` passes verilator lint and yosys synthesis for the generated
`axi_aw_driver` module.

This was the first AXI **initiator** (bus-driving) source. It complements the
capacity/status response core and drives only the AW address channel; the W
primitive below is deliberately separate. AW/W coordination, AR read-address
drive, burst/address generation, the AXI attribute signals (`AWLOCK`/`AWCACHE`/
`AWPROT`/`AWQOS`/`AWREGION`/`AWUSER`), a configurable `AWID` width, and
integration with the capacity/status core remain future increments (see the
report's `unsupported_residue`).

### Single-transfer correctness guarantee

The generated ISF uses a one-state inline launch handoff and two concurrent
rules. `launch_aw` registers the sampled payload and raises `AWVALID` plus the
active/busy state. `accept_aw`, guarded by `AWVALID && AWREADY`, clears
`AWVALID` and the active/busy state on the same rising edge that accepts the
transfer. Explicit `accept_aw`-over-`launch_aw` priority resolves their shared
writes, and the transaction waits on the latched active bit rather than
depending on a later resample of `AWREADY`.

The focused executable regression covers both continuously-high `AWREADY` and
a four-cycle payload stall followed by a one-cycle `AWREADY` pulse. Across two
commands it requires exactly two rising-edge `AWVALID && AWREADY` acceptances,
two one-cycle `aw_done` pulses, stable payload throughout the stall, and final
`AWVALID = aw_busy = 0`. The generated schedule has six states, no compile
issues, and three explicit priority resolutions; generated HDL also passes
Verilator lint and Yosys synthesis.

### Bounded single-beat W write-data driver

`ppif/axi_w_driver.ppif` is the second shipped initiator primitive: a separate
single-beat W bus-side driver with distinct upstream command inputs
(`w_cmd_valid`, 32-bit `cmd_wdata`, four-bit `cmd_wstrb`, and `wready`) and
driven outputs (`wvalid`, 32-bit `wdata`, four-bit `wstrb`, `wlast`, `w_busy`,
and `w_done`). The public clause is `(axi-w-driver axi_w_driver ...)`; its
generated actor/module is `axi_w_driver` and its report schema is
`fsmgen.ial2.protocol_intent.axi_w_driver.v1`.

```text
(axi-w-driver axi_w_driver
  (role manager-to-subordinate)
  (clock clk)
  (reset (rst_n active_low async))
  (command
    (start w_cmd_valid)
    (data cmd_wdata width 32)
    (strobe cmd_wstrb width 4)
    (ready wready))
  (channel
    (valid wvalid)
    (data wdata width 32)
    (strobe wstrb width 4)
    (last wlast)
    (busy w_busy)
    (done w_done)))
```

The driver asserts `WVALID` without waiting for `WREADY`, holds
`WVALID`/`WDATA`/`WSTRB`/`WLAST` stable while stalled, drives `WLAST = 1` for its
one valid beat, accept exactly one `WVALID && WREADY` transfer per accepted
command, then pulse `w_done` for one cycle. With 32-bit data, `WSTRB` is four
bits; every value is legal, including all zeroes (a transfer that writes no
bytes).

Run it through every shipped review stage and external HDL validation:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_w_driver.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/axi_w_driver.ppif
./bin/fsmgen --quiet --outdir generated ppif/axi_w_driver.ppif
./bin/fsmgen --verify-hdl ppif/axi_w_driver.ppif
```

The outdir contains `generated/axi_w_driver.isf` and
`generated/axi_w_driver.fsm` before HDL. The schedule has six states, no compile
issues, and exactly three priority resolutions (`active_q`, `w_busy`, and
`wvalid`). The report's `single_beat` block records data width 32, strobe width
4, last value 1, and legal all-zero strobe behavior.

The schedule uses the corrected AW rule-pair idiom: inline
launch, priority-winning acceptance on the handshake edge, and completion only
after latched activity clears. The focused generated-HDL regression in
`t/1500-ial2-axi-w-driver.t` covers continuously-high `WREADY` with legal
`WSTRB = 0000` and a four-cycle data/strobe/last stall followed by a one-cycle
READY pulse. It observes exactly two handshakes and two done pulses and ends
with valid/busy low.

This remains a channel primitive, not a complete write transactor. AW/W
transaction coordination, multi-beat `WLAST` sequencing, outstanding writes,
capacity-core integration, and the proposed protocol-neutral transaction
interface remain separate future owners.

### Bounded fixed-four-beat W burst driver

`ppif/axi_w_burst4_driver.ppif` ships the first multi-beat physical write-data
primitive. It is additive to the single-beat driver because that earlier
source correctly hard-wires `WLAST=1`; re-arming it four times under a future
`AWLEN=3` request would falsely mark every transfer final.

The burst4 driver receives four explicit full-width tuples in one atomic
command. Explicit fields keep beat order and width diagnostics visible in PPIF;
packed data128/strobe16 banks and a streaming producer handshake remain future
generalization points.

```text
(axi-w-burst4-driver axi_w_burst4_driver
  (role manager-to-subordinate)
  (clock clk)
  (reset (rst_n active_low async))
  (command
    (start w_cmd_valid)
    (data0 cmd_wdata0 width 32)
    (data1 cmd_wdata1 width 32)
    (data2 cmd_wdata2 width 32)
    (data3 cmd_wdata3 width 32)
    (strobe0 cmd_wstrb0 width 4)
    (strobe1 cmd_wstrb1 width 4)
    (strobe2 cmd_wstrb2 width 4)
    (strobe3 cmd_wstrb3 width 4)
    (ready wready))
  (channel
    (valid wvalid)
    (data wdata width 32)
    (strobe wstrb width 4)
    (last wlast)
    (busy w_busy)
    (beat-done w_beat_done)
    (done w_done)
    (beat-index w_beat_index width 2)))
```

On an idle command, beat zero is captured into the driven WDATA/WSTRB
registers and beats one through three into private registers. Later changes to
any command input cannot affect the active burst. WVALID asserts independently
of WREADY and remains high until the fourth transfer. While WREADY is low,
WVALID, WDATA, WSTRB, WLAST, and the current private index remain stable.

Each rising-edge `WVALID && WREADY` accepts one tuple. Non-final acceptance
changes the driven tuple without inserting a WVALID bubble; held-high WREADY
therefore produces four transfers on consecutive cycles. WLAST is low for
presented indices 0, 1, and 2 and high only for index 3. An all-zero strobe is
legal on any beat and still counts toward the required four transfers.

`w_beat_done` is high in every accepted event cycle and `w_beat_index` names
the accepted tuple. Under continuous READY, beat done can remain high for four
adjacent cycles while the index changes `0,1,2,3`; consume it as a per-cycle
event, not with a low-to-high edge detector. `w_done` coincides with the final
beat event/index 3, and WVALID/busy clear. A one-cycle command while busy is
ignored. Asynchronous reset aborts at any index without fabricating a beat or
final event; a later command restarts at index zero.

Run every public inspection and HDL gate:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_w_burst4_driver.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/axi_w_burst4_driver.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_w_burst4_driver.ppif
./bin/fsmgen --quiet --outdir generated ppif/axi_w_burst4_driver.ppif
./bin/fsmgen --verify-hdl ppif/axi_w_burst4_driver.ppif
```

The outdir contains `generated/axi_w_burst4_driver.isf` and
`generated/axi_w_burst4_driver.fsm` before HDL. The generated actor has ten
inputs, eight outputs, zero procedural states, and seven rules with assignment
counts `13/6/6/6/6/1/1`. Five exact priorities preserve one beat event per
accepted cycle and the final done event. The generated WLAST assertion requires
it to be high exactly when the active presented index is three.

The four-subtest `t/1508-ial2-axi-w-burst4-driver.t` checks the exact report,
source anchors, storage/schedule, fail-closed contracts, support matching,
strict/schedule/semantic/outdir paths, Verilator, Yosys, and executable HDL.
The behavior proof observes three completed bursts plus two transfers from a
reset-aborted burst: exactly 14 handshakes, 14 beat events, three final done
events, one ignored busy command, and one reset abort.

This source still has no address or response channel. AW launch,
`AWLEN=3`/`AWSIZE=2`/INCR and 4-KiB coupling, AW/W joining, B completion,
dynamic/narrow/unaligned/FIXED/WRAP bursts, queues/outstanding writes, and
capacity-core integration remain separate owners.

### Bounded fixed-four-beat AW+W write-request composition

`ppif/axi_write_burst4_request_composition.ppif` ships the additive fixed-four
AW+W request boundary. It reuses the unchanged AW driver and unchanged
fixed-four W driver under one generated join coordinator and a flat structural
top. Completion means that the AW transfer and all four W transfers have been
accepted; it does **not** include B response acceptance or transaction success.

The public command keeps four explicit data/strobe tuples:

```text
(axi-write-burst4-request-composition axi_write_burst4_request_composition
  (role manager-to-subordinate)
  (clock clk)
  (reset (rst_n active_low async))
  (command
    (start write_cmd_valid)
    (address cmd_awaddr width 32)
    (id cmd_awid width 4)
    (data0 cmd_wdata0 width 32)
    (data1 cmd_wdata1 width 32)
    (data2 cmd_wdata2 width 32)
    (data3 cmd_wdata3 width 32)
    (strobe0 cmd_wstrb0 width 4)
    (strobe1 cmd_wstrb1 width 4)
    (strobe2 cmd_wstrb2 width 4)
    (strobe3 cmd_wstrb3 width 4))
  (aw-channel
    (ready awready)
    (valid awvalid)
    (address awaddr width 32)
    (id awid width 4)
    (length awlen width 8)
    (size awsize width 3)
    (burst awburst width 2))
  (w-channel
    (ready wready)
    (valid wvalid)
    (data wdata width 32)
    (strobe wstrb width 4)
    (last wlast))
  (status
    (busy write_busy)
    (beat-done write_beat_done)
    (done write_done)
    (beat-index write_beat_index width 2)))
```

Admission atomically captures the address, ID, and all four payload tuples.
Later input mutation cannot alter an active request. The address must be
four-byte aligned, and its complete 16-byte span must remain within one 4-KiB
region. Thus `0x00000004` and the last legal boundary address `0x00000ff0` are
accepted; `0x00001002` is misaligned and `0x00000ff4` crosses the 4-KiB
boundary. The generated guard and concurrent assertion use the audited
renderer-safe predicate for that exact rule.

AW metadata is fixed to `AWLEN=3`, `AWSIZE=2`, and `AWBURST=INCR`. WVALID is
continuous across accepted beats when WREADY stays high, WLAST is
`0/0/0/1`, and arbitrary four-bit WSTRB—including zero—remains legal on every
beat. `write_beat_done` and its two-bit `write_beat_index` are the unchanged W
child's per-accepted-beat event. Adjacent accepted beats can therefore keep the
event high while the index advances; consume it as a per-cycle event, not only
as a rising edge.

AW and W may complete simultaneously, AW-first, or W-first. The coordinator
remembers each independent child completion and pulses `write_done` only after
both AW and the final W beat have completed. A command offered while busy is
ignored because this boundary has no queue. Asynchronous reset aborts an active
request without fabricating a beat or request-done event; a later command
restarts from W beat zero.

Run every public review and HDL gate:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_write_burst4_request_composition.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/axi_write_burst4_request_composition.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_write_burst4_request_composition.ppif
./bin/fsmgen --quiet --outdir generated ppif/axi_write_burst4_request_composition.ppif
./bin/fsmgen --verify-hdl ppif/axi_write_burst4_request_composition.ppif
```

The review path emits `axi_aw_driver.isf`, `axi_w_burst4_driver.isf`, and
`axi_write_burst4_request_coordinator.isf`, then their three leaf FSMs and
`axi_write_burst4_request_composition.fsm`. The selected C4 top has 29 public
signals, three children, 66 nets, 46 declared links, and 52 resolved links.
The rule-only coordinator has 29 ports, 57 signals, six rules with assignment
counts `16/2/1/1/5/1`, and five realized priorities. Support accounting uses
`intent.ppif_axi_write_burst4_request_composition`; corpus totals are
308 protocol fixtures and 349 supported/strict-supported fixtures.

The four-subtest `t/1509-ial2-axi-write-burst4-request-composition.t` checks
the exact report, eleven anchors, static/residue contract, fail-closed grammar,
support, schedule, semantic topology, outdir artifacts, Verilator, Yosys, and
the executable generated top with assertions both disabled and enabled. Both
runs prove legal address `0x00000004`, boundary address `0x00000ff0`, AW-first,
W-first, stalls, atomic payload capture, one ignored busy command, reset abort,
and recovery at exact totals `AW=5`, `W=18`, `beat=18`, and
`request-done=4`.

B response/full-transaction completion, dynamic burst length, packed or
streaming payload supply, narrow/unaligned/FIXED/WRAP behavior, capacity
integration, queues/outstanding requests, ID allocation/ordering/demux,
decision 0020's transaction interface, aliases, verification output, and
backend/VHDL variants remain explicit residue.

### Bounded one-response B write-response acceptor

`ppif/axi_b_response_acceptor.ppif` is the third shipped initiator primitive.
It is a manager-side receiver: a one-shot upstream arm requests acceptance of
one write response, then the generated actor raises `BREADY` without waiting
for `BVALID`. Exactly one `BVALID && BREADY` handshake captures the four-bit
`BID` and two-bit `BRESP`, clears ready/busy, and leads to one later `b_done`
pulse. An unarmed response is not accepted, and the captured outputs remain
stable until a later accepted response replaces them.

```text
(axi-b-response-acceptor axi_b_response_acceptor
  (role subordinate-to-manager)
  (clock clk)
  (reset (rst_n active_low async))
  (command
    (arm b_accept_cmd_valid))
  (channel
    (valid bvalid)
    (ready bready)
    (id bid width 4)
    (response bresp width 2)
    (captured-id response_bid width 4)
    (captured-response response_bresp width 2)
    (busy b_busy)
    (done b_done)))
```

Run the acceptor through the same public review stages:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_b_response_acceptor.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/axi_b_response_acceptor.ppif
./bin/fsmgen --quiet --outdir generated ppif/axi_b_response_acceptor.ppif
./bin/fsmgen --verify-hdl ppif/axi_b_response_acceptor.ppif
```

The report schema is
`fsmgen.ial2.protocol_intent.axi_b_response_acceptor.v1`, its mode is
`acceptor`, and its `bounded_response` block records one response per arm,
`BID` width 4, `BRESP` width 2, eager ready-after-arm behavior, handshake-edge
capture, stable captured outputs, and the later one-cycle completion pulse.
The outdir contains `generated/axi_b_response_acceptor.isf` and
`generated/axi_b_response_acceptor.fsm` before HDL.

The generated schedule has six states, no compile issues, and exactly three
`accept_b`-over-`arm_b` priority resolutions (`active_q`, `b_busy`, and
`bready`). Its focused generated-HDL regression first proves that unarmed
`BVALID` cannot handshake, then covers an already-high held `BVALID` response
and a second response delayed for four cycles after arming. It requires exactly
two handshakes and two done pulses, correct/stable captured `BID` and `BRESP`,
and final ready/busy low.

This fills the physical B-channel acceptance seam beneath the capacity/status
core, but does not connect that core automatically. Back-to-back buffering,
multiple outstanding responses, extended response signaling, AW/W coordination,
and a complete write transactor remain future work.

### Bounded coordinated AW+W request issue

FSMGen now ships a bounded single-beat AW+W write-request composition. It
reuses the generated `axi_aw_driver` and `axi_w_driver` child modules under a
generated structural top and adds a distinct coordinator that launches both
once, remembers their independent completion pulses, and emits aggregate done
only after both handshakes. The B acceptor remains separate, so aggregate done
at this boundary means **request channels accepted**, not **write response
accepted**.

The aggregate accepts
one idle command containing `cmd_awaddr` (32-bit byte address), `cmd_awid`
(four bits), `cmd_wdata` (32 bits), and `cmd_wstrb` (four bits). Its generated
coordinator captures all four fields atomically before pulsing the two child
starts; direct payload wiring would be unsafe because those registered start
pulses reach the children after a one-shot caller may have changed its inputs.

The structural top supplies fixed AW metadata instead of exposing it as
dynamic aggregate input:

| AW field | Fixed value | Single-beat meaning |
| --- | --- | --- |
| `AWLEN` | `8'd0` | one beat (`AWLEN + 1`) |
| `AWSIZE` | `3'd2` | four bytes per beat |
| `AWBURST` | `2'b01` | INCR encoding |

Admission requires address bits `[1:0]` to be zero. The coordinator both guards
child launch and emits a generated assertion, so a misaligned command launches
neither child when assertions are disabled and is visible as a verification
failure when assertions are enabled. WSTRB remains arbitrary, including the
already-supported all-zero value; narrow/unaligned placement is deferred with
dynamic AWSIZE.

The coordinator is a rule-only generated IAL1 actor. It records whether each
one-cycle child completion has occurred and emits one aggregate done pulse only
when both have been seen. The focused generated-HDL proof passes simultaneous,
AW-first, and W-first completion, atomic payload capture, and misaligned
fail-closed operation, with three AW handshakes, three W handshakes, and three
aggregate done pulses. Aggregate busy covers the
whole join; a one-cycle command while busy is ignored and not queued.

The generated result contains three IAL1 items and schedule
reports (AW child, W child, coordinator), three child IAL0 artifacts, and one
selected structural-top IAL0/HDL entry. Child starts, payload captures, busy,
and done events remain internal except for aggregate `write_busy` and
`write_done` plus the physical AW/W bus ports.

The checked-in public source is
`ppif/axi_write_request_composition.ppif`. Its additive object uses:

```text
(axi-write-request-composition axi_write_request_composition
  (role manager-to-subordinate)
  (clock clk)
  (reset (rst_n active_low async))
  (command
    (start write_cmd_valid)
    (address cmd_awaddr width 32)
    (id cmd_awid width 4)
    (data cmd_wdata width 32)
    (strobe cmd_wstrb width 4))
  (aw-channel
    (ready awready)
    (valid awvalid)
    (address awaddr width 32)
    (id awid width 4)
    (length awlen width 8)
    (size awsize width 3)
    (burst awburst width 2))
  (w-channel
    (ready wready)
    (valid wvalid)
    (data wdata width 32)
    (strobe wstrb width 4)
    (last wlast))
  (status
    (busy write_busy)
    (done write_done)))
```

The selected generator is
`FSM::IAL2::ProtocolIntent::AxiWriteRequestComposition`; schema
`fsmgen.ial2.protocol_intent.axi_write_request_composition.v1`; structural top
`axi_write_request_composition`; coordinator
`axi_write_request_coordinator`; and focused executable owner
`t/1502-ial2-axi-write-request-composition.t`. The top is a three-child C4
composition and remains the only selected HDL entry.

Run the public source directly:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_write_request_composition.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/axi_write_request_composition.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_write_request_composition.ppif
./bin/fsmgen --verify-hdl ppif/axi_write_request_composition.ppif
```

### Full-write transaction composition

FSMGen now ships the bounded single-beat AW+W+B full-write source
`ppif/axi_write_transaction_composition.ppif`. It reuses the shipped AW driver,
W driver, request coordinator, and B acceptor rather than duplicating their
channel state machines. A new response-aware transaction coordinator and
structural top relate one admitted aligned command to exactly one accepted B
response and one full-transaction completion event.

The generated top is a flat five-child C4 composition: AW driver, W driver,
the request coordinator extracted from the existing request-composition
generator, B acceptor, and transaction coordinator. The private nested request
top is intentionally omitted because a `?top` root is not a legal `?fsmc`
child in this lane. The result contains five generated IAL1 review sources and
schedules, five leaf FSMs, and one selected structural-top FSM.

The transaction coordinator captures the aligned public request and AWID,
keeps aggregate busy high through response retirement, and arms B only after
both AW and W have transferred. It exposes request completion separately from
full transaction completion. Captured BID is compared with the retained AWID;
a mismatch is assertion-visible and reports match status false, but the
already-consumed response still terminally completes. Captured BRESP remains a
raw two-bit transaction result—full completion does not imply an OKAY response.

The additive public object is:

```text
(axi-write-transaction-composition axi_write_transaction_composition
  (role manager)
  (clock clk)
  (reset (rst_n active_low async))
  (command
    (start write_cmd_valid)
    (address cmd_awaddr width 32)
    (id cmd_awid width 4)
    (data cmd_wdata width 32)
    (strobe cmd_wstrb width 4))
  ...
  (b-channel
    (valid bvalid)
    (ready bready)
    (id bid width 4)
    (response bresp width 2)
    (captured-id response_bid width 4)
    (captured-response response_bresp width 2))
  (status
    (busy write_busy)
    (request-done write_request_done)
    (transaction-done write_transaction_done)
    (response-id-match response_id_match)))
```

The generator is
`FSM::IAL2::ProtocolIntent::AxiWriteTransactionComposition`, with report schema
`fsmgen.ial2.protocol_intent.axi_write_transaction_composition.v1`, selected
top `axi_write_transaction_composition`, five generated IAL1 schedules, five
leaf FSMs plus the structural top, and focused proof owner
`t/1503-ial2-axi-write-transaction-composition.t`.

The source keeps the public request vocabulary familiar while using private
request/B handoff names inside C4. It arms B at request completion, holds busy
through B retirement, and records ID match from captured BID versus admitted
AWID. A mismatch remains assertion-visible but terminal; raw BRESP determines
the transaction result and full completion does not imply an OKAY response.

Run and inspect the public source directly:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_write_transaction_composition.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/axi_write_transaction_composition.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_write_transaction_composition.ppif
./bin/fsmgen --verify-hdl ppif/axi_write_transaction_composition.ppif
./bin/fsmgen --quiet --strict --outdir .artifacts/ial2/fsmgen-axi-full-write-out ppif/axi_write_transaction_composition.ppif
```

The outdir contains the five `.isf` review sources, five leaf `.fsm` files,
and `axi_write_transaction_composition.fsm`; it does not contain the private
`axi_write_request_private.fsm` top.

The bounded implementation still excludes capacity integration, queues,
multiple outstanding transactions, dynamic ID allocation/ordering, multi-beat
or narrow/unaligned behavior, extended AXI attributes, AR/R, aliases,
verification-output generation, and backend/VHDL variants. The `.axi`
profile-alias spelling remains fail-closed; this first composition surface is
generic `.ppif` only. Decision 0020's protocol-neutral transaction interface
also remains a director-gated future direction.

### Bounded AR read-address driver

`ppif/axi_ar_driver.ppif` is the shipped standalone AXI4 manager read-address
primitive. It captures one idle local command, asserts ARVALID independently
of ARREADY, holds the complete core AR request payload through backpressure,
accepts exactly once, and reports address-request issue rather than read-
transaction completion.

```text
(axi-ar-driver axi_ar_driver
  (role manager-to-subordinate)
  (clock clk)
  (reset (rst_n active_low async))
  (command
    (start ar_cmd_valid)
    (address cmd_araddr width 32)
    (id cmd_arid width 4)
    (length cmd_arlen width 8)
    (size cmd_arsize width 3)
    (burst cmd_arburst width 2)
    (ready arready))
  (channel
    (valid arvalid)
    (address araddr width 32)
    (id arid width 4)
    (length arlen width 8)
    (size arsize width 3)
    (burst arburst width 2)
    (busy ar_busy)
    (done ar_done)))
```

The generator is `FSM::IAL2::ProtocolIntent::AxiArDriver`; the report schema is
`fsmgen.ial2.protocol_intent.axi_ar_driver.v1`. Run every shipped review and
validation surface directly:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_ar_driver.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/axi_ar_driver.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_ar_driver.ppif
./bin/fsmgen --quiet --outdir generated ppif/axi_ar_driver.ppif
./bin/fsmgen --verify-hdl ppif/axi_ar_driver.ppif
```

The review path emits `axi_ar_driver.isf`, then `axi_ar_driver.fsm`, then the
selected HDL module. The generated schedule has 15 interface ports, six exact
transaction states, eight launch assignments, three acceptance assignments,
no compile issues, and three acceptance-over-launch priority resolutions for
the active bit, busy, and ARVALID.

The report's machine-readable `request_scope` records widths 32/4/8/3/2,
`done_event = ar_request_accepted`, and
`includes_read_response = false`. Support accounting identifies the source as
`intent.ppif_axi_ar_driver`; after adding the standalone R-beat source, the
corpus has 304 protocol fixtures and 345 supported/strict-supported fixtures.

The focused generated-HDL proof covers continuously asserted ARREADY, a
four-cycle stall while every upstream command field changes, a command offered
while busy, a one-cycle READY pulse, reset while idle and while stalled, and a
fresh post-reset request. It requires exact totals of three AR handshakes and
three one-cycle done pulses, verifies the captured five-field payload at every
acceptance, ends idle, and passes both Verilator lint and Yosys synthesis.

This remains a request-channel primitive, not a complete AXI manager.
`ar_done` means one AR request was accepted; it does not mean any R beat
arrived or the read completed. The separately shipped bounded R acceptor below
owns raw RREADY/RID/RDATA/RRESP/RLAST capture. The fixed-single-beat full-read
composition now coordinates the two primitives and checks ARID/RID plus
RLAST; broader dynamic legality, repeated beats, and burst completion remain
future work. Legal address/length/size/burst combinations and extended AR
attributes also remain explicit residue.

The larger alternatives remain deferred. Capacity/status
integration needs an explicit physical-to-abstract event/ID adapter and an
outstanding policy; multi-beat or back-to-back writes need queues, counters,
and ordering; expanding the `.axi` alias adds spelling rather than bus-driving
behavior; and decision 0020's protocol-neutral transaction interface remains
director-gated.

### Bounded R read-data beat acceptor

`ppif/axi_r_beat_acceptor.ppif` is the shipped standalone AXI4 manager-side
read-data primitive. It explicitly arms one ownership window, raises RREADY
without waiting for RVALID, captures exactly one raw R beat, then returns idle
and emits a later one-cycle beat-done pulse.

```text
(axi-r-beat-acceptor axi_r_beat_acceptor
  (role subordinate-to-manager)
  (clock clk)
  (reset (rst_n active_low async))
  (command
    (arm r_accept_cmd_valid))
  (channel
    (valid rvalid)
    (ready rready)
    (id rid width 4)
    (data rdata width 32)
    (response rresp width 2)
    (last rlast)
    (captured-id response_rid width 4)
    (captured-data response_rdata width 32)
    (captured-response response_rresp width 2)
    (captured-last response_rlast)
    (busy r_busy)
    (done r_beat_done)))
```

The generator is `FSM::IAL2::ProtocolIntent::AxiRBeatAcceptor`; the report
schema is `fsmgen.ial2.protocol_intent.axi_r_beat_acceptor.v1`, and support
accounting uses `intent.ppif_axi_r_beat_acceptor`. Run all public surfaces
directly:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_r_beat_acceptor.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/axi_r_beat_acceptor.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_r_beat_acceptor.ppif
./bin/fsmgen --quiet --outdir generated ppif/axi_r_beat_acceptor.ppif
./bin/fsmgen --verify-hdl ppif/axi_r_beat_acceptor.ppif
```

The mandatory review path emits `axi_r_beat_acceptor.isf`, then
`axi_r_beat_acceptor.fsm`, then the selected HDL module. The generated schedule
has 13 interface ports, six transaction states, three arm assignments, seven
acceptance assignments, no compile issues, and three acceptance-over-arm
priority resolutions for the active bit, busy, and RREADY.

An idle `r_accept_cmd_valid` arms exactly one beat. While armed, `r_busy` and
RREADY remain high for any number of cycles until `RVALID && RREADY`. That
handshake captures RID4/RDATA32/RRESP2/RLAST1 raw, clears busy/ready, holds the
captured tuple until another accepted beat replaces it, and produces one later
`r_beat_done` pulse. RVALID before arm cannot handshake; holding RVALID high
after the owned handshake cannot cause a second acceptance. A second arm while
busy is ignored rather than queued.

The focused `t/1505-ial2-axi-r-beat-acceptor.t` proof covers unarmed,
already-high and held-high valid, post-accept input mutation, four-cycle
delayed valid, busy-command ignore, idle and active reset, post-reset recovery,
and a one-cycle valid pulse. It requires exactly three handshakes and three
done pulses with exact raw captures, and passes both Verilator and Yosys.

The scope is deliberately one **beat**, not one complete read transaction.
`r_beat_done` does not imply RLAST, successful RRESP, RID/ARID match, ARLEN
satisfaction, or read completion. The full-read composition below supplies the
first bounded AR coordination, ID match, fixed-one-beat RLAST check, and
transaction completion boundary. Repeated or multi-beat receive policy,
general last/length validation, response interpretation, capacity and
outstanding integration, back-to-back buffering, and extended R sidebands
remain explicit future work.

### Bounded fixed-single-beat full-read composition

`ppif/axi_read_transaction_composition.ppif` is the shipped AR+R transaction
surface. The additive object has aggregate role `manager`, asynchronous
active-low reset, and thirteen ordered Issue L source anchors. Its exact public
object is:

```text
(axi-read-transaction-composition axi_read_transaction_composition
  (role manager)
  (clock clk)
  (reset (rst_n active_low async))
  (command
    (start read_cmd_valid)
    (address cmd_read_addr width 32)
    (id cmd_read_id width 4))
  (ar-channel
    (ready arready)
    (valid arvalid)
    (address araddr width 32)
    (id arid width 4)
    (length arlen width 8)
    (size arsize width 3)
    (burst arburst width 2))
  (r-channel
    (valid rvalid)
    (ready rready)
    (id rid width 4)
    (data rdata width 32)
    (response rresp width 2)
    (last rlast)
    (captured-id response_rid width 4)
    (captured-data response_rdata width 32)
    (captured-response response_rresp width 2)
    (captured-last response_rlast))
  (status
    (busy read_busy)
    (request-done read_request_done)
    (transaction-done read_transaction_done)
    (response-id-match response_id_match)
    (response-last-match response_last_match)))
```

The reference generator is
`FSM::IAL2::ProtocolIntent::AxiReadTransactionComposition`, report schema
`fsmgen.ial2.protocol_intent.axi_read_transaction_composition.v1`, support id
`intent.ppif_axi_read_transaction_composition`, and focused test
`t/1506-ial2-axi-read-transaction-composition.t`. Support accounting is 306
protocol fixtures and 347 supported/strict-supported fixtures. Run every
public review and validation surface directly:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_read_transaction_composition.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/axi_read_transaction_composition.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_read_transaction_composition.ppif
./bin/fsmgen --quiet --outdir generated ppif/axi_read_transaction_composition.ppif
./bin/fsmgen --verify-hdl ppif/axi_read_transaction_composition.ppif
```

The shipped architecture reuses the AR driver and R acceptor unchanged under a
new zero-state, seven-rule coordinator and a flat three-child C4 structural
top. One aligned address32/ID4 command privately drives `ARLEN=0`, `ARSIZE=2`,
and `ARBURST=INCR`, issues one AR request, arms R only after AR acceptance, and
retires after exactly one captured R beat. This makes the one-beat completion
claim structurally honest without narrowing the standalone dynamic AR source.

The review path emits three IAL1 artifacts (`axi_ar_driver.isf`,
`axi_r_beat_acceptor.isf`, and `axi_read_transaction_coordinator.isf`), their
three leaf FSMs, and selected top
`axi_read_transaction_composition.fsm`. All three schedules are lowering-clean.
The coordinator has 18 ports, zero procedural states, seven rule decision
trees with assignment counts 6/1/3/1/1/6/1, and four realized pulse-priority
resolutions. Semantic JSON reports 27 public signals, three generated FSM
children, 41 nets, and 44 resolved links. Sized constants reach the AR child,
while captured RID and RLAST safely fan out from the R child to both public
result ports and coordinator checks. Generated SystemVerilog passes Verilator
lint and Yosys synthesis.

The completion boundary is explicit: request-done is the accepted AR request;
transaction-done is the later owned R-beat retirement. Raw RID4/RDATA32/
RRESP2/RLAST1 stays observable, and RRESP does not imply success. RID mismatch
or missing RLAST sets stable match status low and trips a generated assertion,
but remains terminal after the consumed beat instead of hanging for an
impossible replacement.

The executable generated-HDL proof covers misalignment non-launch, fixed
metadata, stalled and continuous ARREADY, stable payload under input mutation,
a busy command, already-high and delayed RVALID, raw non-OKAY capture, terminal
RID and RLAST errors, reset during both a stalled AR and an armed R wait, and
post-reset recovery. It ends idle at exact counts `AR=5`, `R=4`,
`request-done=5`, and `transaction-done=4`; the one-count difference must prove
that reset after AR completion cancels response ownership without fabricating
an R handshake or full completion.

### Bounded fixed-four-beat full-read composition

`ppif/axi_read_burst4_transaction_composition.ppif` ships the first multi-beat
physical read boundary: a fixed-four, full-width INCR composition with
`ARLEN=3`, `ARSIZE=2`, and `ARBURST=INCR`. Its additive public object uses the
same command/AR/R vocabulary as the fixed-single source and extends status
with a raw beat event and index:

```text
(axi-read-burst4-transaction-composition axi_read_burst4_transaction_composition
  (role manager)
  (clock clk)
  (reset (rst_n active_low async))
  (command
    (start read_cmd_valid)
    (address cmd_read_addr width 32)
    (id cmd_read_id width 4))
  (ar-channel
    (ready arready)
    (valid arvalid)
    (address araddr width 32)
    (id arid width 4)
    (length arlen width 8)
    (size arsize width 3)
    (burst arburst width 2))
  (r-channel
    (valid rvalid)
    (ready rready)
    (id rid width 4)
    (data rdata width 32)
    (response rresp width 2)
    (last rlast)
    (captured-id response_rid width 4)
    (captured-data response_rdata width 32)
    (captured-response response_rresp width 2)
    (captured-last response_rlast))
  (status
    (busy read_busy)
    (request-done read_request_done)
    (beat-done read_beat_done)
    (transaction-done read_transaction_done)
    (response-beat-index response_beat_index width 2)
    (response-id-match response_id_match)
    (response-last-match response_last_match)))
```

Admission requires a four-byte-aligned 16-byte span contained within one
4-KiB region. Consequently, an address ending in `...ff0` is legal, while
`...ff4`, `...ff8`, `...ffc`, and misaligned addresses do not launch AR. The
composition reuses the unchanged AR driver and explicitly re-arms one unchanged
one-beat R acceptor four times under a two-bit-index coordinator. This creates
an intentional ready-low bubble between accepted R beats; a subordinate may
hold `RVALID` and its current payload stable across that bubble.

The event stream stays raw. `read_request_done` marks the owned AR handshake;
each `read_beat_done` exposes the newly captured RID/RDATA/RRESP/RLAST tuple and
its `response_beat_index` from zero through three; `read_transaction_done`
retires ownership with the fourth accepted beat. `response_id_match` and
`response_last_match` are sticky across the burst. Beat count is authoritative,
so early RLAST, RID mismatch, and non-OKAY RRESP still drain four transfers;
missing final RLAST retires on the fourth beat with last-match low. RRESP is the
raw current-beat code, not a success bit and not a burst aggregate.

The reference generator is
`FSM::IAL2::ProtocolIntent::AxiReadBurst4TransactionComposition`, report schema
`fsmgen.ial2.protocol_intent.axi_read_burst4_transaction_composition.v1`,
support id `intent.ppif_axi_read_burst4_transaction_composition`, and focused
test `t/1507-ial2-axi-read-burst4-transaction-composition.t`. The structural
top has 29 public signals, three generated children, 48 nets, and 46 resolved
links. Its coordinator has 20 ports, zero procedural states, ten rule decision
trees, and eight realized priorities. Run all public surfaces with:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_read_burst4_transaction_composition.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/axi_read_burst4_transaction_composition.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_read_burst4_transaction_composition.ppif
./bin/fsmgen --quiet --outdir generated ppif/axi_read_burst4_transaction_composition.ppif
./bin/fsmgen --verify-hdl ppif/axi_read_burst4_transaction_composition.ppif
```

The generated-HDL proof covers two illegal addresses, stalled AR plus a busy
command, already-high continuous RVALID, per-beat non-OKAY capture, RID
mismatch, early and missing RLAST, a complete four-beat error drain, delayed
clean beats, reset after one accepted beat, and post-reset recovery. It ends
idle at exact AR/R/request/beat/transaction counts `4/13/4/13/3`; Verilator and
Yosys both pass.

Current correctness caveat: t1507 runs that behavioral harness with
`--no-assert`. The behavioral admission path correctly factors the nested
4-KiB test as `high & (bit3 | bit2)`, but the generated concurrent property
currently inlines it as `high & bit3 | bit2`. SystemVerilog precedence then
falsely rejects legal address `0x00000004`. Parent selector `.832` selects
no-behavior audit `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.1` to isolate a
general AST-preserving renderer contract and freeze assertion-enabled legal-
bit-2 coverage before repair. This caveat concerns the generated assertion,
not the shipped behavioral admission set. See the
[selection record](../../IAL2_POST_DIRECT_VHDL_REDUCTION_NEXT_OWNER_SELECTION.md).

General dynamic bursts, RRESP/output-bank aggregation, malformed-subordinate
timeout/recovery, capacity/status adapter wiring, multiple outstanding and
back-to-back reads, ID queues/demux/interleaving, aliases, and decision 0020's
protocol-neutral transaction interface remain separate later directions.

## More-Control Mode

Move to manager capacity/status when the user needs AXI manager-level control
instead of a single channel monitor.

`ppif/axi_manager_capacity_status.ppif` introduces:

- read and write pending-capacity limits;
- `submit-policy try`;
- abstract read/write submit and completion events;
- status outputs such as can-accept, full, pending, and slots-available.

`ppif/axi_manager_capacity_status_id_family.ppif` adds ID-family metadata:

```text
(id-families
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid))
  (read (width 4) (request-id axi0_arid) (response-id axi0_rid)))
```

`ppif/axi_manager_capacity_status_transaction_envelope.ppif` adds logical
transactions over that capacity/status shell:

```text
(transactions
  (write w0
    (tag wr0)
    (request axi0_write_submit)
    (completion axi0_write_complete)
    (id auto))
  (read r0
    (tag rd0)
    (request axi0_read_submit)
    (completion axi0_read_complete)
    (id (value 3))))
```

Useful more-control probes are:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_id_family.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_transaction_envelope.ppif
```

The schedule report for these manager examples uses
`fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1` and records that
the generated review-artifact formats are `isf` and `fsm`. The transaction
semantic JSON keeps the authored `.ppif` source path and support-accounts the
checked-in transaction-envelope example as
`intent.ppif_axi_manager_capacity_status_transaction_envelope`.

## Raw/Full-Control Mode

The raw/full-control AXI example for this chapter is:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif
```

This checked-in source stays inside one bounded shipped AXI manager family, but
it exposes several explicit controls at once:

- three dynamic read transactions `r0`, `r1`, and `r2`;
- `same-id-ordering` with `dynamic-id-reuse issue-order-queue`;
- burst-last `response-demux` with generated transaction completions;
- multi-beat read-data capture by `RID`;
- raw `ARLEN` burst-length capture with AXI `axlen-plus-one` encoding;
- runtime beat-count/`RLAST` validation;
- per-transaction data/status output-bank prefixes and valid masks.

Validate that deep shape with:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif
```

Use `--emit-schedule-json` or `--outdir` on this family when reviewing a
specific implementation slice. For routine documentation review, the strict
check is usually the fastest proof that the checked-in source still parses and
passes the selected static contract.

## Residue

The shipped AXI IAL2 surface is broad but bounded. The following are not
claimed by this chapter:

- full AXI manager behavior;
- arbitrary cardinalities;
- complete scoreboards;
- authored/general different-ID interleaving beyond selected families;
- broader `.axi` manager profile-alias behavior beyond the selected AW
  Valid-Ready alias;
- direct IAL2-to-HDL or IAL2-to-IAL0 lowering;
- verification-output generation;
- backend-language variants;
- VHDL behavior.

Those items need future task-tree leaves before they can become user-facing
behavior.

## Validation Used For This Chapter

This chapter was validated from checked-in sources with:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_aw_valid_ready.ppif
./bin/fsmgen --quiet --strict --check --json ppif/axi_aw_valid_ready.axi
./bin/fsmgen --quiet --strict --check --json ppif/axi_aw_driver.ppif
./bin/fsmgen --verify-hdl ppif/axi_aw_driver.ppif
./bin/fsmgen --quiet --strict --check --json ppif/axi_w_driver.ppif
./bin/fsmgen --verify-hdl ppif/axi_w_driver.ppif
./bin/fsmgen --quiet --strict --check --json ppif/axi_w_burst4_driver.ppif
./bin/fsmgen --verify-hdl ppif/axi_w_burst4_driver.ppif
./bin/fsmgen --quiet --strict --check --json ppif/axi_write_burst4_request_composition.ppif
./bin/fsmgen --verify-hdl ppif/axi_write_burst4_request_composition.ppif
./bin/fsmgen --quiet --strict --check --json ppif/axi_b_response_acceptor.ppif
./bin/fsmgen --verify-hdl ppif/axi_b_response_acceptor.ppif
./bin/fsmgen --quiet --strict --check --json ppif/axi_ar_driver.ppif
./bin/fsmgen --verify-hdl ppif/axi_ar_driver.ppif
./bin/fsmgen --quiet --strict --check --json ppif/axi_r_beat_acceptor.ppif
./bin/fsmgen --verify-hdl ppif/axi_r_beat_acceptor.ppif
./bin/fsmgen --quiet --strict --check --json ppif/axi_write_request_composition.ppif
./bin/fsmgen --verify-hdl ppif/axi_write_request_composition.ppif
./bin/fsmgen --quiet --strict --check --json ppif/axi_write_transaction_composition.ppif
./bin/fsmgen --verify-hdl ppif/axi_write_transaction_composition.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_id_family.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif
./bin/fsmgen --quiet --outdir .artifacts/ial2/fsmgen-doc-axi-691-out ppif/axi_aw_valid_ready.ppif
```

The temporary outdir probe produced `axi_aw_valid_ready_monitor.isf` and
`axi_aw_valid_ready_monitor.fsm`, confirming that the guided example still
exposes the review artifacts the chapter describes. The nine listed initiator
source checks and `--verify-hdl` runs confirm that six channel primitives plus
the three write compositions are accepted and lower to lint/synthesis-clean HDL. The
focused `t/1499-ial2-axi-aw-driver.t`, `t/1500-ial2-axi-w-driver.t`,
`t/1501-ial2-axi-b-response-acceptor.t`, `t/1504-ial2-axi-ar-driver.t`, and
`t/1505-ial2-axi-r-beat-acceptor.t` generated-HDL simulations separately prove
their transfer/response cardinality, completion-pulse, reset, and stability
guarantees; the W test also proves the all-zero-strobe case remains legal, the
B test proves unarmed responses cannot handshake, and the R test proves exact
raw beat capture across held/delayed valid, busy arm, and active reset. The
four-subtest
`t/1502-ial2-axi-write-request-composition.t` additionally proves the complete
public/report/fail-closed/CLI artifact contract and executes the structural top
for misaligned no-launch, atomic capture, simultaneous-ready, AW-first, W-first,
long-stall stability, ignored-busy-command, zero-strobe, fixed-metadata, and
exact three-AW/three-W/three-done behavior.

The four-subtest `t/1508-ial2-axi-w-burst4-driver.t` proves the additive
fixed-four W path independently: exact report/schedule and fail-closed
contracts, support-accounted CLI/artifact/Verilator/Yosys surfaces, atomic
payload capture, continuous and stalled READY behavior, legal zero strobes,
WLAST `0/0/0/1`, ignored busy command, reset abort/recovery, and exact
14-handshake/14-beat-event/three-completion cardinality.

The four-subtest
`t/1509-ial2-axi-write-burst4-request-composition.t` proves the additive
fixed-four AW+W join end to end: exact report/schedule/static/residue and
fail-closed contracts, 29-signal/three-child/66-net/46-declared-link/
52-resolved-link C4 topology, support-accounted CLI/artifact/Verilator/Yosys
surfaces, renderer-safe legality under assertions, independent AW/W completion,
direct W beat event/index, busy-command ignore, reset abort/recovery, and exact
`5/18/18/4` AW/W/beat/request-done cardinality.

The four-subtest `t/1503-ial2-axi-write-transaction-composition.t` extends that
proof through B retirement. It checks the exact report and fail-closed grammar,
support-accounted strict/schedule/semantic/outdir/Verilator/Yosys surfaces, and
executes the generated five-child top for misaligned no-launch, atomic capture,
simultaneous/AW-first/W-first request completion, already-high and delayed
BVALID, aggregate busy,
ignored busy command, raw non-OKAY BRESP capture, matched BID, terminal
mismatched BID, exact 3/3/3 AW/W/B handshakes, distinct request/transaction
pulses, and final idle.
