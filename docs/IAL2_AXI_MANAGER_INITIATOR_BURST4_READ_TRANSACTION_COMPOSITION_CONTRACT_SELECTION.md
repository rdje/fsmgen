# IAL2 AXI manager initiator — fixed-four read transaction composition contract selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.37` (behavior-neutral contract
selection).

Date: 2026-07-23

Status: exact public/generator/report/test contract selected. The following
leaf, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.38`, owns implementation.

This selector changes no parser, generator, public source, support-accounting
entry, capability manifest, test, generated artifact, runtime behavior, or HDL
behavior.

## 1. Selected identity

| Facet | Selected value |
| --- | --- |
| PPIF clause/object | `(axi-read-burst4-transaction-composition ...)` / `axi-read-burst4-transaction-composition` |
| parser contract `kind` | `axi_read_burst4_transaction_composition` |
| generator | `FSM::IAL2::ProtocolIntent::AxiReadBurst4TransactionComposition` |
| generated result `kind` | `protocol_intent.axi_read_burst4_transaction_composition` |
| report schema | `fsmgen.ial2.protocol_intent.axi_read_burst4_transaction_composition.v1` |
| result mode | `read-burst4-transaction-composition` |
| public source | `ppif/axi_read_burst4_transaction_composition.ppif` |
| intent/object/top | `axi_read_burst4_transaction_composition` |
| transaction coordinator | `axi_read_burst4_transaction_coordinator` |
| selected IAL0/HDL entry | `axi_read_burst4_transaction_composition.fsm` |
| support id | `intent.ppif_axi_read_burst4_transaction_composition` |
| coverage key | `ial2_ppif_axi_read_burst4_transaction_composition_pipeline_cli` |
| focused test | `t/1507-ial2-axi-read-burst4-transaction-composition.t` |
| executable fixture | `t/data/axi_read_burst4_transaction_composition_tb.svt` |

The parser contract kind is unprefixed; only the generated result kind has the
`protocol_intent.` prefix. `burst4` is part of every new identity because the
cardinality is fixed, not a default for a future general read transaction.
The shipped fixed-single-beat object's identities and behavior do not change.

The aggregate role is exactly `manager`: it drives AR and RREADY and receives
ARREADY plus the R payload. Either single-channel directional role is rejected.

## 2. Exact public source

```text
(protocol-platform-intent axi_read_burst4_transaction_composition
  (profile axi4)
  (source
    (object axi-read-burst4-transaction-composition)
    (anchor (document IHI0022_L_2025-08) (section A2.3) (page 29))
    (anchor (document IHI0022_L_2025-08) (section A2.3.1) (page 30))
    (anchor (document IHI0022_L_2025-08) (section A2.3.2.2) (page 32))
    (anchor (document IHI0022_L_2025-08) (section A2.6) (page 41))
    (anchor (document IHI0022_L_2025-08) (section A3.1) (page 42))
    (anchor (document IHI0022_L_2025-08) (section A3.1.1) (page 43))
    (anchor (document IHI0022_L_2025-08) (section A3.1.2) (page 44))
    (anchor (document IHI0022_L_2025-08) (section A3.1.4) (page 46))
    (anchor (document IHI0022_L_2025-08) (section A3.2.2) (page 55))
    (anchor (document IHI0022_L_2025-08) (section A3.3.2) (page 62))
    (anchor (document IHI0022_L_2025-08) (section A5.1.1) (page 90))
    (anchor (document IHI0022_L_2025-08) (section B1.2.1) (page 279))
    (anchor (document IHI0022_L_2025-08) (section B1.2.2) (page 281)))
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
      (response-last-match response_last_match))))
