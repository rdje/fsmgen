# IAL2 AXI manager initiator — fixed-four W burst driver contract selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.41` (behavior-neutral contract
selection).

Date: 2026-07-23

Status: exact public/generator/report/test contract selected. The following
leaf, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.42`, owns implementation.

This selector changes no parser, generator, public source, support-accounting
entry, capability manifest, test, generated artifact, runtime behavior, or HDL
behavior.

## 1. Selected identity

| Facet | Selected value |
| --- | --- |
| PPIF clause/object | `(axi-w-burst4-driver ...)` / `axi-w-burst4-driver` |
| parser contract `kind` | `axi_w_burst4_driver` |
| generator | `FSM::IAL2::ProtocolIntent::AxiWBurst4Driver` |
| generated result `kind` | `protocol_intent.axi_w_burst4_driver` |
| report schema | `fsmgen.ial2.protocol_intent.axi_w_burst4_driver.v1` |
| result mode | `burst4-driver` |
| public source | `ppif/axi_w_burst4_driver.ppif` |
| intent/actor/module | `axi_w_burst4_driver` |
| generated IAL1 | `axi_w_burst4_driver.isf` |
| generated IAL0 / HDL entry | `axi_w_burst4_driver.fsm` |
| support id | `intent.ppif_axi_w_burst4_driver` |
| coverage key | `ial2_ppif_axi_w_burst4_driver_pipeline_cli` |
| focused test | `t/1508-ial2-axi-w-burst4-driver.t` |
| executable fixture | `t/data/axi_w_burst4_driver_tb.svt` |

`burst4` is part of every new identity because four transfers are a fixed
contract, not the default of a general W driver. The new generator is additive.
The shipped `(axi-w-driver ...)`, `AxiWDriver`, schema v1, t/1500, and all
single-beat write compositions remain unchanged.

The role is exactly `manager-to-subordinate`: the actor drives WVALID, WDATA,
WSTRB, and WLAST and samples subordinate-owned WREADY. It is still a channel
primitive, not a complete write transaction.

## 2. Exact public source

```text
(protocol-platform-intent axi_w_burst4_driver
  (profile axi4)
  (source
    (object axi-w-burst4-driver)
    (anchor (document IHI0022_L_2025-08) (section A2.3) (page 29))
    (anchor (document IHI0022_L_2025-08) (section A2.3.1) (page 30))
    (anchor (document IHI0022_L_2025-08) (section A2.3.2.1) (page 31))
    (anchor (document IHI0022_L_2025-08) (section A3.1.2) (page 44))
    (anchor (document IHI0022_L_2025-08) (section A3.2.1) (page 53))
    (anchor (document IHI0022_L_2025-08) (section A3.2.1.1) (page 54))
    (anchor (document IHI0022_L_2025-08) (section B1.1.2) (page 277)))
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
      (beat-index w_beat_index width 2))))
