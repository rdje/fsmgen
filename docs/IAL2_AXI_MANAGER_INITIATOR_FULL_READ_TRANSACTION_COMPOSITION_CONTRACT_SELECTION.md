# IAL2 AXI manager initiator — full-read transaction composition contract selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.33` (behavior-neutral contract
selection).

Date: 2026-07-23

Status: exact public/generator/report/test contract selected. The following
leaf, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.34`, owns implementation.

This selector changes no parser, generator, public source, support-accounting
entry, capability manifest, test, generated artifact, runtime behavior, or HDL
behavior.

## 1. Selected identity

| Facet | Selected value |
| --- | --- |
| PPIF clause/object | `(axi-read-transaction-composition ...)` / `axi-read-transaction-composition` |
| parser contract `kind` | `axi_read_transaction_composition` |
| generator | `FSM::IAL2::ProtocolIntent::AxiReadTransactionComposition` |
| generated result `kind` | `protocol_intent.axi_read_transaction_composition` |
| report schema | `fsmgen.ial2.protocol_intent.axi_read_transaction_composition.v1` |
| result mode | `read-transaction-composition` |
| public source | `ppif/axi_read_transaction_composition.ppif` |
| intent/object/top | `axi_read_transaction_composition` |
| transaction coordinator | `axi_read_transaction_coordinator` |
| selected IAL0/HDL entry | `axi_read_transaction_composition.fsm` |
| support id | `intent.ppif_axi_read_transaction_composition` |
| coverage key | `ial2_ppif_axi_read_transaction_composition_pipeline_cli` |
| focused test | `t/1506-ial2-axi-read-transaction-composition.t` |

The readiness audit's shorthand “parser kind” is disambiguated here: the
normalized parser contract kind is `axi_read_transaction_composition`; only
the generated result has the `protocol_intent.` prefix. This matches every
shipped protocol-intent family and prevents dispatch/report ambiguity.

“Transaction” means one fixed read request plus its one owned response beat.
“Composition” remains explicit because the implementation is three generated
actors under a structural top, not one monolithic FSM.

The aggregate role is exactly `manager`. Directional
`manager-to-subordinate` and `subordinate-to-manager` roles are rejected
because the full boundary drives AR and RREADY while receiving ARREADY and the
R payload.

## 2. Exact public source

```text
(protocol-platform-intent axi_read_transaction_composition
  (profile axi4)
  (source
    (object axi-read-transaction-composition)
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
      (response-last-match response_last_match))))
```

All thirteen anchors are mandatory in that order. They are the de-duplicated
union of the shipped AR driver and R beat acceptor dependencies, with the
read-address burst attributes, request-to-response dependency, RLAST/RRESP,
ARID/RID relationship, and both channel-direction tables preserved.

### Public semantics

- `read_cmd_valid` is a level-sampled idle admission request, not a queue or
  edge-capture promise.
- `cmd_read_addr` and `cmd_read_id` are captured atomically on one four-byte-
  aligned admission.
- the private AR request is fixed to address32, ID4, `ARLEN=0`, `ARSIZE=2`, and
  `ARBURST=INCR`.
- `read_busy` covers public admission through one owned R-beat retirement.
- `read_request_done` pulses after the AR child accepts the fixed request and
  at the coordinator's R-arm event.
- `read_transaction_done` pulses after the R child captures the one owned raw
  RID/RDATA/RRESP/RLAST beat and the coordinator retires ownership.
- `response_rid`, `response_rdata`, `response_rresp`, and `response_rlast`
  hold the last captured raw beat.
- `response_id_match` is stable status written at full completion; one means
  captured RID equals the retained admitted ARID.
- `response_last_match` is stable status written at full completion; one means
  captured RLAST is asserted for the fixed single expected beat.
- either match failure is assertion-visible but functionally terminal after
  the already-consumed beat.
- transaction done does not imply RRESP is OKAY or that error RDATA is usable.

## 3. Parser contract

`_contract_from_root` gains an `@axi_read_transaction_compositions`
accumulator and `axi-read-transaction-composition` clause arm. Root policy:

- require an AXI-family profile at dispatch, then pin exact `axi4` in the
  generator;
- require exactly one full-read composition object;
- reject mixing with Valid-Ready channels/bundles, manager-capacity-status,
  standalone AR/R, either write composition, standalone AW/W/B, or APB/AHB
  objects;
- add the new object to every existing standalone/aggregate mixing count; and
- include it in the missing-intent enumeration.

`_parse_axi_read_transaction_composition` requires these object clauses once:

```text
role clock reset command ar-channel r-channel status
```

The block parsers require exactly:

```text
command:    start=scalar, address=width, id=width
ar-channel: ready=scalar, valid=scalar, address=width, id=width,
            length=width, size=width, burst=width