```

All thirteen anchors are mandatory and ordered. The source object is the
hyphenated clause identity, not the actor name.

### Public semantics

- `read_cmd_valid` is a level-sampled idle request, not a queue.
- address32 and ID4 capture atomically only when the address is four-byte
  aligned and the complete 16-byte span stays within one 4-KiB region.
- AR metadata is always LEN3/SIZE2/INCR, describing exactly four 32-bit words.
- `read_busy` covers admission through the fourth accepted response beat.
- `read_request_done` pulses once after AR acceptance and with the first R-arm
  handoff.
- `read_beat_done` pulses once after each of four raw captures.
- `response_beat_index[1:0]` is 0, 1, 2, then 3 for those events.
- `read_transaction_done` pulses with the fourth beat event.
- captured RID4/RDATA32/RRESP2/RLAST1 holds the newest raw tuple.
- `response_id_match` is initialized true per admission and becomes sticky
  false after any captured RID differs from retained ARID.
- `response_last_match` is initialized true and becomes sticky false unless
  RLAST is low on indices 0-2 and high on index 3.
- count is the only functional retirement authority: mismatch and non-OKAY
  status drain to the fourth accepted beat.
- transaction done does not imply OKAY RRESP or usable error RDATA.

There is no public RRESP aggregate or success flag. A consumer samples raw
RRESP with each beat event.

## 3. Parser contract and alias policy

`_contract_from_root` gains an
`@axi_read_burst4_transaction_compositions` accumulator and one
`axi-read-burst4-transaction-composition` arm. Root policy:

- dispatch only under the AXI profile family, with exact `axi4` pinned by the
  generator;
- require exactly one burst4 object;
- reject mixing with the fixed-single full read, standalone AR/R, both write
  compositions, standalone AW/W/B, capacity/status, Valid-Ready, APB, or AHB;
- add the object to every existing standalone/aggregate mixing count; and
- include it in the missing-intent enumeration.

`_parse_axi_read_burst4_transaction_composition` requires exactly one of each:

```text
role clock reset command ar-channel r-channel status
```

Block shapes are exact:

```text
command:    start=scalar, address=width, id=width
ar-channel: ready=scalar, valid=scalar, address=width, id=width,
            length=width, size=width, burst=width
r-channel:  valid=scalar, ready=scalar, id=width, data=width,
            response=width, last=scalar, captured-id=width,
            captured-data=width, captured-response=width,
            captured-last=scalar
status:     busy=scalar, request-done=scalar, beat-done=scalar,
            transaction-done=scalar, response-beat-index=width,
            response-id-match=scalar, response-last-match=scalar
```

Hyphenated names normalize to underscore keys. The returned contract is:

```text
kind       = axi_read_burst4_transaction_composition
name       = <object name>
role       = manager
clock/reset/protocol/source/intent_name
command    = { start, address{name,width}, id{name,width} }
ar_channel = { ready, valid, address, id, length, size, burst }
r_channel  = { valid, ready, id, data, response, last,
               captured_id, captured_data, captured_response,
               captured_last }
status     = { busy, request_done, beat_done, transaction_done,
               response_beat_index{name,width}, response_id_match,
               response_last_match }
```

The source is generic `.ppif` only. `_validate_profile_alias_contract` rejects
with this exact message:

```text
(axi-read-burst4-transaction-composition ...) remains unsupported for the first profile-alias implementation
```

No `.axi` fixture, support entry, or advertised alias is added.

## 4. Generator normalization and private namespace

The generator pins:

- kind, profile `axi4`, role `manager`, and asynchronous active-low reset;
- command address32/ID4;
- AR address32/ID4/length8/size3/burst2;
- R bus and captured ID4/data32/response2 plus scalar handshake/last;
- scalar busy/request-done/beat-done/transaction-done/ID-match/last-match;
- response beat index width 2; and
- exactly thirteen normalized source anchors.

All public names are distinct from each other and this fixed private set:

```text
ar_cmd_valid_i  ar_cmd_addr_i   ar_cmd_id_i
ar_busy_i       ar_done_i       r_arm_i
r_busy_i        r_done_i        captured_rid_i
captured_rlast_i
active_q        expected_arid_q response_armed_q beat_index_q
```

Reserve child command/status names, actor names, instance names, and artifact
names exactly as the fixed-single generator already does, adding the new
burst4 coordinator/top identities. Authored object or binding collisions fail
before generated files escape.

## 5. Exact unchanged child reuse

Invoke `AxiArDriver->generate` with its shipped bindings:

```text
ar_cmd_valid, cmd_araddr32, cmd_arid4, cmd_arlen8, cmd_arsize3,
cmd_arburst2, arready -> arvalid/araddr32/arid4/arlen8/arsize3/
arburst2/ar_busy/ar_done
```

The structural top, not the child, fixes `cmd_arlen=8'd3`,
`cmd_arsize=3'd2`, and `cmd_arburst=2'b01`. Preserve the original AR source-
anchor subset and all AR schedule/report behavior.