```

All seven anchors are mandatory and ordered as shown. They fix handshake and
stability, per-beat manager VALID independence, Length-selected transfer
cardinality/no early termination, WDATA/WLAST, WSTRB, and W signal direction.
The source deliberately has no AW/address anchor because the driver does not
own AWLEN, address legality, or 4-KiB containment.

### Binding semantics

The command block contains the ten inputs: one one-shot start, four explicitly
ordered data32 values, four corresponding strobe4 values, and WREADY. The
channel block contains the eight outputs: WVALID/WDATA/WSTRB/WLAST plus local
busy, accepted-beat event, final done, and accepted-beat index2.

- An idle start atomically captures every command payload field.
- Beat zero is retained directly in the registered driven WDATA/WSTRB outputs;
  private registers retain beats one through three.
- WVALID asserts without consulting WREADY and remains high until the fourth
  accepted transfer.
- WLAST is low for presented indices 0-2 and high for presented index 3.
- Every WSTRB value is legal, including zero, independently on each beat.
- Beat done identifies one acceptance in each high cycle; adjacent accepted
  beats can produce adjacent high event cycles and are distinguished by index.
- Final done is high with beat done/index three and aggregate busy clears.
- A one-cycle start while busy is ignored, not queued.

Bindings remain rebindable identifiers, but the field names, widths, ordering,
and semantics are fixed.

## 3. Parser contract

### Root object and cardinality

`FSM::Adapter::IAL2::PPIF::_contract_from_root` gains
`@axi_w_burst4_drivers` and an `axi-w-burst4-driver` clause arm. The exact
policy is:

- root dispatch accepts only an AXI-family profile; generator normalization
  pins implementation to exact `axi4`;
- exactly one `(axi-w-burst4-driver ...)` object is required;
- it cannot mix with any valid-ready, capacity/status, standalone AXI channel,
  AXI composition, APB, or AHB object; and
- the missing-intent enumeration names `(axi-w-burst4-driver ...)`.

No existing object cardinality or dispatch order changes except for adding the
new mutually exclusive family.

### Clause parsing

`_parse_axi_w_burst4_driver` requires exactly once:

```text
role clock reset command channel
```

`_parse_axi_w_burst4_driver_command_block` accepts and requires:

```text
start=scalar
data0=width data1=width data2=width data3=width
strobe0=width strobe1=width strobe2=width strobe3=width
ready=scalar
```

`_parse_axi_w_burst4_driver_channel_block` accepts and requires:

```text
valid=scalar data=width strobe=width last=scalar busy=scalar
beat-done=scalar done=scalar beat-index=width
```

The normalized contract is:

```text
kind       = axi_w_burst4_driver
name       = <object name>
actor_name = <object name unless explicitly supplied internally>
protocol   = <root profile>
role       = manager-to-subordinate
clock      = <identifier>
reset      = <normalized reset>
command    = {
  start,
  data0..data3 {name,width},
  strobe0..strobe3 {name,width},
  ready
}
channel    = {
  valid, data{name,width}, strobe{name,width}, last,
  busy, beat_done, done, beat_index{name,width}
}
source     = <object + anchors>
intent_name = <root name>
```

Unknown, duplicate, missing, packed-bank, streaming, authored-length, or
additional tuple vocabulary fails in the PPIF parser.

### `.axi` alias policy

The object ships only through generic `.ppif`. Adapter alias dispatch adds a
family-specific rejection with required substring:

```text
(axi-w-burst4-driver ...) remains unsupported for the first profile-alias implementation
```

It must precede generic aggregate guards so the diagnostic remains precise.
No `.axi` fixture or support entry is added.

## 4. Generator normalization and diagnostics

`AxiWBurst4Driver` uses the same defensive constructor/generate/clone and
generated-IAL1/IAL0 envelope as `AxiWDriver`, with these exact diagnostics:

| Invalid contract | Required diagnostic substring |
| --- | --- |
| wrong kind | `AXI W burst4 driver IAL2 contract kind must be axi_w_burst4_driver` |
| profile other than exact AXI4 | `AXI W burst4 driver IAL2 contract profile must be axi4 in this slice` |
| wrong role | `AXI W burst4 driver IAL2 contract role must be manager-to-subordinate` |
| wrong reset | `AXI W burst4 driver reset must be asynchronous active-low in this slice` |
| wrong command data width | exact `command.dataN.width must be 32 in this slice` |
| wrong command strobe width | exact `command.strobeN.width must be 4 in this slice` |
| wrong driven data width | `channel.data.width must be 32 in this slice` |
| wrong driven strobe width | `channel.strobe.width must be 4 in this slice` |
| wrong beat-index width | `channel.beat_index.width must be 2 in this slice` |
| absent scalar/binding | identify the exact missing `command.*` or `channel.*` field |
| invalid identifier | identify the exact field and require an ISF identifier |
| duplicate interface/private name | `AXI W burst4 driver IAL2 contract duplicates signal '<name>'` |
| unsupported constructor option | identify the option and permit only `debug` |
| `.axi` object | the alias substring from section 3 |

Root errors identify source/profile/object for wrong family, more than one
object, mixing, missing object, and duplicate/unsupported clauses.

The duplicate-name set includes clock, reset, all eighteen bindings,
`active_q`, `beat_index_q`, `data1_q`-`data3_q`, `strb1_q`-`strb3_q`, and
`can_accept`. WLAST values and beat cardinality are not author-controlled.

## 5. Exact generated IAL1 actor

Binding substitutions are allowed; the following control/storage structure is
exact:

```text
(actor axi_w_burst4_driver
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input w_cmd_valid)
    (input cmd_wdata0 (width 32))
    (input cmd_wdata1 (width 32))
    (input cmd_wdata2 (width 32))
    (input cmd_wdata3 (width 32))
    (input cmd_wstrb0 (width 4))
    (input cmd_wstrb1 (width 4))
    (input cmd_wstrb2 (width 4))
    (input cmd_wstrb3 (width 4))
    (input wready)
    (output wvalid)
    (output wdata (width 32))
    (output wstrb (width 4))
    (output wlast)
    (output w_busy)
    (output w_beat_done)
    (output w_done)
    (output w_beat_index (width 2)))

  (storage
    (var beat_index_q (width 2) (reset 0))
    (var data1_q (width 32) (reset 0))
    (var data2_q (width 32) (reset 0))
    (var data3_q (width 32) (reset 0))
    (var strb1_q (width 4) (reset 0))
    (var strb2_q (width 4) (reset 0))
    (var strb3_q (width 4) (reset 0)))

  (priority accept_beat0 over clear_beat_done)
  (priority accept_beat1 over clear_beat_done)
  (priority accept_beat2 over clear_beat_done)
  (priority accept_final over clear_beat_done)
  (priority accept_final over clear_done)

  (rule admit (& (! active_q) w_cmd_valid)
    (set active_q 1)
    (set w_busy 1)
    (set beat_index_q 0)
    (set data1_q cmd_wdata1)
    (set data2_q cmd_wdata2)
    (set data3_q cmd_wdata3)
    (set strb1_q cmd_wstrb1)
    (set strb2_q cmd_wstrb2)
    (set strb3_q cmd_wstrb3)
    (set wvalid 1)
    (set wdata cmd_wdata0)
    (set wstrb cmd_wstrb0)
    (set wlast 0))

  (rule accept_beat0 (& active_q wvalid wready (== beat_index_q 0))
    (set w_beat_done 1)
    (set w_beat_index 0)
    (set beat_index_q 1)
    (set wdata data1_q)
    (set wstrb strb1_q)
    (set wlast 0))

  (rule accept_beat1 (& active_q wvalid wready (== beat_index_q 1))
    (set w_beat_done 1)
    (set w_beat_index 1)
    (set beat_index_q 2)
    (set wdata data2_q)
    (set wstrb strb2_q)
    (set wlast 0))

  (rule accept_beat2 (& active_q wvalid wready (== beat_index_q 2))
    (set w_beat_done 1)
    (set w_beat_index 2)
    (set beat_index_q 3)
    (set wdata data3_q)
    (set wstrb strb3_q)
    (set wlast 1))

  (rule accept_final (& active_q wvalid wready (== beat_index_q 3))
    (set w_beat_done 1)
    (set w_beat_index 3)
    (set active_q 0)
    (set w_busy 0)
    (set wvalid 0)
    (set w_done 1))

  (rule clear_beat_done w_beat_done
    (set w_beat_done 0))

  (rule clear_done w_done
    (set w_done 0))

  (transaction wlast_sequence_check
    (assert
      (=> (& wvalid active_q)
          (== wlast (== beat_index_q 3)))
      "WLAST must be high only on fixed-four beat index 3")))