r-channel:  valid=scalar, ready=scalar, id=width, data=width,
            response=width, last=scalar, captured-id=width,
            captured-data=width, captured-response=width,
            captured-last=scalar
status:     busy=scalar, request-done=scalar, transaction-done=scalar,
            response-id-match=scalar, response-last-match=scalar
```

Hyphenated fields normalize to underscore keys. The contract returned to the
generator is:

```text
kind       = axi_read_transaction_composition
name       = <object name>
role       = manager
clock/reset
command    = { start, address{name,width}, id{name,width} }
ar_channel = { ready, valid, address, id, length, size, burst }
r_channel  = { valid, ready, id, data, response, last,
               captured_id, captured_data, captured_response,
               captured_last }
status     = { busy, request_done, transaction_done,
               response_id_match, response_last_match }
protocol/source/intent_name
```

Duplicate or unsupported clauses fail in PPIF parsing. The generic binding
parser enforces scalar versus exact `width` forms before generation.

### `.axi` policy

Generic `.ppif` only. `_validate_profile_alias_contract` rejects:

```text
(axi-read-transaction-composition ...) remains unsupported for the first profile-alias implementation
```

No `.axi` fixture or capability is added.

## 4. Generator normalization and child reuse

The generator pins:

- exact kind, profile `axi4`, role `manager`, and asynchronous active-low reset;
- command address width 32 and command ID width 4;
- AR address32/ID4/length8/size3/burst2;
- R bus/captured ID widths 4, data widths 32, response widths 2, and scalar
  valid/ready/last/captured-last; and
- all command/status scalar bindings to width one.

All public signal names must be distinct from one another and from this fixed
private/reserved set:

```text
ar_cmd_valid_i  ar_cmd_addr_i  ar_cmd_id_i
ar_busy_i       ar_done_i      r_arm_i
r_busy_i        r_done_i       captured_rid_i
captured_rlast_i
active_q        expected_arid_q response_armed_q
```

The generator also reserves every actor, instance, and artifact identity fixed
by this contract against authored object/binding collisions where applicable.

### Exact unchanged AR child

The generator invokes `AxiArDriver->generate` with the shipped child's exact
bindings:

```text
ar_cmd_valid, cmd_araddr32, cmd_arid4, cmd_arlen8, cmd_arsize3,
cmd_arburst2, arready -> arvalid/araddr32/arid4/arlen8/arsize3/
arburst2/ar_busy/ar_done
```

Those child command/status names are private to the structural top because the
aggregate command is named `read_cmd_valid`/`cmd_read_addr`/`cmd_read_id`.
Explicit top links connect the coordinator to the child; sized literals drive
the remaining metadata inputs. The child receives its original nine source
anchors from the public union and is otherwise byte-for-byte behaviorally
unchanged.

### Exact unchanged R child

The generator invokes `AxiRBeatAcceptor->generate` with the shipped child's
exact bindings:

```text
r_accept_cmd_valid, rvalid/rready, rid4/rdata32/rresp2/rlast,
response_rid4/response_rdata32/response_rresp2/response_rlast,
r_busy/r_beat_done
```

Its arm is private because the aggregate has no public arm. Its bus and
captured-result bindings connect by name to the public top. It receives its
original eight source anchors from the public union and is otherwise unchanged.

The new generator emits only `axi_read_transaction_coordinator.isf` itself,
lowers it through the normal ISF scheduler, and builds the selected full top.
It must not copy or recreate either child ISF.

## 5. Exact transaction-coordinator IAL1 target

```text
(actor axi_read_transaction_coordinator
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
    (output read_transaction_done)
    (output response_id_match)
    (output response_last_match))

  (priority finish_response over admit)
  (priority finish_response over arm_response)
  (priority finish_response over clear_transaction_done)
  (priority arm_response over clear_r_arm)
  (priority arm_response over clear_request_done)
  (priority admit over clear_ar_start)

  (rule admit
    (& (! active_q) (! ar_busy_i) (! r_busy_i) read_cmd_valid
       (! cmd_read_addr[0]) (! cmd_read_addr[1]))
    (set active_q 1)
    (set ar_cmd_valid_i 1)
    (set ar_cmd_addr_i cmd_read_addr)
    (set ar_cmd_id_i cmd_read_id)
    (set expected_arid_q cmd_read_id)
    (set read_busy 1))

  (rule clear_ar_start ar_cmd_valid_i
    (set ar_cmd_valid_i 0))

  (rule arm_response
    (& active_q (! response_armed_q) ar_done_i (! r_busy_i))
    (set response_armed_q 1)
    (set r_arm_i 1)
    (set read_request_done 1))

  (rule clear_r_arm r_arm_i
    (set r_arm_i 0))

  (rule clear_request_done read_request_done
    (set read_request_done 0))

  (rule finish_response
    (& active_q response_armed_q r_done_i)
    (set active_q 0)
    (set response_armed_q 0)
    (set read_busy 0)
    (set read_transaction_done 1)
    (set response_id_match (== captured_rid_i expected_arid_q))
    (set response_last_match captured_rlast_i))

  (rule clear_transaction_done read_transaction_done
    (set read_transaction_done 0))

  (transaction aligned_command_check
    (assert
      (=> (& (! active_q) (! ar_busy_i) (! r_busy_i) read_cmd_valid)
          (& (! cmd_read_addr[0]) (! cmd_read_addr[1])))
      "single-beat AXI read transaction address must be four-byte aligned"))

  (transaction response_id_check
    (assert
      (=> (& active_q response_armed_q r_done_i)
          (== captured_rid_i expected_arid_q))
      "accepted AXI RID must match admitted ARID"))

  (transaction response_last_check
    (assert
      (=> (& active_q response_armed_q r_done_i)
          captured_rlast_i)
      "fixed-single-beat AXI read response must assert RLAST")))