Invoke `AxiRBeatAcceptor->generate` once with its shipped bindings:

```text
r_accept_cmd_valid, rvalid/rready, rid4/rdata32/rresp2/rlast,
response_rid4/response_rdata32/response_rresp2/response_rlast,
r_busy/r_beat_done
```

The coordinator reuses that one child four times by issuing four distinct arm
pulses. Do not clone four instances and do not widen the child. Preserve its
original R source-anchor subset and all one-arm/one-beat schedule/report
behavior.

The aggregate generator itself emits only
`axi_read_burst4_transaction_coordinator.isf`, lowers it through
`FSM::Adapter::ISF` and `FSM::Scheduler::ISF`, and builds the new structural
top. It never copies child ISF text into a new behavioral implementation.

## 6. Exact legality predicate

Admission and the assertion use this exact supported bit predicate:

```text
(& (! cmd_read_addr[0])
   (! cmd_read_addr[1])
   (! (& cmd_read_addr[11] cmd_read_addr[10] cmd_read_addr[9]
         cmd_read_addr[8] cmd_read_addr[7] cmd_read_addr[6]
         cmd_read_addr[5] cmd_read_addr[4]
         (| cmd_read_addr[3] cmd_read_addr[2]))))
```

For an aligned 16-byte span this is equivalent to low12 `<= 12'hff0`. It
accepts `...ff0` and rejects `...ff4`, `...ff8`, `...ffc`, and every
misaligned address. The explicit bits avoid introducing mixed-width dynamic
arithmetic in this fixed slice.

## 7. Exact coordinator IAL1