```

Strict JSON is exact at 18 ports, 10 inputs, 8 outputs, 30 signals, zero
states, and no diagnostics. Schedule JSON has `compile_issues=[]`, seven
declared storage registers, and these decision-tree blocks:

```text
admit             13
accept_beat0       6
accept_beat1       6
accept_beat2       6
accept_final       6
clear_beat_done    1
clear_done         1
```

The five authored priorities and scheduler resolutions are exact:

```text
accept_beat0 > clear_beat_done : w_beat_done
accept_beat1 > clear_beat_done : w_beat_done
accept_beat2 > clear_beat_done : w_beat_done
accept_final > clear_beat_done : w_beat_done
accept_final > clear_done      : w_done
```

Compatible same-value fan-in is exact for WLAST zero from admission/beat0/
beat1 and beat-done one from all four acceptance rules. `active_q` is inferred
from rule writes; the assertion-only transaction exposes scheduler-reserved
`can_accept`. No private data0/strobe0 register is permitted.

## 6. Lifecycle and reset contract

One idle command owns exactly four transfers:

1. admission captures all tuples, raises busy/WVALID, and presents beat zero;
2. no rule changes presented payload/index while WREADY is low;
3. each accepted non-final edge publishes its accepted index and atomically
   presents the next captured tuple without lowering WVALID;
4. accepted index three publishes beat done/index/final done and lowers
   active/busy/WVALID; and
5. the pulse-clear rules lower events on the next non-event cycle.

With WREADY continuously high, the four transfers and four beat events occupy
four consecutive cycles. A high beat-done level in each adjacent cycle is four
events, not one edge-detected event; the changing index identifies each.

Reset asynchronously clears all public registers, private storage, active
ownership, and events without fabricating a handshake or done. Recovery starts
at index zero. A busy-time one-cycle start is ignored; there is no queue,
command-ready signal, or retained retry. A held command and an adjacent
back-to-back guarantee remain outside the contract.

## 7. Exact report and artifacts

The report schema is
`fsmgen.ial2.protocol_intent.axi_w_burst4_driver.v1` and contains:

- `mode = burst4-driver`;
- `layering { source_layer=IAL2, generated_ial1_format=isf,
  generated_ial0_format=fsm, direct_ial2_to_ial0=false }`;
- `source_object { id, intent_name, anchors[] }`;
- `target_protocol { profile=axi4, object=axi-w-burst4-driver,
  role=manager-to-subordinate }`;
- `driver { name, actor_name }`;
- cloned `bindings { clock, reset, command, channel }`;
- `fixed_burst_policy` with these exact keys/values:
  `data_width=32`, `strobe_width=4`, `beat_count=4`,
  `beat_index_width=2`, `last_beat_index=3`,
  `last_sequence=[0,0,0,1]`,
  `payload_authoring=explicit_four_tuple_fields`,
  `capture_policy=atomic_on_idle_command`,
  `beat_zero_storage=driven_wdata_wstrb_registers`,
  `trailing_payload_storage=private_per_beat_registers`,
  `valid_policy=assert_independent_of_ready_and_hold_through_fourth_acceptance`,
  `stall_policy=hold_valid_data_strobe_last_and_index`,
  `beat_completion=w_transfer_accepted`,
  `burst_completion=fourth_w_transfer_accepted`, and
  `all_zero_strobe_allowed=true`;
- `driver_policy` with `queue_depth=0`,
  `busy_command=ignored_not_queued`,
  `beat_event=level_high_each_accepted_cycle_with_index`,
  `final_event=coincident_with_accepted_index_three`, and
  `reset=asynchronous_abort_without_events`;
- exact schedule/storage/priority summary;
- generated artifacts; and
- ordered enforced-static and residue arrays from section 8.

Artifacts are exact:

```text
generated IAL1: axi_w_burst4_driver.isf
generated IAL0: axi_w_burst4_driver.fsm
selected HDL entry kind: generated_driver_fsm
selected HDL entry artifact: axi_w_burst4_driver.fsm
```

There is no composition top. Schedule JSON exposes the one actor schedule;
semantic JSON exposes the FSM root; outdir emits ISF/FSM/HDL; Verilator/Yosys
verify the generated driver FSM.

## 8. Exact enforced strings and residue

The ordered enforced strings are:

1. `profile must be axi4, object must be axi-w-burst4-driver, and role must be manager-to-subordinate`
2. `clock and reset are shared with one asynchronous active-low generated actor`
3. `one idle command atomically captures four explicit data width 32 and strobe width 4 tuples`
4. `WVALID asserts independently of WREADY and remains high through all four presented beats`
5. `WDATA, WSTRB, WLAST, and the current beat index remain stable during every WREADY-low stall`
6. `WLAST is low on beat indices 0 through 2 and high only on beat index 3`
7. `exactly four WVALID and WREADY acceptances retire one admitted command`
8. `all-zero and partial WSTRB values are legal on every beat`
9. `beat done and beat index identify every accepted tuple including consecutive WREADY-high transfers`
10. `final done coincides with accepted beat index 3 and clears busy and WVALID`
11. `a one-cycle command while busy is ignored and no command queue is provided`
12. `asynchronous reset aborts without fabricated beat or final events and recovery restarts at beat index 0`
13. `lowering is IAL2 through one generated IAL1 actor into one generated IAL0 FSM, never direct IAL2-to-IAL0`

The ordered residue is:

| ID | Detail |
| --- | --- |
| `axi_w_burst4_driver_aw_coordination_deferred` | `AW launch, address ownership, AWLEN/AWSIZE/AWBURST coupling, alignment, 4-KiB legality, AW/W joining, and request completion remain future work.` |
| `axi_w_burst4_driver_b_response_completion_deferred` | `B arming, BID/BRESP handling, and full write-transaction completion remain future work.` |
| `axi_w_burst4_driver_address_attribute_coupling_deferred` | `This channel primitive does not establish address, transfer-size, burst-kind, or transaction-container legality.` |
| `axi_w_burst4_driver_dynamic_general_bursts_deferred` | `Authored or dynamic beat counts, lengths other than four, and general burst progression remain future work.` |
| `axi_w_burst4_driver_narrow_unaligned_wrap_deferred` | `Narrow, unaligned, FIXED, WRAP, and extended W-side behavior remain future work.` |
| `axi_w_burst4_driver_streaming_packed_payload_deferred` | `Packed payload banks, streaming producer supply, producer backpressure, and underflow buffering remain future work.` |
| `axi_w_burst4_driver_capacity_core_integration_deferred` | `Capacity/status submit/completion, ID authority, response bookkeeping, and storage integration remain future work.` |
| `axi_w_burst4_driver_outstanding_queueing_deferred` | `Adjacent back-to-back admission, multiple outstanding writes, buffering, queues, ordering, demux, and interleaving remain future work.` |
| `axi_w_burst4_driver_transaction_interface_deferred` | `Decision 0020 protocol-neutral transaction interfaces and role composition remain director-gated future work.` |
| `axi_w_burst4_driver_profile_alias_deferred` | `.axi profile-alias surfacing remains unsupported; this source uses generic .ppif only.` |
| `axi_w_burst4_driver_verification_output_deferred` | `Direct verification-output generation from this IAL2 source remains future work.` |
| `axi_w_burst4_driver_backend_variants_deferred` | `Direct backend lowering, backend-language variants, and VHDL behavior remain future work.` |
| `axi_w_burst4_driver_other_protocols_unchanged` | `AHB and APB behavior remain unchanged.` |

## 9. Exact implementation owner (`.42`)

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.42` owns exactly:

1. add `FSM::IAL2::ProtocolIntent::AxiWBurst4Driver` with defensive APIs,
   normalization, the exact actor/report/artifacts above, and defensive copies;
2. wire PPIF import/result dispatch, root accumulator/clause/cardinality/
   mixing/return, object and block parsers, predicate, missing-object text, and
   exact `.axi` rejection;
3. add the exact seven-anchor public source from section 2;
4. support-account it with the exact id/key/module/root identities;
5. update t/248 from 306 to 307 protocol fixtures and from 347 to 348 for both
   supported-smoke and strict-supported fixtures;
6. update `LanguageSurfaceSection.pm` and t/297 with the bounded shipped W
   burst4 wording;
7. add exact four-subtest t/1508 and its tracked executable fixture;
8. update the AXI mdBook from selected/not-shipped to shipped commands,
   artifacts, guarantees, event semantics, example, and residue; and
9. synchronize task/index, Memory, behavior fact, generated Knowledge Map, and
   cleanup before the task-scoped commit.

No existing W generator/source/test/composition may be edited except additive
shared PPIF dispatch/accounting/manifest coexistence and focused cross-surface
assertions required to recognize the new family.

## 10. Exact executable regression

`t/1508` has exactly four top-level subtests:

1. **Adapter/report/schedule** — exact identity, seven anchors, bindings,
   fixed policy, driver policy, static/residue order, 18 ports, 30 signals,
   zero states, seven rules at `13/6/6/6/6/1/1`, seven declared storage
   registers, five exact priorities, compatible fan-in, assertion, and
   ISF/FSM artifacts.
