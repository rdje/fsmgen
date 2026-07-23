# IAL2 AXI manager initiator — fixed-four write-request composition contract selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.45` (behavior-neutral contract
selection).

Date: 2026-07-23

Status: exact public/generator/report/test contract selected. The following
leaf, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.46`, owns implementation.

This selector changes no parser, generator, public source, support-accounting
entry, capability manifest, test, generated artifact, runtime behavior, or HDL
behavior.

## 1. Selected identity

| Facet | Selected value |
| --- | --- |
| PPIF clause/object | `(axi-write-burst4-request-composition ...)` / `axi-write-burst4-request-composition` |
| parser contract `kind` | `axi_write_burst4_request_composition` |
| generator | `FSM::IAL2::ProtocolIntent::AxiWriteBurst4RequestComposition` |
| generated result `kind` | `protocol_intent.axi_write_burst4_request_composition` |
| report schema | `fsmgen.ial2.protocol_intent.axi_write_burst4_request_composition.v1` |
| result mode | `write-burst4-request-composition` |
| public source | `ppif/axi_write_burst4_request_composition.ppif` |
| intent/object/top | `axi_write_burst4_request_composition` |
| request coordinator | `axi_write_burst4_request_coordinator` |
| selected IAL0/HDL entry | `axi_write_burst4_request_composition.fsm` |
| support id | `intent.ppif_axi_write_burst4_request_composition` |
| coverage key | `ial2_ppif_axi_write_burst4_request_composition_pipeline_cli` |
| focused test | `t/1509-ial2-axi-write-burst4-request-composition.t` |
| executable fixture | `t/data/axi_write_burst4_request_composition_tb.svt` |

`burst4` is mandatory in every new identity. Fixed four is an explicit
cardinality, not the default for a future general write request. The family is
additive to `(axi-write-request-composition ...)`; the existing fixed-single
source, generator, schema, support id, t/1502, and behavior remain unchanged.

The role is exactly `manager-to-subordinate`: the composition drives AW and W
and samples AWREADY/WREADY. Aggregate done is request-channel completion only,
not B response or full transaction completion.

## 2. Exact public source

```text
(protocol-platform-intent axi_write_burst4_request_composition
  (profile axi4)
  (source
    (object axi-write-burst4-request-composition)
    (anchor (document IHI0022_L_2025-08) (section A3.2.1) (page A3-40))
    (anchor (document IHI0022_L_2025-08) (section A2.3) (page 29))
    (anchor (document IHI0022_L_2025-08) (section A2.3.1) (page 30))
    (anchor (document IHI0022_L_2025-08) (section A2.3.2.1) (page 31))
    (anchor (document IHI0022_L_2025-08) (section A3.1) (page 42))
    (anchor (document IHI0022_L_2025-08) (section A3.1.1) (page 43))
    (anchor (document IHI0022_L_2025-08) (section A3.1.2) (page 44))
    (anchor (document IHI0022_L_2025-08) (section A3.1.4) (page 46))
    (anchor (document IHI0022_L_2025-08) (section A3.2.1) (page 53))
    (anchor (document IHI0022_L_2025-08) (section A3.2.1.1) (page 54))
    (anchor (document IHI0022_L_2025-08) (section B1.1.2) (page 277)))
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
      (beat-index write_beat_index width 2))))
```

All eleven anchors are mandatory and ordered. The first legacy-numbered AW
anchor stays first for continuity with the shipped write composition; the ten
Issue L numbered pages add dependency, burst/cardinality, 4-KiB, WLAST, and
direction ownership.

### Public semantics

- `write_cmd_valid` is level-sampled only while aggregate and both children
  are idle; there is no queue or ready output.
- address32, ID4, and all four data32/strobe4 tuples capture atomically.
- the address must be four-byte aligned and its 16-byte span must remain within
  one 4-KiB region.
- AW metadata is fixed to LEN3/SIZE2/INCR.
- the AW and W children start once and progress independently.
- `write_busy` spans legal admission through the joined child completion.
- `write_beat_done` and `write_beat_index[1:0]` are the unchanged W child's
  direct accepted-transfer event and index.
- `write_done` pulses once after AW completion and final W completion have both
  been observed, in either order.
- arbitrary WSTRB is preserved per beat, including zero.
- reset aborts without fabricating beat or request completion.

`write_done` does not assert BREADY, consume BID/BRESP, or imply success.

## 3. Parser contract and alias policy

`_contract_from_root` gains an
`@axi_write_burst4_request_compositions` accumulator and exact clause arm. It
requires one object, adds it to every standalone/aggregate mixing count and
the missing-intent enumeration, and rejects mixing with fixed-single write or
read compositions, standalone AXI channel objects, capacity/status,
Valid-Ready, AHB, or APB.

`_parse_axi_write_burst4_request_composition` requires exactly one of:

```text
role clock reset command aw-channel w-channel status
```

Block shapes are exact:

```text
command:    start=scalar, address=width, id=width,
            data0..data3=width, strobe0..strobe3=width