```text
(actor axi_read_burst4_transaction_coordinator
  (clock clk)
  (reset (rst_n async active_low))

  (interface
    (input read_cmd_valid)
    (input cmd_read_addr (width 32))
    (input cmd_read_id (width 4))
    (input ar_busy_i)
    (input ar_done_i)
    (input r_busy_i)
    (input r_done_i)
    (input captured_rid_i (width 4))
    (input captured_rlast_i)
    (output ar_cmd_valid_i)
    (output ar_cmd_addr_i (width 32))
    (output ar_cmd_id_i (width 4))
    (output r_arm_i)
    (output read_busy)
    (output read_request_done)
    (output read_beat_done)
    (output read_transaction_done)
    (output response_beat_index (width 2))
    (output response_id_match)
    (output response_last_match))

  (storage
    (var beat_index_q (width 2) (reset 0)))

  (priority finish_burst over advance_beat)
  (priority finish_burst over arm_next_response)
  (priority finish_burst over clear_beat_done)
  (priority finish_burst over clear_transaction_done)
  (priority advance_beat over arm_next_response)
  (priority advance_beat over clear_beat_done)
  (priority arm_first_response over clear_r_arm)
  (priority arm_first_response over clear_request_done)
  (priority arm_next_response over clear_r_arm)
  (priority admit over clear_ar_start)

  (rule admit
    (& (! active_q) (! ar_busy_i) (! r_busy_i) read_cmd_valid
       (! cmd_read_addr[0]) (! cmd_read_addr[1])
       (! (& cmd_read_addr[11] cmd_read_addr[10] cmd_read_addr[9]
             cmd_read_addr[8] cmd_read_addr[7] cmd_read_addr[6]
             cmd_read_addr[5] cmd_read_addr[4]
             (| cmd_read_addr[3] cmd_read_addr[2]))))
    (set active_q 1)
    (set ar_cmd_valid_i 1)
    (set ar_cmd_addr_i cmd_read_addr)
    (set ar_cmd_id_i cmd_read_id)
    (set expected_arid_q cmd_read_id)
    (set beat_index_q 0)
    (set response_armed_q 0)
    (set read_busy 1)
    (set response_id_match 1)
    (set response_last_match 1))

  (rule clear_ar_start ar_cmd_valid_i
    (set ar_cmd_valid_i 0))

  (rule arm_first_response
    (& active_q (! response_armed_q) (== beat_index_q 0)
       ar_done_i (! r_busy_i))
    (set response_armed_q 1)
    (set r_arm_i 1)
    (set read_request_done 1))

  (rule arm_next_response
    (& active_q (! response_armed_q) (! (== beat_index_q 0)) (! r_busy_i))
    (set response_armed_q 1)
    (set r_arm_i 1))

  (rule clear_r_arm r_arm_i
    (set r_arm_i 0))

  (rule clear_request_done read_request_done
    (set read_request_done 0))

  (rule advance_beat
    (& active_q response_armed_q r_done_i (! (== beat_index_q 3)))
    (set read_beat_done 1)
    (set response_beat_index beat_index_q)
    (set response_id_match
      (& response_id_match (== captured_rid_i expected_arid_q)))
    (set response_last_match
      (& response_last_match
         (== captured_rlast_i (== beat_index_q 3))))
    (set beat_index_q (+ beat_index_q 1))
    (set response_armed_q 0))

  (rule finish_burst
    (& active_q response_armed_q r_done_i (== beat_index_q 3))
    (set read_beat_done 1)
    (set response_beat_index beat_index_q)
    (set response_id_match
      (& response_id_match (== captured_rid_i expected_arid_q)))
    (set response_last_match
      (& response_last_match captured_rlast_i))
    (set active_q 0)
    (set response_armed_q 0)
    (set read_busy 0)
    (set read_transaction_done 1))

  (rule clear_beat_done read_beat_done
    (set read_beat_done 0))

  (rule clear_transaction_done read_transaction_done
    (set read_transaction_done 0))

  (transaction aligned_boundary_command_check
    (assert
      (=> (& (! active_q) (! ar_busy_i) (! r_busy_i) read_cmd_valid)
          (& (! cmd_read_addr[0]) (! cmd_read_addr[1])
             (! (& cmd_read_addr[11] cmd_read_addr[10] cmd_read_addr[9]
                   cmd_read_addr[8] cmd_read_addr[7] cmd_read_addr[6]
                   cmd_read_addr[5] cmd_read_addr[4]
                   (| cmd_read_addr[3] cmd_read_addr[2])))))
      "fixed-four AXI INCR read must be four-byte aligned and remain within 4 KiB"))

  (transaction response_id_check
    (assert
      (=> (& active_q response_armed_q r_done_i)
          (== captured_rid_i expected_arid_q))
      "each accepted AXI RID must match the admitted ARID"))

  (transaction response_last_check
    (assert
      (=> (& active_q response_armed_q r_done_i)
          (== captured_rlast_i (== beat_index_q 3)))
      "AXI RLAST must be low before and high on fixed-four beat index 3")))
```

This exact source strict-checks and lowers with `compile_issues=[]`. The
coordinator has 20 ports, zero states, one declared two-bit storage register,
three assertion-only transactions, and ten rules:

```text
admit                    10
clear_ar_start            1
arm_first_response        3
arm_next_response         2
clear_r_arm               1
clear_request_done        1
advance_beat              6
finish_burst              8
clear_beat_done           1
clear_transaction_done    1
```

All ten authored priorities are mandatory. Eight scheduler resolutions are
exact:

```text
admit              > clear_ar_start          : ar_cmd_valid_i
arm_first_response > clear_r_arm              : r_arm_i
arm_next_response  > clear_r_arm              : r_arm_i
advance_beat       > clear_beat_done          : read_beat_done
finish_burst       > clear_beat_done          : read_beat_done
arm_first_response > clear_request_done       : read_request_done
finish_burst       > clear_transaction_done   : read_transaction_done
finish_burst       > advance_beat             : response_last_match
```

No `when` action is permitted inside either beat rule; the readiness compiler
probe proved that rule shells accept only one guard condition. Non-final and
final behavior therefore remain separate rules.

## 8. Exact flat C4 top