2. **Fail closed** — wrong root/profile/role/reset; missing/duplicate/unknown
   object or blocks; every wrong width; missing binding; duplicate/reserved
   name; packed/streaming/length/fifth-tuple expansion; mixed/multiple object;
   and `.axi` alias.
3. **Public tooling** — strict check JSON, support match, semantic JSON,
   schedule JSON, outdir ISF/FSM/HDL, Verilator lint, and Yosys synthesis.
4. **Generated-HDL behavior** — exact tuples/strobes/WLAST/index/events under
   low/already-high/continuous/pulsed WREADY, post-admission input mutation,
   busy command, reset between beats, recovery, and final idle.

The executable fixture must finish exactly:

```text
PASS handshakes=14 beat=14 done=3 busy_ignored=1 reset_abort=1
```

Three bursts complete; a fourth accepts two beats before reset. The test must
observe WLAST `0/0/0/1` for every completed burst, no WVALID bubble during
continuous-ready bursts, stable payload during every stall, all zero/partial/
full strobes, no phantom event on reset, and all outputs idle after recovery.

Focused validation is:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiWBurst4Driver.pm
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
prove -Iperl t/1508-ial2-axi-w-burst4-driver.t
./bin/fsmgen --quiet --strict --check --json ppif/axi_w_burst4_driver.ppif
./bin/fsmgen --strict --emit-schedule-json ppif/axi_w_burst4_driver.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_w_burst4_driver.ppif
./bin/fsmgen --verify-hdl ppif/axi_w_burst4_driver.ppif
scripts/run_with_ram_guard.sh prove -Iperl \
  t/248-regression-corpus-accounting.t \
  t/297-capability-manifest.t \
  t/1500-ial2-axi-w-driver.t \
  t/1502-ial2-axi-write-request-composition.t \
  t/1503-ial2-axi-write-transaction-composition.t \
  t/1507-ial2-axi-read-burst4-transaction-composition.t \
  t/1508-ial2-axi-w-burst4-driver.t
mdbook build docs/book
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
scripts/check_docs_relative_paths.sh
git diff --check
scripts/check_doctrines.sh
```

Heavy/broad tests remain under the repository RAM policy. If the known macOS
inactive/cache metric falsely trips the guard, verify real availability with
`memory_pressure` and use the documented direct focused-test fallback.

## 11. Deferrals and rollback

Implementation must not add AW/address/B coordination, dynamic/general/narrow/
unaligned/FIXED/WRAP bursts, packed or streaming payloads, capacity integration,
back-to-back/outstanding/queue/order/demux/interleaving, timeout/recovery,
changes to shipped W/write/read sources, `.axi`, decision 0020 activation,
verification output, direct/backend/VHDL behavior, AHB, or APB.

Rollback of `.41` is documentation-only: remove this note and its fact card,
restore `.41` active and `.42` pending, restore task-index/book/Memory pointers,
regenerate `KNOWLEDGE_MAP.md`, and commit the reversal. No parser, generator,
source, test, runtime, or HDL behavior exists in this leaf.

## 12. Conclusion

The contract is closed. `.42` can implement one additive fixed-four W driver
without remaining syntax, width, lifecycle, schedule, diagnostic, report,
residue, support, test, artifact, validation, or ownership ambiguity.