```

The exact schedule has 18 interface ports, zero states, no procedural
transactions, no compile issues, and seven rule blocks with assignment counts:

```text
admit                    6
clear_ar_start           1
arm_response             3
clear_r_arm              1
clear_request_done       1
finish_response          6
clear_transaction_done   1
```

The six authored priorities are required. Four resolve scheduled pulse-write
conflicts:

```text
admit           > clear_ar_start          : ar_cmd_valid_i
arm_response    > clear_r_arm              : r_arm_i
arm_response    > clear_request_done       : read_request_done
finish_response > clear_transaction_done   : read_transaction_done
```

The other two authored finish orderings defensively document mutually
exclusive active/armed state transitions and add no realized schedule rows.
The three assertion-only transactions add no states.

## 6. Exact flat C4 structural top

Immediate children and instances are exactly:

```text
(?fsmc:ar_driver axi_ar_driver)
(?fsmc:r_acceptor axi_r_beat_acceptor)
(?fsmc:transaction_coordinator axi_read_transaction_coordinator)
```

The top has 27 ports in this exact order: `clk`, `rst_n`; inputs
`read_cmd_valid`, `cmd_read_addr<32`, `cmd_read_id<4`, `arready`, `rvalid`,
`rid<4`, `rdata<32`, `rresp<2`, `rlast`; outputs `arvalid`, `araddr>32`,
`arid>4`, `arlen>8`, `arsize>3`, `arburst>2`, `rready`,
`response_rid>4`, `response_rdata>32`, `response_rresp>2`,
`response_rlast`, `read_busy`, `read_request_done`,
`read_transaction_done`, `response_id_match`, and `response_last_match`.

The exact explicit wiring is:

```text
(ar_driver.ar_busy transaction_coordinator.ar_busy_i)
(ar_driver.ar_done transaction_coordinator.ar_done_i)
(transaction_coordinator.ar_cmd_valid_i ar_driver.ar_cmd_valid)
(transaction_coordinator.ar_cmd_addr_i ar_driver.cmd_araddr)
(transaction_coordinator.ar_cmd_id_i ar_driver.cmd_arid)
(=8'd0 ar_driver.cmd_arlen)
(=3'd2 ar_driver.cmd_arsize)
(=2'b01 ar_driver.cmd_arburst)
(transaction_coordinator.r_arm_i r_acceptor.r_accept_cmd_valid)
(r_acceptor.r_busy transaction_coordinator.r_busy_i)
(r_acceptor.r_beat_done transaction_coordinator.r_done_i)
(r_acceptor.response_rid transaction_coordinator.captured_rid_i)
(r_acceptor.response_rlast transaction_coordinator.captured_rlast_i)
```

All remaining public bus/command/status links use exact same-name C4 binding.
`response_rid` and `response_rlast` each fan out from the R child to the public
top and the distinct private coordinator input. `response_rdata` and
`response_rresp` are top-facing only. Every fanout has one source.

The selected top concatenates the three leaf FSM definitions after its `?top`
body. There is no nested structural top. Exact compiler evidence is 27 public
signals, three generated FSM children, 41 composition nets, 44 resolved links,
lane C4, and no diagnostics.

## 7. Exact behavior

For each accepted aligned command:

1. capture address/expected ARID, pulse private AR start, and raise aggregate
   busy;
2. let the unchanged AR child hold fixed metadata and retained payload until
   one ARVALID/ARREADY transfer;
3. observe its later `ar_done_i`, pulse public request done and private R arm
   together, and mark the response owned;
4. let the unchanged R child raise and hold RREADY independently of RVALID
   until one RVALID/RREADY transfer;
5. after `r_done_i`, compare captured RID/RLAST with retained ARID/high,
   preserve raw result, lower busy, and pulse full transaction done; and
6. hold captured raw result and match statuses until reset or later completion.

There is no combinational ARREADY-to-RREADY path. R is never armed before the
owned AR request completes. An already-high legal RVALID is held by the
subordinate until later RREADY and accepted once. A pre-arm transient RVALID is
unowned and ignored. Held-high RVALID cannot produce a second acceptance
because the one-beat child drops RREADY.

RID mismatch and missing RLAST each produce match status zero plus an emitted
assertion. With assertions disabled, the consumed response still retires and
the top returns idle. Every two-bit RRESP value is raw terminal status and does
not suppress completion or change match results.

Misaligned idle command attempts assert and launch no AR. Commands while busy
are ignored and not queued. Reset from idle, AR issue, or R wait returns every
child and aggregate activity/VALID/READY/pulse/status output to generated reset
values and abandons local ownership without a phantom R or transaction done.

## 8. Exact report and artifact contract

Report schema:
`fsmgen.ial2.protocol_intent.axi_read_transaction_composition.v1`.

Required sections and exact top-level meanings:

- `mode = read-transaction-composition`;
- standard layering with `direct_ial2_to_ial0 = false`;
- source object with thirteen ordered anchors;
- target `{profile=axi4, object=axi-read-transaction-composition,
  role=manager}`;
- `composition` with topology `flat_fixed_single_beat_ar_r_transaction`, three
  exact children, shared system ports, 27 top-port entries, 41 nets, 44 links,
  and explicit/same-name/fanout wiring policy;
- cloned public `bindings` for command/AR/R/status;
- `single_beat_policy` with address32/data32/ID4, alignment4, LEN0/SIZE2/INCR,
  beat count one, request completion `ar_request_accepted`, response completion
  `r_beat_accepted_and_captured`, and RLAST expected high;
- `ar_driver_reuse` with shipped generator identity, unchanged bindings,
  fixed top literals, and one retained leaf;
- `r_acceptor_reuse` with shipped generator identity, unchanged raw capture,
  private arm, and one retained leaf;
- `transaction_coordinator` with exact actor, idle admission, atomic capture,
  `arm_after_request_completion`, aggregate busy/request/full completion,
  retained-ARID and fixed-RLAST comparisons, terminal assertion/status policy,
  raw RRESP, and queue depth zero;
- three `children` entries in AR, R, coordinator order;
- three generated schedule entries in that order; and
- exact generated artifacts/static rules/residue below.

Generated IAL1 items, in order:

```text
axi_ar_driver.isf
axi_r_beat_acceptor.isf
axi_read_transaction_coordinator.isf
```

Generated IAL0 leaf items remain in child order. The report's deterministic
IAL0 file list is:

```text
axi_ar_driver.fsm
axi_r_beat_acceptor.fsm
axi_read_transaction_composition.fsm
axi_read_transaction_coordinator.fsm
```

Count is four: three leaves plus the selected structural top. The selected HDL
entry kind is `generated_composition_top`, child count three, entry artifact
`axi_read_transaction_composition.fsm`.

`--emit-schedule-json` reports all three schedules. `--emit-semantic-json`
selects a `top` root, lane C4, three generated FSM children, 27 public signals,
41 nets, 44 links, and the new support id. `--outdir` writes three `.isf`, four
`.fsm`, and selected HDL. `--verify-hdl` must pass Verilator lint and Yosys
synthesis. Strict rejection emits no partial generated output.

## 9. Enforced static rules and residue

The report's exact ordered enforced rules are:

1. `profile must be axi4, object must be axi-read-transaction-composition, and role must be manager`
2. `clock and asynchronous active-low reset are shared by all three generated children`
3. `one idle admission atomically captures aligned address width 32 and ID width 4`
4. `AR metadata is fixed to ARLEN 0, ARSIZE 2, and ARBURST INCR for one four-byte beat`
5. `flat C4 topology reuses unchanged generated AR driver and R beat acceptor actors plus one transaction coordinator`
6. `private AR-start and R-arm/status bindings isolate child-to-child links while captured RID and RLAST fan out from one source`
7. `R is armed only after the owned AR request accepts`
8. `aggregate busy spans admission through R retirement and request/transaction done are distinct one-cycle pulses`
9. `captured RID and RLAST are checked against retained admitted ARID and the fixed-one-beat expectation; either mismatch terminally completes with status zero plus assertion`
10. `captured RID width 4, RDATA width 32, RRESP width 2, and RLAST remain raw transaction results and RRESP is not interpreted as success`
11. `all public bindings, generated internal signals, instance names, and artifact names are distinct`
12. `lowering is IAL2 through three generated IAL1 and three generated leaf IAL0 actors into one structural IAL0 top, never direct IAL2-to-IAL0`

The exact ordered residue entries are:

| ID | Detail |
| --- | --- |
| `axi_read_transaction_composition_capacity_core_integration_deferred` | `Capacity/status read submit/completion, read-data storage, and response-demux integration remain future work.` |
| `axi_read_transaction_composition_outstanding_queueing_deferred` | `Multiple outstanding reads, queues, adjacent back-to-back admission, and response buffering remain future work.` |
| `axi_read_transaction_composition_id_allocation_ordering_demux_deferred` | `Dynamic ID allocation/reuse, same-ID ordering, RID demux, and read-data interleaving remain future work.` |
| `axi_read_transaction_composition_dynamic_multi_beat_deferred` | `Dynamic AR metadata, repeated or multi-beat R receipt, ARLEN/RLAST counting, response aggregation, and burst progression remain future work.` |
| `axi_read_transaction_composition_narrow_unaligned_attributes_deferred` | `Narrow or unaligned transfers, wrapping bursts, and extended AR attributes remain future work.` |
| `axi_read_transaction_composition_response_status_aggregation_deferred` | `Raw RRESP is captured; protocol-neutral status mapping, multi-beat aggregation, and error-RDATA usability policy remain future work.` |
| `axi_read_transaction_composition_extended_r_monitoring_deferred` | `Extended Issue L R sidebands and generated subordinate stall/payload-stability monitoring remain future work.` |
| `axi_read_transaction_composition_write_channels_deferred` | `Write-address, write-data, and write-response behavior remain outside this read composition.` |
| `axi_read_transaction_composition_transaction_interface_deferred` | `Decision 0020 protocol-neutral transaction interfaces remain director-gated future work.` |
| `axi_read_transaction_composition_profile_alias_deferred` | `.axi profile-alias surfacing remains unsupported; this source uses generic .ppif only.` |
| `axi_read_transaction_composition_verification_output_deferred` | `Direct verification-output generation from this IAL2 source remains future work.` |
| `axi_read_transaction_composition_backend_variants_deferred` | `Direct backend lowering, backend-language variants, and VHDL behavior remain future work.` |
| `axi_read_transaction_composition_other_protocols_unchanged` | `AHB and APB behavior remain unchanged.` |

No child residue is silently discarded: each child report remains available
under `children`, while the ordered aggregate residue above states the selected
composition boundary.

## 10. Required diagnostics

Generator failures must contain:

| Invalid contract | Required substring |
| --- | --- |
| wrong kind | `AXI read transaction composition IAL2 contract kind must be axi_read_transaction_composition` |
| wrong profile | `profile must be axi4 in this slice` |
| wrong role | `role must be manager` |
| wrong reset | `reset must be asynchronous active-low in this slice` |
| wrong width | exact `command.*`, `ar_channel.*`, or `r_channel.*.width must be <N>` |
| missing binding/block | name exact missing field/block |
| invalid identifier | exact field and `must be an ISF identifier` |
| duplicate public/private name | `duplicates signal '<name>'` |
| missing AR child/artifact | `missing generated AR child` plus artifact/name |
| missing R child/artifact | `missing generated R child` plus artifact/name |
| duplicate generated file | `generated duplicate .fsm artifact` plus name |
| malformed schedule/artifact count | expected three-child/three-schedule/four-artifact contract |
| malformed fanout/top | exact missing link, driver, child, or top identity |
| `.axi` source | `(axi-read-transaction-composition ...) remains unsupported for the first profile-alias implementation` |

Parser failures identify wrong profile family, cardinality, mixing, duplicate/
unknown clauses, missing blocks, malformed scalar/width bindings, unsupported
role/value, and the exact new object spelling.

The focused fail-closed table includes at least: wrong root/profile family/
AXI revision/role; synchronous and active-high reset; duplicate command;
unknown object clause; missing R channel; missing transaction done; every
missing captured R field and both missing match statuses; attempted dynamic AR
metadata; nested child; mixed standalone AR or R; duplicate aggregate object;
duplicate public binding; generated artifact collision; `.axi` alias rejection;
command address/ID wrong widths; all five AR payload wrong widths; and all six
R bus/captured ID/data/response wrong widths.

## 11. Support accounting and focused test

Add one supported regression entry:

```text
id               = intent.ppif_axi_read_transaction_composition
coverage         = ial2_ppif_axi_read_transaction_composition_pipeline_cli
strict_supported = 1
```

t/248 expected counts move:

```text
protocol entries:             304 -> 305
supported generated entries:  345 -> 346
strict-supported entries:     345 -> 346
```

The `.ppif` capability manifest advertises the shipped AR/R primitives plus
the new bounded full-read composition; t/297 asserts the exact wording.

`t/1506` has exactly four top-level subtests:

1. adapter/report/generated child, schedule, private namespace, fanout, and
   exact C4 artifact contract;
2. malformed/expanded public and in-process contracts fail closed;
3. support/check/schedule/semantic/outdir/verify-HDL use the public source; and
4. generated structural top executes the full transaction matrix.

The executable structural top is compiled with `--no-assert` so terminal
protocol-error behavior can be proved; emitted HDL is separately checked for
the three exact assertion messages. It must prove:

1. reset-idle outputs low and misaligned command non-launch;
2. command 1 with continuous ARREADY and RVALID already high before admission,
   exact retained AR payload/fixed metadata, no pre-AR RREADY, exactly one R
   acceptance, matching ID/last, and raw non-OKAY RRESP;
3. command 2 with four-cycle AR stall, stable payload while public inputs
   mutate, an ignored busy command, then delayed RVALID with held RREADY/busy;
4. command 3 with a one-cycle ARREADY pulse and terminal RID mismatch plus
   missing RLAST plus raw non-OKAY RRESP;
5. reset while command 4 is stalled before AR acceptance, producing no AR/
   request/R/transaction event;
6. reset after command 5 AR acceptance while R is armed, preserving its AR and
   request event but producing no R/transaction event; and
7. command 6 clean post-reset recovery, captured raw result, and final idle.

The exact final line is:

```text
PASS ar=5 r=4 request=5 transaction=4 mismatch_terminal=1 missing_last_terminal=1 reset_abort=2
```

The one-count request/transaction difference is mandatory reset truth, not a
test relaxation. Every non-reset admitted command otherwise produces exactly
one AR, one request-done, one R, and one transaction-done.

## 12. Implementation owner, validation, and rollback

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.34` implements this contract exactly. It
owns:

- new `AxiReadTransactionComposition.pm` with defensive public generation/
  report methods, child result reuse, coordinator generation, and top assembly;
- PPIF import/dispatch/accumulator/cardinality/mixing/missing enumeration,
  object/block parsers, predicate, and `.axi` rejection;
- exact thirteen-anchor public source, support entry/counts, capability
  manifest wording/assertion, and t/1506;
- AXI mdBook shipped behavior and runnable public commands;
- task/index/Memory/behavior-fact/Knowledge Map synchronization; and
- syntax, t/1499-t/1506+t248+t297, public strict/check/schedule/semantic/outdir/
  Verilator/Yosys/executable-top proof, mdBook, continuity, whitespace, and
  doctrine gates under repository RAM policy.

Rollback for `.34` removes only the new full-read module/parser/source/support/
manifest/test/docs/fact changes and restores `.33` active. Standalone AR/R,
both write compositions, capacity/status, and every deferred surface remain
behaviorally unchanged.

This selector is documentation-only. Validate Knowledge Map generation/check,
mdBook, docs paths, bounded Memory, whitespace, and doctrines. Selector
rollback removes this contract/fact, restores `.33` active, removes `.34` as an
eligible implementation leaf, and restores prior task-index/book/Memory
pointers; no behavior rollback is required.