Children and instance order:

```text
(?fsmc:ar_driver axi_ar_driver)
(?fsmc:r_acceptor axi_r_beat_acceptor)
(?fsmc:transaction_coordinator axi_read_burst4_transaction_coordinator)
```

The 29 top ports, in order, are `clk`, `rst_n`; inputs `read_cmd_valid`,
`cmd_read_addr<32`, `cmd_read_id<4`, `arready`, `rvalid`, `rid<4`,
`rdata<32`, `rresp<2`, `rlast`; outputs `arvalid`, `araddr>32`, `arid>4`,
`arlen>8`, `arsize>3`, `arburst>2`, `rready`, `response_rid>4`,
`response_rdata>32`, `response_rresp>2`, `response_rlast`, `read_busy`,
`read_request_done`, `read_beat_done`, `read_transaction_done`,
`response_beat_index>2`, `response_id_match`, and `response_last_match`.

Explicit wiring is exact:

```text
(ar_driver.ar_busy transaction_coordinator.ar_busy_i)
(ar_driver.ar_done transaction_coordinator.ar_done_i)
(transaction_coordinator.ar_cmd_valid_i ar_driver.ar_cmd_valid)
(transaction_coordinator.ar_cmd_addr_i ar_driver.cmd_araddr)
(transaction_coordinator.ar_cmd_id_i ar_driver.cmd_arid)
(=8'd3 ar_driver.cmd_arlen)
(=3'd2 ar_driver.cmd_arsize)
(=2'b01 ar_driver.cmd_arburst)
(transaction_coordinator.r_arm_i r_acceptor.r_accept_cmd_valid)
(r_acceptor.r_busy transaction_coordinator.r_busy_i)
(r_acceptor.r_beat_done transaction_coordinator.r_done_i)
(r_acceptor.response_rid transaction_coordinator.captured_rid_i)
(r_acceptor.response_rlast transaction_coordinator.captured_rlast_i)
```

All other links use exact same-name binding. Captured RID and RLAST each have
one source and fan out to public top plus coordinator. RDATA and RRESP remain
top-facing only. Compiler evidence is exactly 29 public signals, three
generated FSM children, 48 composition nets, 46 resolved links, lane C4,
zero regular top states, and no diagnostics.

## 9. Lifecycle, drain, and reset

One admitted command owns this sequence:

1. retain address/ARID, initialize index/match status, pulse AR start, raise
   busy;
2. wait for exactly one unchanged AR acceptance;
3. pulse request done and first R arm from the later AR-done event;
4. accept/capture one raw R beat through the unchanged child;
5. on child done, pulse beat done, publish current index, update sticky status;
6. for indices 0-2, increment and issue the next arm only after child idle;
7. at index 3, pulse beat done and transaction done together and return idle.

RREADY is low during the child retirement/re-arm bubble. A conforming
subordinate holds RVALID/payload until the later handshake; continuous RVALID
therefore loses and duplicates no transfer.

Count is authoritative:

| Case | Status/action |
| --- | --- |
| matching RID, RLAST low at indices 0-2 | status stays true; re-arm |
| matching RID, RLAST high at index 3 | status stays true; retire |
| RID mismatch at any index | sticky ID match false; continue to index 3 |
| early RLAST | sticky last match false; continue to index 3 |
| missing final RLAST | sticky last match false; retire at index 3 |
| non-OKAY RRESP | raw code remains visible with beat event; control unchanged |

If an invalid subordinate stops after early RLAST, the manager remains busy
waiting for the ARLEN-selected remainder. Assertion detects the first bad last;
timeout/resynchronization is explicitly deferred.

Busy commands are ignored. Reset from AR issue, response wait, or between
beats asynchronously clears children, ownership, counter, captured results,
pulses, and match status without fabricated completion. Post-reset admission
starts at index zero with match status true.

## 10. Report and artifact contract

Report schema:
`fsmgen.ial2.protocol_intent.axi_read_burst4_transaction_composition.v1`.

Required sections:

- `mode = read-burst4-transaction-composition`;
- standard layering with `direct_ial2_to_ial0=false`;
- exact source object, intent, and anchors;
- target `{profile=axi4, object=axi-read-burst4-transaction-composition,
  role=manager}`;