aw-channel: ready=scalar, valid=scalar, address=width, id=width,
            length=width, size=width, burst=width
w-channel:  ready=scalar, valid=scalar, data=width, strobe=width,
            last=scalar
status:     busy=scalar, beat-done=scalar, done=scalar,
            beat-index=width
```

The normalized hash is:

```text
kind       = axi_write_burst4_request_composition
name       = <object name>
role       = manager-to-subordinate
clock/reset/protocol/source/intent_name
command    = { start, address{name,width}, id{name,width},
               data0..data3{name,width}, strobe0..strobe3{name,width} }
aw_channel = { ready, valid, address, id, length, size, burst }
w_channel  = { ready, valid, data, strobe, last }
status     = { busy, beat_done, done, beat_index{name,width} }
```

Unknown, duplicate, missing, packed, streaming, authored metadata/cardinality,
B response, or nested-child vocabulary fails before generation.

The generic `.ppif` surface ships alone. `.axi` validation rejects with:

```text
(axi-write-burst4-request-composition ...) remains unsupported for the first profile-alias implementation
```

No alias fixture, support entry, or manifest claim is added.

## 4. Generator normalization and private namespace

The generator pins exact kind, profile `axi4`, role, asynchronous active-low
reset, eleven anchors, and these widths:

```text
command: address32, ID4, four data32, four strobe4
AW:      address32, ID4, length8, size3, burst2
W:       data32, strobe4
status:  beat-index2; all other bindings scalar
```

All public bindings are distinct from this fixed private namespace:

```text
aw_cmd_valid_i  aw_cmd_addr_i  aw_cmd_id_i  aw_busy_i  aw_done_i
w_cmd_valid_i   w_cmd_data0_i  w_cmd_data1_i w_cmd_data2_i w_cmd_data3_i
w_cmd_strb0_i   w_cmd_strb1_i  w_cmd_strb2_i w_cmd_strb3_i
w_busy_i        w_done_i
active_q        aw_seen_q      w_seen_q      can_accept
aw_driver       w_driver       coordinator
```

Reserve the three actor names, three instance names, all leaf/top artifact
names, and every unchanged-child private register. Authored collisions fail
before a partial generated file map escapes.

Required generator diagnostic substrings include:

| Invalid contract | Required substring |
| --- | --- |
| wrong kind | `AXI write burst4 request composition IAL2 contract kind must be axi_write_burst4_request_composition` |
| wrong profile | `AXI write burst4 request composition IAL2 contract profile must be axi4 in this slice` |
| wrong role | `AXI write burst4 request composition IAL2 contract role must be manager-to-subordinate` |
| wrong reset | `AXI write burst4 request composition reset must be asynchronous active-low in this slice` |
| wrong address/ID width | exact `command.address.width must be 32` / `command.id.width must be 4` |
| wrong tuple width | exact `command.dataN.width must be 32` / `command.strobeN.width must be 4` |
| wrong channel width | identify exact `aw_channel.*` or `w_channel.*` fixed width |
| wrong index width | `status.beat_index.width must be 2 in this slice` |
| duplicate name | `AXI write burst4 request composition IAL2 contract duplicates signal '<name>'` |
| unsupported option | identify the option and permit only `debug` |

Parser errors identify exact missing/duplicate/unknown blocks and fields;
root errors identify cardinality, mixing, profile, and object family.

## 5. Exact unchanged-child contracts

Invoke `AxiAwDriver->generate` once with:

```text
aw_cmd_valid_i, aw_cmd_addr_i32, aw_cmd_id_i4,
cmd_awlen8, cmd_awsize3, cmd_awburst2, awready
  -> awvalid, awaddr32, awid4, awlen8, awsize3, awburst2,
     aw_busy_i, aw_done_i
```

The top connects `8'd3`, `3'd2`, and `2'b01` to the metadata inputs. Preserve
the AW generator's six-state schedule, report, and source-anchor subset.