- cloned public command/AR/R/status bindings;
- `composition` topology `flat_fixed_four_beat_ar_r_transaction`, exact child
  order, shared clock/reset, 29 top ports, 48 nets, 46 links, explicit/same-
  name/fanout policies;
- `fixed_burst_policy` containing `address_width=32`,
  `address_alignment_bytes=4`, `span_bytes=16`,
  `four_kib_contained=true`, `id_width=4`, `data_width=32`, `arlen=3`,
  `arsize=2`, `arburst=1`, `arburst_name=INCR`, `beat_count=4`,
  `request_completion=ar_request_accepted`,
  `beat_completion=r_beat_accepted_and_captured`, and
  `transaction_completion=fourth_r_beat_accepted_and_captured`;
- unchanged `ar_driver_reuse` and `r_acceptor_reuse` records;
- `transaction_coordinator` with idle admission, queue depth zero, exact
  legality guard, first/subsequent arm policy, two-bit count, pulse/busy/reset,
  sticky match, count-authoritative drain, and raw-RRESP policies;
- child reports and three ordered schedule reports;
- selected artifacts; and
- the exact static/residue arrays below.

Generated IAL1 order:

```text
axi_ar_driver.isf
axi_r_beat_acceptor.isf
axi_read_burst4_transaction_coordinator.isf
```

Deterministic IAL0 file list:

```text
axi_ar_driver.fsm
axi_r_beat_acceptor.fsm
axi_read_burst4_transaction_composition.fsm
axi_read_burst4_transaction_coordinator.fsm
```

The selected HDL entry kind is `generated_composition_top`, child count three,
module `axi_read_burst4_transaction_composition`, entry artifact
`axi_read_burst4_transaction_composition.fsm`. Schedule JSON exposes all three
schedules; semantic JSON exposes the C4 counts; outdir emits three ISF and four
FSM artifacts; Verilator/Yosys verify the selected top.

## 11. Exact enforced rules and residue

The ordered enforced strings are:

1. `profile must be axi4, object must be axi-read-burst4-transaction-composition, and role must be manager`
2. `clock and asynchronous active-low reset are shared by all three generated children`
3. `one idle admission atomically captures address width 32 and ID width 4`
4. `admission requires four-byte alignment and the complete 16-byte span to remain within one 4-KiB region`
5. `AR metadata is fixed to ARLEN 3, ARSIZE 2, and ARBURST INCR for four four-byte beats`
6. `flat C4 topology reuses unchanged generated AR driver and one explicitly re-armed R beat acceptor plus one transaction coordinator`
7. `R is first armed only after the owned AR request accepts`
8. `the unchanged R beat acceptor is re-armed once for each of four expected beats`
9. `one outstanding ownership interval rejects busy commands and provides no queue`
10. `request, beat, and transaction completion are distinct one-cycle events`
11. `response beat index 0 through 3 identifies the raw captured tuple during each beat event`
12. `RID match and the expected count/RLAST sequence match are sticky across all four beats`
13. `RID mismatch, early RLAST, missing final RLAST, and non-OKAY RRESP drain or retire at the authoritative fourth accepted beat`
14. `RRESP remains raw per beat and is not interpreted as success or aggregated`
15. `lowering is IAL2 through three generated IAL1 and three generated leaf IAL0 actors into one structural IAL0 top, never direct IAL2-to-IAL0`

The ordered residue is:

| ID | Detail |
| --- | --- |
| `axi_read_burst4_transaction_composition_dynamic_burst_deferred` | `Authored or dynamic ARLEN, variable beat counts, variable ARSIZE, FIXED/WRAP bursts, and general burst progression remain future work.` |
| `axi_read_burst4_transaction_composition_narrow_unaligned_wrap_attributes_deferred` | `Narrow, unaligned, or wrapping transfers and extended AR attributes remain future work.` |
| `axi_read_burst4_transaction_composition_multi_beat_write_deferred` | `Multi-beat WDATA/WSTRB supply, WLAST sequencing, and write transaction composition remain future work.` |
| `axi_read_burst4_transaction_composition_response_aggregation_output_banks_deferred` | `Sticky or worst RRESP aggregation, result mapping, error-RDATA usability policy, and four-entry output banks remain future work.` |
| `axi_read_burst4_transaction_composition_capacity_core_integration_deferred` | `Capacity/status submit/completion, ID authority, read-data storage, and response-demux integration remain future work.` |
| `axi_read_burst4_transaction_composition_outstanding_queueing_deferred` | `Adjacent back-to-back admission, multiple outstanding reads, buffering, and queues remain future work.` |
| `axi_read_burst4_transaction_composition_id_allocation_ordering_demux_deferred` | `Dynamic ID allocation/reuse, same-ID ordering, RID demux, and read-data interleaving remain future work.` |
| `axi_read_burst4_transaction_composition_malformed_subordinate_recovery_deferred` | `Timeout, abort, retry, or resynchronization when a malformed subordinate stops before the ARLEN-selected count remain future work.` |
| `axi_read_burst4_transaction_composition_extended_r_monitoring_deferred` | `Extended Issue L R sidebands and generated subordinate stall/payload-stability monitoring remain future work.` |
| `axi_read_burst4_transaction_composition_transaction_interface_deferred` | `Decision 0020 protocol-neutral transaction interfaces remain director-gated future work.` |
| `axi_read_burst4_transaction_composition_profile_alias_deferred` | `.axi profile-alias surfacing remains unsupported; this source uses generic .ppif only.` |
| `axi_read_burst4_transaction_composition_verification_output_deferred` | `Direct verification-output generation from this IAL2 source remains future work.` |
| `axi_read_burst4_transaction_composition_backend_variants_deferred` | `Direct backend lowering, backend-language variants, and VHDL behavior remain future work.` |
| `axi_read_burst4_transaction_composition_other_protocols_unchanged` | `AHB and APB behavior remain unchanged.` |

Child residue remains available under each child report and is not silently
discarded.

## 12. Exact diagnostics

Generator diagnostics contain:

| Invalid contract | Required substring |
| --- | --- |
| wrong kind | `AXI read burst4 transaction composition IAL2 contract kind must be axi_read_burst4_transaction_composition` |
| wrong profile | `AXI read burst4 transaction composition IAL2 contract profile must be axi4 in this slice` |
| wrong role | `AXI read burst4 transaction composition IAL2 contract role must be manager` |
| wrong reset | `AXI read burst4 transaction composition reset must be asynchronous active-low in this slice` |
| wrong width | exact `command.*`, `ar_channel.*`, `r_channel.*`, or `status.response_beat_index.width must be <N>` |
| missing binding/block | exact missing field/block path |
| invalid identifier | exact field plus `must be an ISF identifier` |
| duplicate public/private name | `duplicates signal '<name>'` |
| missing/duplicate child file | child/artifact identity plus exact expected count |
| duplicate generated file | `generated duplicate .fsm artifact '<name>'` |
| malformed schedules/artifacts/top | exact three-child/three-schedule/four-artifact/top expectation |
| `.axi` source | exact alias rejection from section 3 |

Parser diagnostics identify the exact burst4 object spelling and the offending
profile, cardinality, mix, duplicate/unknown clause, missing block, or malformed
binding. The t/1507 negative table includes at least:

- wrong root/profile family/AXI revision/role;
- synchronous or active-high reset;
- duplicate command and unknown clause;
- missing AR, R, or status block;
- missing captured ID/data/response/last;
- missing request/beat/transaction done, beat index, ID match, or last match;
- any authored length/size/burst/cardinality extension;
- nested child or top;
- mixed fixed-single read, standalone AR/R, write composition, or other intent;
- multiple burst4 objects;
- duplicate public binding or generated artifact collision;
- every wrong command/AR/R/result/beat-index width; and
- `.axi` rejection.

Malformed input fails before partial generated output escapes.

## 13. Support, manifest, and exact t/1507 proof

Add one supported entry:

```text
id               = intent.ppif_axi_read_burst4_transaction_composition
coverage         = ial2_ppif_axi_read_burst4_transaction_composition_pipeline_cli
strict_supported = 1
```