Invoke `AxiWBurst4Driver->generate` once with:

```text
w_cmd_valid_i,
w_cmd_data0_i32..w_cmd_data3_i32,
w_cmd_strb0_i4..w_cmd_strb3_i4, wready
  -> wvalid, wdata32, wstrb4, wlast,
     w_busy_i, write_beat_done, w_done_i, write_beat_index2
```

The beat event/index bind directly to public aggregate status. Preserve the W
child's zero-state seven-rule schedule, WLAST assertion, payload storage,
report, and source-anchor subset. The aggregate generator emits only the new
coordinator behavior and structural top; it does not copy either child actor.

## 6. Exact renderer-safe legality predicate

Admission and the assertion consequent use exactly:

```text
(& (! cmd_awaddr[0])
   (! cmd_awaddr[1])
   (! (& cmd_awaddr[11] cmd_awaddr[10] cmd_awaddr[9]
         cmd_awaddr[8] cmd_awaddr[7] cmd_awaddr[6]
         cmd_awaddr[5] cmd_awaddr[4] cmd_awaddr[3]))
   (! (& cmd_awaddr[11] cmd_awaddr[10] cmd_awaddr[9]
         cmd_awaddr[8] cmd_awaddr[7] cmd_awaddr[6]
         cmd_awaddr[5] cmd_awaddr[4] cmd_awaddr[2])))
```

This is exhaustively equivalent over all 4,096 low-address values to
`aligned && low12 <= 12'hff0`. It accepts legal bit2-high address `0x00000004`
and `...0ff0`, and rejects misalignment plus `...0ff4`, `...0ff8`, `...0ffc`.
Do not replace it with the nested-OR spelling while the proposed general
assertion precedence repair is inactive.

## 7. Exact coordinator IAL1

Binding substitution is allowed; structure and policy are exact:

```text
(actor axi_write_burst4_request_coordinator
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input write_cmd_valid)
    (input cmd_awaddr (width 32))
    (input cmd_awid (width 4))
    (input cmd_wdata0 (width 32))
    (input cmd_wdata1 (width 32))
    (input cmd_wdata2 (width 32))
    (input cmd_wdata3 (width 32))
    (input cmd_wstrb0 (width 4))
    (input cmd_wstrb1 (width 4))
    (input cmd_wstrb2 (width 4))
    (input cmd_wstrb3 (width 4))
    (input aw_busy_i)
    (input aw_done_i)
    (input w_busy_i)
    (input w_done_i)
    (output aw_cmd_valid_i)
    (output aw_cmd_addr_i (width 32))
    (output aw_cmd_id_i (width 4))
    (output w_cmd_valid_i)
    (output w_cmd_data0_i (width 32))
    (output w_cmd_data1_i (width 32))
    (output w_cmd_data2_i (width 32))
    (output w_cmd_data3_i (width 32))
    (output w_cmd_strb0_i (width 4))
    (output w_cmd_strb1_i (width 4))
    (output w_cmd_strb2_i (width 4))
    (output w_cmd_strb3_i (width 4))
    (output write_busy)
    (output write_done))

  (priority finish_join over latch_aw)
  (priority finish_join over latch_w)
  (priority finish_join over admit)
  (priority finish_join over clear_done)
  (priority admit over latch_aw)
  (priority admit over latch_w)
  (priority admit over clear_child_starts)

  (rule admit
    (& (! active_q) (! aw_busy_i) (! w_busy_i) write_cmd_valid
       (! cmd_awaddr[0]) (! cmd_awaddr[1])
       (! (& cmd_awaddr[11] cmd_awaddr[10] cmd_awaddr[9]
             cmd_awaddr[8] cmd_awaddr[7] cmd_awaddr[6]
             cmd_awaddr[5] cmd_awaddr[4] cmd_awaddr[3]))
       (! (& cmd_awaddr[11] cmd_awaddr[10] cmd_awaddr[9]
             cmd_awaddr[8] cmd_awaddr[7] cmd_awaddr[6]
             cmd_awaddr[5] cmd_awaddr[4] cmd_awaddr[2])))
    (set active_q 1)
    (set aw_seen_q 0)
    (set w_seen_q 0)
    (set aw_cmd_valid_i 1)
    (set aw_cmd_addr_i cmd_awaddr)
    (set aw_cmd_id_i cmd_awid)
    (set w_cmd_valid_i 1)
    (set w_cmd_data0_i cmd_wdata0)
    (set w_cmd_data1_i cmd_wdata1)
    (set w_cmd_data2_i cmd_wdata2)
    (set w_cmd_data3_i cmd_wdata3)
    (set w_cmd_strb0_i cmd_wstrb0)
    (set w_cmd_strb1_i cmd_wstrb1)
    (set w_cmd_strb2_i cmd_wstrb2)
    (set w_cmd_strb3_i cmd_wstrb3)
    (set write_busy 1))

  (rule clear_child_starts (| aw_cmd_valid_i w_cmd_valid_i)
    (set aw_cmd_valid_i 0)
    (set w_cmd_valid_i 0))

  (rule latch_aw (& active_q aw_done_i)
    (set aw_seen_q 1))

  (rule latch_w (& active_q w_done_i)
    (set w_seen_q 1))

  (rule finish_join
    (& active_q (| aw_seen_q aw_done_i) (| w_seen_q w_done_i))
    (set active_q 0)
    (set aw_seen_q 0)
    (set w_seen_q 0)
    (set write_busy 0)
    (set write_done 1))

  (rule clear_done write_done
    (set write_done 0))

  (transaction aligned_boundary_command_check
    (assert
      (=> (& (! active_q) (! aw_busy_i) (! w_busy_i) write_cmd_valid)
          (& (! cmd_awaddr[0]) (! cmd_awaddr[1])
             (! (& cmd_awaddr[11] cmd_awaddr[10] cmd_awaddr[9]
                   cmd_awaddr[8] cmd_awaddr[7] cmd_awaddr[6]
                   cmd_awaddr[5] cmd_awaddr[4] cmd_awaddr[3]))
             (! (& cmd_awaddr[11] cmd_awaddr[10] cmd_awaddr[9]
                   cmd_awaddr[8] cmd_awaddr[7] cmd_awaddr[6]
                   cmd_awaddr[5] cmd_awaddr[4] cmd_awaddr[2]))))
      "fixed-four AXI INCR write request must be four-byte aligned and remain within 4 KiB")))
```

The exact actor has 15 inputs, 14 outputs, 29 ports, 57 lowered signals, zero
states, `compile_issues=[]`, and six decision trees:

```text
admit                16
clear_child_starts    2
latch_aw              1
latch_w               1
finish_join            5
clear_done             1
```

All seven authored priority declarations remain. Five realized resolutions
are exact:

```text
admit       > clear_child_starts : aw_cmd_valid_i
finish_join > latch_aw           : aw_seen_q
admit       > clear_child_starts : w_cmd_valid_i
finish_join > latch_w            : w_seen_q
finish_join > clear_done         : write_done
```

Compatible same-value fan-in is exact for `aw_seen_q=0` and `w_seen_q=0` from
`admit` plus `finish_join`. No beat counter or beat event regeneration is
permitted in the coordinator.

## 8. Exact flat C4 top

Child and instance order is:

```text
(?fsmc:aw_driver axi_aw_driver)
(?fsmc:w_driver axi_w_burst4_driver)
(?fsmc:coordinator axi_write_burst4_request_coordinator)
```

The 29 public ports, in order, are `clk`, `rst_n`; inputs
`write_cmd_valid`, `cmd_awaddr<32`, `cmd_awid<4`, `cmd_wdata0<32` through
`cmd_wdata3<32`, `cmd_wstrb0<4` through `cmd_wstrb3<4`, `awready`, `wready`;
outputs `awvalid`, `awaddr>32`, `awid>4`, `awlen>8`, `awsize>3`, `awburst>2`,
`wvalid`, `wdata>32`, `wstrb>4`, `wlast`, `write_busy`, `write_beat_done`,
`write_done`, and `write_beat_index>2`.

Explicit wiring is exact:

```text
(aw_driver.aw_busy_i coordinator.aw_busy_i)
(aw_driver.aw_done_i coordinator.aw_done_i)
(w_driver.w_busy_i coordinator.w_busy_i)
(w_driver.w_done_i coordinator.w_done_i)
(coordinator.aw_cmd_valid_i aw_driver.aw_cmd_valid_i)
(coordinator.aw_cmd_addr_i aw_driver.aw_cmd_addr_i)
(coordinator.aw_cmd_id_i aw_driver.aw_cmd_id_i)
(=8'd3 aw_driver.cmd_awlen)
(=3'd2 aw_driver.cmd_awsize)
(=2'b01 aw_driver.cmd_awburst)
(coordinator.w_cmd_valid_i w_driver.w_cmd_valid_i)
(coordinator.w_cmd_data0_i w_driver.w_cmd_data0_i)
(coordinator.w_cmd_data1_i w_driver.w_cmd_data1_i)
(coordinator.w_cmd_data2_i w_driver.w_cmd_data2_i)
(coordinator.w_cmd_data3_i w_driver.w_cmd_data3_i)
(coordinator.w_cmd_strb0_i w_driver.w_cmd_strb0_i)
(coordinator.w_cmd_strb1_i w_driver.w_cmd_strb1_i)
(coordinator.w_cmd_strb2_i w_driver.w_cmd_strb2_i)
(coordinator.w_cmd_strb3_i w_driver.w_cmd_strb3_i)
```

All other links are exact same-name public/system binding. Semantic truth is:

```text
signal_count=29
composition_child_count=3
composition_net_count=66
composition_declared_link_count=46
composition_resolved_link_count=52
lane=C4
```

The generated result has three ordered IAL1 items/schedule reports, three leaf
IAL0 FSMs, and one selected top. Artifact names are:

```text
axi_aw_driver.isf / axi_aw_driver.fsm
axi_w_burst4_driver.isf / axi_w_burst4_driver.fsm
axi_write_burst4_request_coordinator.isf
axi_write_burst4_request_coordinator.fsm
axi_write_burst4_request_composition.fsm  # generated_composition_top, selected
```

## 9. Lifecycle and completion

One legal idle command owns one AW transfer and four W transfers. Both starts
are one-cycle pulses sourced by the coordinator's captured outputs. AW and W
may accept in the same or different cycles. Each later child done event either
completes the join immediately when the other side is already remembered or
sets its one-bit history.

WVALID, payload progression, stall stability, WLAST `0/0/0/1`, beat events,
and final W done remain the W child contract. AWVALID/payload stability and
exactly-one AW acceptance remain the AW child contract. The coordinator owns
only aggregate capture/start/history/busy/request-done.

A command while busy is ignored. Reset during AW stall, W stall, after AW,
mid-W burst, or before join aborts all three actors and emits no completion.
The system-level environment is responsible for quiescing the subordinate
across reset, matching the shipped child assumption. Recovery starts fresh.

## 10. Report and static contract

Schema `fsmgen.ial2.protocol_intent.axi_write_burst4_request_composition.v1`
contains:

- `mode=write-burst4-request-composition`;
- `layering` with generated ISF/FSM and `direct_ial2_to_ial0=false`;
- exact source object/intent/eleven anchors and target profile/object/role;
- cloned command/AW/W/status bindings;
- `fixed_four_request_policy` with address width 32, ID width 4, data width
  32, strobe width 4, beat count 4, alignment 4, span 16, 4-KiB containment,
  AWLEN 3, AWSIZE 2, AWBURST 1/INCR, explicit tuple authoring, atomic capture,
  direct beat event/index, and request completion after both children;
- child reuse, coordinator schedule/history/reset policy, and measured C4;
- three child reports and schedule reports;
- exact artifacts/selected top; and
- ordered enforced-static and unsupported-residue arrays.

The exact fifteen enforced-static details are:

1. `AXI4 manager-to-subordinate fixed-four AW+W request composition`;
2. `shared clock and asynchronous active-low reset across all three children`;
3. `idle command atomically captures address32 ID4 and four explicit data32 strobe4 tuples`;
4. `admission requires four-byte alignment and a 16-byte span contained within one 4-KiB region`;
5. `AW metadata is fixed to LEN3 SIZE2 INCR`;
6. `flat C4 reuses unchanged AW and W-burst4 actors plus one join coordinator`;
7. `one admitted command emits one one-cycle start to each child`;
8. `AW and final-W completions are independently remembered and joined`;
9. `one active request ignores busy commands and has no queue`;
10. `W beat event and index are direct unchanged-child outputs`;
11. `request done excludes B response acceptance and transaction success`;
12. `arbitrary per-beat WSTRB including zero remains legal`;
13. `reset aborts without phantom beat or request completion and recovery restarts`;
14. `selected top is the exact 29-signal 3-child 66-net 46-declared-link 52-resolved-link C4 composition`; and
15. `lowering uses three generated IAL1 and leaf IAL0 actors plus one structural top never direct IAL2-to-IAL0`.

## 11. Exact residue

The fourteen IDs and detail policies are:

| ID | Exact detail |
| --- | --- |
| `axi_write_burst4_request_composition_b_response_full_transaction_deferred` | `B arming BID BRESP and full write-transaction completion remain separate` |
| `axi_write_burst4_request_composition_dynamic_burst_deferred` | `authored or dynamic length and variable payload cardinality remain unsupported` |
| `axi_write_burst4_request_composition_narrow_unaligned_wrap_attributes_deferred` | `narrow unaligned FIXED WRAP and extended AW attributes remain unsupported` |
| `axi_write_burst4_request_composition_packed_streaming_payload_deferred` | `packed banks and streaming producer handshakes remain unsupported` |
| `axi_write_burst4_request_composition_capacity_core_integration_deferred` | `capacity submit completion and storage integration remain separate` |
| `axi_write_burst4_request_composition_outstanding_queueing_deferred` | `back-to-back buffering queues and multiple outstanding requests remain unsupported` |
| `axi_write_burst4_request_composition_id_allocation_ordering_demux_deferred` | `ID allocation reuse ordering response demux and interleaving remain separate` |
| `axi_write_burst4_request_composition_malformed_subordinate_recovery_deferred` | `timeout abort retry and bus resynchronization policy remain unsupported` |
| `axi_write_burst4_request_composition_response_aggregation_output_banks_deferred` | `response aggregation and output banks are not request-composition responsibilities` |
| `axi_write_burst4_request_composition_transaction_interface_deferred` | `decision 0020 protocol-neutral transaction interface remains director-gated` |
| `axi_write_burst4_request_composition_profile_alias_deferred` | `the .axi alias remains unsupported for this object` |
| `axi_write_burst4_request_composition_verification_output_deferred` | `direct verification-output generation remains unsupported` |
| `axi_write_burst4_request_composition_backend_variants_deferred` | `direct backend VHDL and backend-language variants remain unchanged` |
| `axi_write_burst4_request_composition_other_protocols_unchanged` | `AHB and APB parsing lowering artifacts and behavior remain unchanged` |

## 12. Exact t/1509 proof

Support totals become 308 protocol fixtures, 349 supported fixtures, and 349
strict-supported fixtures. The support classification is `supported_smoke`
and family `protocol_fixture`; no alias fixture is added.

Exactly four top-level subtests are required:

1. public parse/report/eleven anchors, child/coordinator schedules, artifacts,
   static/residue, and exact C4 counts;
2. constructor/generator/PPIF/cardinality/mixing/width/name/alias failures;
3. support-accounted strict check, schedule JSON, semantic JSON, outdir,
   Verilator, and Yosys;
4. assertion-disabled illegal-address behavior and assertion-enabled legal
   generated-top behavior.

The executable fixture must observe exact totals:

```text
PASS aw=5 w=18 beat=18 done=4 illegal=2 busy_ignored=1 reset_abort=1
```

Scenarios are misaligned and aligned crossing no-launch; legal bit2-high
`0x00000004`; legal terminal `0x00000ff0`; fixed metadata; atomic payload
mutation; continuous ready; W-first then delayed AW; AW-first with individually
pulsed W transfers; stable stalls; busy command rejection; reset after AW plus
two W transfers; recovery; exact beat indices/WLAST; and final idle. Compile
the negative run with assertions disabled and the all-legal run with assertions
enabled so the safe predicate is tested without suppressing verification.

Focused preservation is t/1499+t/1500+t/1502+t/1503+t/1507+t/1508 plus
t/248+t/297. Public strict/schedule/semantic/outdir/verify-HDL, mdBook,
Knowledge Map, Memory, docs paths, whitespace, and doctrines are mandatory.

## 13. Implementation owner and rollback

`.46` atomically owns:

- new `AxiWriteBurst4RequestComposition.pm`;
- additive PPIF parser/import/dispatch/cardinality/mixing/missing-intent/alias
  wiring;
- exact public source;
- support and manifest entries at 308/349/349;
- t/1509 plus tracked executable fixture;
- shipped mdBook documentation and behavior fact;
- task/index/Memory/Knowledge Map synchronization and probe cleanup; and
- all focused/public/continuity/doctrine validation above.

No implementation may generalize the fixed-single generator in place, change
either child, add B, or repair the separately proposed assertion renderer tree.

Selector rollback removes this note and its fact card, restores `.45` active,
removes `.46`, and restores task/index/book/Memory pointers. No behavior
rollback is required because `.45` changes no shipped source or code.