Expected t/248 counts:

```text
protocol entries:             305 -> 306
supported generated entries:  346 -> 347
strict-supported entries:     346 -> 347
```

The `.ppif` capability-manifest current-boundary sentence adds the fixed-four
full-width INCR read composition while preserving all prior wording and
deferrals; t/297 owns the exact text.

`t/1507` contains exactly four top-level subtests:

1. adapter/report/anchors/schedules/artifacts/topology;
2. malformed and expanded contracts fail closed;
3. support/check/schedule/semantic/outdir/Verilator/Yosys use the public source;
4. generated structural top executes the exact behavior matrix.

The tracked `.svt` fixture is the single source for the executable harness;
the Perl test loads it rather than duplicating a heredoc. Compile with
Verilator `--no-assert` for deliberate mismatch cases; separately check that
all three assertion messages remain emitted.

The behavior matrix proves:

- reset idle and illegal misaligned plus aligned-4-KiB-crossing non-launch;
- legal `...ff0` and fixed LEN3/SIZE2/INCR;
- continuous, stalled, and pulsed ARREADY with retained payload;
- busy command ignore and no RREADY before AR completion;
- already-high, delayed, continuously-held, and pulsed RVALID;
- ready-low re-arm bubbles with no lost/double transfer;
- raw tuple/index for all four beat positions;
- one burst containing RID mismatch, early RLAST, two non-OKAY RRESP values,
  and missing final RLAST, yet exactly four accepted beats and one completion;
- a following clean burst reinitializing both sticky statuses;
- reset after AR and between beats, no phantom completion, and recovery;
- exact final idle/cardinality:

```text
PASS ar=4 r=13 request=4 beat=13 transaction=3
     illegal=2 busy_ignored=1 error_drain=4 reset_abort=1
```

Three completed four-beat transactions plus one pre-reset beat explain the
13 R/beat events. Four AR/request events include the reset-aborted transaction;
only three transaction pulses are permitted.

## 14. Atomic implementation owner and validation

`.38` must change these surfaces atomically:

| Surface | Owner |
| --- | --- |
| parser/dispatch | `perl/FSM/Adapter/IAL2/PPIF.pm` |
| aggregate generator | new `perl/FSM/IAL2/ProtocolIntent/AxiReadBurst4TransactionComposition.pm` |
| unchanged children | `AxiArDriver.pm`, `AxiRBeatAcceptor.pm` read-only reuse |
| source | new `ppif/axi_read_burst4_transaction_composition.ppif` |
| support | `perl/FSM/Support/RegressionCorpus.pm`, t/248 |
| manifest | `perl/FSM/Support/LanguageSurfaceSection.pm`, t/297 |
| proof | new t/1507 and `.svt` fixture |
| user docs | `docs/book/src/16a-ial2-axi.md` |
| continuity | task/index, Memory, behavior fact, Knowledge Map, git |

Validation requires syntax; strict public check; schedule/semantic/outdir;
Verilator and Yosys; exact executable proof; focused t/1499-t/1507 plus t/248
and t/297 under the repository RAM policy; mdBook; Knowledge Map; memory/docs-
paths/whitespace; doctrines; and absence of generated scratch artifacts.

## 15. Preserved deferrals and rollback

`.38` must not change the fixed-single source or any existing parser/generator/
test behavior. It does not add dynamic/narrow/wrap/unaligned bursts, multi-beat
write, RRESP aggregation/output banks, capacity integration, outstanding/
back-to-back/queues/demux/interleaving, malformed-subordinate recovery,
aliases, decision 0020 activation, verification output, direct/backend/VHDL,
AHB, or APB behavior.

Implementation rollback removes the new generator/source/test/fixture/support/
manifest/book/behavior-fact/task changes and restores counts to 305/346/346.
It leaves every shipped fixed-single, channel, write, capacity, AHB, and APB
surface untouched.

Selector rollback removes this selector and its fact, restores `.37` active,
makes `.38` pending/blocked again, and restores task-index/book/Memory pointers.
No runtime rollback is needed because `.37` changes no behavior.
