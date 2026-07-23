# IAL2 AXI manager initiator — full-write transaction composition contract selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.21` (behavior-neutral contract
selection).

Date: 2026-07-23

Status: exact public/generator/report/test contract selected. The following
leaf, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.22`, owns implementation.

This selector changes no parser, generator, public source, support-accounting
entry, capability manifest, test, generated artifact, runtime behavior, or HDL
behavior.

## 1. Selected Identity

| Facet | Selected value |
| --- | --- |
| PPIF clause/object | `(axi-write-transaction-composition ...)` / `axi-write-transaction-composition` |
| parser contract `kind` | `axi_write_transaction_composition` |
| generator | `FSM::IAL2::ProtocolIntent::AxiWriteTransactionComposition` |
| generated result `kind` | `protocol_intent.axi_write_transaction_composition` |
| report schema | `fsmgen.ial2.protocol_intent.axi_write_transaction_composition.v1` |
| result mode | `write-transaction-composition` |
| public source | `ppif/axi_write_transaction_composition.ppif` |
| intent/object/top | `axi_write_transaction_composition` |
| transaction coordinator | `axi_write_transaction_coordinator` |
| selected IAL0/HDL entry | `axi_write_transaction_composition.fsm` |
| support id | `intent.ppif_axi_write_transaction_composition` |
| coverage key | `ial2_ppif_axi_write_transaction_composition_pipeline_cli` |
| focused test | `t/1503-ial2-axi-write-transaction-composition.t` |

“Transaction” is selected over “transactor” in public spelling because this
object composes one complete bounded AXI write transaction: request issue plus
its B response. “Composition” remains explicit because the implementation is
five generated actors under a structural top, not one monolithic FSM.

The aggregate role is exactly `manager`. Directional
`manager-to-subordinate` is rejected for this object because the full boundary
both drives AW/W and accepts subordinate-to-manager B.

## 2. Exact Public Source

```text
(protocol-platform-intent axi_write_transaction_composition
  (profile axi4)
  (source
    (object axi-write-transaction-composition)
    (anchor (document IHI0022_L_2025-08) (section A3.2.1) (page A3-40))
    (anchor (document IHI0022_L_2025-08) (section A2.3) (page 29))
    (anchor (document IHI0022_L_2025-08) (section A2.3.1) (page 30))
    (anchor (document IHI0022_L_2025-08) (section A2.3.2.1) (page 31))
    (anchor (document IHI0022_L_2025-08) (section A3.2.1) (page 53))
    (anchor (document IHI0022_L_2025-08) (section A3.2.1.1) (page 54))
    (anchor (document IHI0022_L_2025-08) (section A3.3) (page 61))
    (anchor (document IHI0022_L_2025-08) (section A3.3.1) (page 61))
    (anchor (document IHI0022_L_2025-08) (section B1.1.3) (page 278)))
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
      (response-id-match response_id_match))))
```

All nine anchors are mandatory in that order. They are the de-duplicated union
of the shipped request composition and B acceptor dependencies. The two
`A3.2.1` anchors intentionally carry different page forms already required by
the request contract; neither is silently normalized away.

### Public semantics

- `write_cmd_valid` is a level-sampled idle admission request, not a queue or
  edge-capture promise.
- `cmd_awaddr`, `cmd_awid`, `cmd_wdata`, and `cmd_wstrb` are captured atomically
  on one aligned admission.
- AW/W retain the shipped 32-bit address/data, four-bit ID/strobe, fixed
  `AWLEN=0`, `AWSIZE=2`, `AWBURST=INCR`, and `WLAST=1` policy.
- all WSTRB values, including zero, remain legal.
- `write_busy` covers public admission through B response retirement.
- `write_request_done` pulses after both AW and W handshakes and at B arming.
- `write_transaction_done` pulses after the B child captures BID/BRESP and
  retires its armed response transaction.
- `response_bid` and `response_bresp` hold the last captured raw response.
- `response_id_match` is stable status written at full completion; one means
  captured BID equals the retained admitted AWID, zero means mismatch.
- transaction done does not imply BRESP is OKAY.

## 3. Parser Contract

`_contract_from_root` gains an `@axi_write_transaction_compositions`
accumulator and `axi-write-transaction-composition` clause arm. Root policy:

- require an AXI-family profile at dispatch, then pin exact `axi4` in the
  generator;
- require exactly one full-write composition object;
- reject mixing with Valid-Ready channels/bundles, manager-capacity-status,
  standalone AW/W/B, the AW+W request composition, or APB/AHB objects;
- add the new object to every existing standalone/aggregate mixing count; and
- include it in the missing-intent enumeration.

`_parse_axi_write_transaction_composition` requires these object clauses once:

```text
role clock reset command aw-channel w-channel b-channel status
```

The block parsers require exactly:

```text
command:    start=scalar, address=width, id=width, data=width, strobe=width
aw-channel: ready=scalar, valid=scalar, address=width, id=width,
            length=width, size=width, burst=width
w-channel:  ready=scalar, valid=scalar, data=width, strobe=width, last=scalar
b-channel:  valid=scalar, ready=scalar, id=width, response=width,
            captured-id=width, captured-response=width
status:     busy=scalar, request-done=scalar, transaction-done=scalar,
            response-id-match=scalar
```

Hyphenated fields normalize to underscore keys. The contract returned to the
generator is:

```text
kind       = axi_write_transaction_composition
name       = <object name>
role       = manager
clock/reset
command    = { start, address{name,width}, id{name,width},
               data{name,width}, strobe{name,width} }
aw_channel = { ready, valid, address, id, length, size, burst }
w_channel  = { ready, valid, data, strobe, last }
b_channel  = { valid, ready, id, response, captured_id,
               captured_response }
status     = { busy, request_done, transaction_done, response_id_match }
protocol/source/intent_name
```

Duplicate or unsupported clauses fail in PPIF parsing. The generic binding
parser enforces scalar versus exact `width` forms before generation.

### `.axi` policy

Generic `.ppif` only. `_validate_profile_alias_contract` rejects:

```text
(axi-write-transaction-composition ...) remains unsupported for the first profile-alias implementation
```

No `.axi` fixture or capability is added.

## 4. Generator Normalization And Private Namespace

The generator pins:

- exact kind, profile `axi4`, role `manager`, and asynchronous active-low reset;
- command address/data widths 32, command ID/strobe widths 4;
- AW address32/ID4/length8/size3/burst2;
- W data32/strobe4 and scalar last;
- B bus/captured ID widths 4 and bus/captured response widths 2; and
- all scalar bindings to width one.

All public signal names must be distinct from one another and from this fixed
private/reserved set:

```text
request_cmd_valid_i  request_awaddr_i  request_awid_i
request_wdata_i      request_wstrb_i   request_busy_i
request_done_i       b_arm_i           b_busy_i
b_done_i             captured_bid_i
active_q              response_armed_q expected_awid_q
```

The generator also reserves all actor, instance, and artifact identities fixed
by this contract against authored object/binding collisions where applicable.

### Exact child reuse

The generator invokes `AxiWriteRequestComposition->generate` with:

- the public AW/W bus bindings;
- exact fixed single-beat policy inherited from that generator;
- the seven private request command/status bindings above;
- actor/top name `axi_write_request_private`; and
- the six request-side anchors from the public source.

It retains the request result's three IAL1 items, three schedule reports, and
three `generated_endpoint` IAL0 items/files. It must discard the unselected
`axi_write_request_private.fsm` structural top from the returned full-write
artifact set. It does not copy or recreate AW, W, or request-coordinator ISF.

The generator separately invokes `AxiBResponseAcceptor->generate` with public
B bus/captured-response bindings and private `b_arm_i`, `b_busy_i`, `b_done_i`,
using the six B-side anchors. The B actor is otherwise unchanged.

The new generator emits only `axi_write_transaction_coordinator.isf` itself,
lowers it through the normal ISF scheduler, and builds the selected full top.

## 5. Exact Transaction-Coordinator IAL1 Target

```text
(actor axi_write_transaction_coordinator
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input write_cmd_valid)
    (input cmd_awaddr (width 32))
    (input cmd_awid (width 4))
    (input cmd_wdata (width 32))
    (input cmd_wstrb (width 4))
    (input request_busy_i)
    (input request_done_i)
    (input b_busy_i)
    (input b_done_i)
    (input captured_bid_i (width 4))
    (output request_cmd_valid_i)
    (output request_awaddr_i (width 32))
    (output request_awid_i (width 4))
    (output request_wdata_i (width 32))
    (output request_wstrb_i (width 4))
    (output b_arm_i)
    (output write_busy)
    (output write_request_done)
    (output write_transaction_done)
    (output response_id_match))

  (priority finish_response over admit)
  (priority finish_response over arm_response)
  (priority finish_response over clear_transaction_done)
  (priority arm_response over clear_b_arm)
  (priority arm_response over clear_request_done)
  (priority admit over clear_request_start)

  (rule admit
    (& (! active_q) (! request_busy_i) (! b_busy_i)
       write_cmd_valid (! cmd_awaddr[0]) (! cmd_awaddr[1]))
    (set active_q 1)
    (set request_cmd_valid_i 1)
    (set request_awaddr_i cmd_awaddr)
    (set request_awid_i cmd_awid)
    (set request_wdata_i cmd_wdata)
    (set request_wstrb_i cmd_wstrb)
    (set expected_awid_q cmd_awid)
    (set write_busy 1))

  (rule clear_request_start request_cmd_valid_i
    (set request_cmd_valid_i 0))

  (rule arm_response
    (& active_q (! response_armed_q) request_done_i (! b_busy_i))
    (set response_armed_q 1)
    (set b_arm_i 1)
    (set write_request_done 1))

  (rule clear_b_arm b_arm_i
    (set b_arm_i 0))

  (rule clear_request_done write_request_done
    (set write_request_done 0))

  (rule finish_response
    (& active_q response_armed_q b_done_i)
    (set active_q 0)
    (set response_armed_q 0)
    (set write_busy 0)
    (set write_transaction_done 1)
    (set response_id_match (== captured_bid_i expected_awid_q)))

  (rule clear_transaction_done write_transaction_done
    (set write_transaction_done 0))

  (transaction aligned_command_check
    (assert
      (=> (& (! active_q) (! request_busy_i) (! b_busy_i) write_cmd_valid)
          (& (! cmd_awaddr[0]) (! cmd_awaddr[1])))
      "single-beat AXI write transaction address must be four-byte aligned"))

  (transaction response_id_check
    (assert
      (=> (& active_q response_armed_q b_done_i)
          (== captured_bid_i expected_awid_q))
      "accepted AXI BID must match admitted AWID")))
```

The exact schedule has zero states, no procedural transactions, no compile
issues, and seven rule blocks with assignment counts:

```text
admit                    8
clear_request_start      1
arm_response             3
clear_b_arm              1
clear_request_done       1
finish_response          5
clear_transaction_done   1
```

The six authored priorities are required. Four resolve scheduled pulse-write
conflicts:

```text
admit           > clear_request_start    : request_cmd_valid_i
arm_response    > clear_b_arm             : b_arm_i
arm_response    > clear_request_done      : write_request_done
finish_response > clear_transaction_done  : write_transaction_done
```

The other two authored orderings defensively document mutually exclusive
active/armed state transitions and do not add realized schedule rows.

## 6. Exact Flat C4 Structural Top

Immediate children and instances are exactly:

```text
(?fsmc:aw_driver axi_aw_driver)
(?fsmc:w_driver axi_w_driver)
(?fsmc:request_coordinator axi_write_request_coordinator)
(?fsmc:b_acceptor axi_b_response_acceptor)
(?fsmc:transaction_coordinator axi_write_transaction_coordinator)
```

The top has 29 ports: shared clock/reset, ten non-system inputs, and seventeen
outputs. Public bindings are those in section 2. The fixed literal and explicit
internal wiring is:

```text
(aw_driver.aw_busy request_coordinator.aw_busy)
(aw_driver.aw_done request_coordinator.aw_done)
(w_driver.w_busy request_coordinator.w_busy)
(w_driver.w_done request_coordinator.w_done)
(request_coordinator.aw_cmd_valid aw_driver.aw_cmd_valid)
(request_coordinator.aw_cmd_awaddr aw_driver.aw_cmd_awaddr)
(request_coordinator.aw_cmd_awid aw_driver.aw_cmd_awid)
(=8'd0 aw_driver.cmd_awlen)
(=3'd2 aw_driver.cmd_awsize)
(=2'b01 aw_driver.cmd_awburst)
(request_coordinator.w_cmd_valid w_driver.w_cmd_valid)
(request_coordinator.w_cmd_wdata w_driver.w_cmd_wdata)
(request_coordinator.w_cmd_wstrb w_driver.w_cmd_wstrb)
(transaction_coordinator.request_cmd_valid_i request_coordinator.request_cmd_valid_i)
(transaction_coordinator.request_awaddr_i request_coordinator.request_awaddr_i)
(transaction_coordinator.request_awid_i request_coordinator.request_awid_i)
(transaction_coordinator.request_wdata_i request_coordinator.request_wdata_i)
(transaction_coordinator.request_wstrb_i request_coordinator.request_wstrb_i)
(request_coordinator.request_busy_i transaction_coordinator.request_busy_i)
(request_coordinator.request_done_i transaction_coordinator.request_done_i)
(transaction_coordinator.b_arm_i b_acceptor.b_accept_cmd_valid)
(b_acceptor.b_busy transaction_coordinator.b_busy_i)
(b_acceptor.b_done transaction_coordinator.b_done_i)
(b_acceptor.response_bid transaction_coordinator.captured_bid_i)
```

All remaining public bus/command/status links use exact same-name C4 binding.
`response_bid` fans out to the public top and the distinct private
`captured_bid_i` input through the explicit link. `response_bresp` is top-
facing only.

The request private top is not nested or returned. The selected top concatenates
the five leaf FSM definitions after its `?top` body, following the shipped C4
artifact pattern.

## 7. Exact Behavior

For each accepted aligned command:

1. capture all request payload plus expected AWID, pulse private request start,
   and raise aggregate busy;
2. let the unchanged request coordinator start AW/W and join either completion
   order;
3. observe its one request-done pulse, pulse public request done and B arm, and
   mark the response owned;
4. keep aggregate busy high while the unchanged B acceptor asserts/holds
   BREADY until one BVALID/BREADY transfer;
5. after B done, compare captured BID with expected AWID, hold match status,
   lower busy, and pulse full transaction done; and
6. hold captured BID/BRESP and match status until a later response updates
   them.

B is never armed before both request channels transfer. An already-high legal
BVALID must be held until BREADY and is accepted once. A pre-arm transient
BVALID is unowned and ignored. A mismatch still retires with match status zero
because the response has already been consumed; the generated ID assertion
makes the protocol violation visible. Any two-bit BRESP is captured and
completes transport.

Misaligned idle command attempts assert and launch no request. Commands while
aggregate busy are ignored and not queued. Reset from any phase returns all
child and aggregate activity/VALID/READY/pulse outputs low and abandons the
in-flight local transaction without a phantom completion.

## 8. Exact Report And Artifact Contract

Report schema:
`fsmgen.ial2.protocol_intent.axi_write_transaction_composition.v1`.

Required sections:

- `mode = write-transaction-composition`;
- standard layering with `direct_ial2_to_ial0 = false`;
- source object with nine anchors;
- target `{profile=axi4, object=axi-write-transaction-composition,
  role=manager}`;
- `composition` with topology
  `flat_single_beat_aw_w_b_transaction`, five exact children, shared system
  ports, 29 top-port entries, and explicit wiring policy;
- cloned public `bindings` for command/AW/W/B/status;
- `single_beat_policy` with address32/data32/ID4/strobe4, alignment4,
  LEN0/SIZE2/INCR/WLAST1/zero-strobe-allowed, request completion after AW+W,
  response completion after B capture;
- `request_composition_reuse` with generator identity, private bindings,
  three retained leaves, and `nested_top_selected = false`;
- `transaction_coordinator` with exact actor, idle admission, atomic capture,
  `arm_after_request_completion`, busy/request/full completion policies,
  retained-AWID comparison, mismatch terminal+assert policy, raw BRESP, and
  queue depth zero;
- five `children` entries;
- five generated schedule entries;
- exact generated artifacts/static rules/residue below.

Generated IAL1 items, in order:

```text
axi_aw_driver.isf
axi_w_driver.isf
axi_write_request_coordinator.isf
axi_b_response_acceptor.isf
axi_write_transaction_coordinator.isf
```

Generated IAL0 items/files are those five matching `.fsm` leaves plus selected
`axi_write_transaction_composition.fsm`. Count is six. The selected HDL entry
kind is `generated_composition_top`, child count five. There is no
`axi_write_request_private.fsm` in the returned files or `--outdir` output.

`--emit-schedule-json` reports all five schedules. `--emit-semantic-json`
selects a `top` root, lane C4, five children, and support id. `--outdir` writes
five `.isf`, six `.fsm`, and selected HDL. `--verify-hdl` must pass Verilator
lint and Yosys synthesis.

## 9. Enforced Static Rules And Residue

The report's enforced rules state:

1. exact AXI4 profile, full-write object, and manager role;
2. one asynchronous active-low shared reset/clock;
3. one aligned idle command captured atomically;
4. exact fixed one-beat AW/W policy including zero strobe;
5. flat five-child C4 topology using unchanged AW/W/request/B actors;
6. private request/B status namespace and no nested request top;
7. B arm only after request completion;
8. aggregate busy through B retirement and separate request/full done pulses;
9. retained AWID matched to captured BID with terminal mismatch+assertion;
10. raw two-bit BRESP is captured, not interpreted as success;
11. all public/private/reserved names and artifacts are distinct; and
12. five IAL1 -> five leaf IAL0 -> one structural top, never direct lowering.

Exact residue IDs cover:

- capacity/status submission/completion/demux integration;
- multiple outstanding writes, queues, adjacent back-to-back admission, and
  response buffering;
- dynamic IDs/allocation and same-ID/different-ID ordering;
- multi-beat W, dynamic WLAST/AW metadata, burst address generation, narrow/
  unaligned placement, and added attributes;
- BRESP-to-higher-level-status interpretation and extended B sidebands;
- AR/R behavior;
- decision `0020` transaction-interface activation;
- `.axi` aliasing and verification-output generation;
- direct backend, backend-language variants, and VHDL; and
- AHB/APB behavior.

## 10. Required Diagnostics

Generator failures must contain:

| Invalid contract | Required substring |
| --- | --- |
| wrong kind | `AXI write transaction composition IAL2 contract kind must be axi_write_transaction_composition` |
| wrong profile | `profile must be axi4 in this slice` |
| wrong role | `role must be manager` |
| wrong reset | `reset must be asynchronous active-low in this slice` |
| wrong width | exact `command.*`, `aw_channel.*`, `w_channel.*`, or `b_channel.*.width must be <N>` |
| missing binding/block | name exact missing field/block |
| invalid identifier | exact field and `must be an ISF identifier` |
| duplicate public/private name | `duplicates signal '<name>'` |
| missing request leaf/artifact | `missing generated request child` plus artifact/name |
| retained nested request top | `must not retain nested request composition top` |
| duplicate generated file | `generated duplicate .fsm artifact` plus name |
| malformed schedule/artifact count | name expected five-child/five-schedule/six-artifact contract |
| `.axi` source | `(axi-write-transaction-composition ...) remains unsupported for the first profile-alias implementation` |

Parser failures identify wrong profile family, cardinality, mixing, duplicate/
unknown clauses, missing blocks, malformed widths, unsupported role/value, and
the exact new object spelling.

## 11. Support Accounting And Focused Test

Add one supported regression entry:

```text
id               = intent.ppif_axi_write_transaction_composition
coverage         = ial2_ppif_axi_write_transaction_composition_pipeline_cli
strict_supported = 1
```

t/248 expected counts move:

```text
protocol entries:          301 -> 302
supported generated entries: 342 -> 343
strict-supported entries:     342 -> 343
```

The `.ppif` capability manifest advertises both the existing request-only
composition and the new full-write composition; t/297 asserts the new boundary.

`t/1503` has exactly four top-level subtests:

1. adapter/report/generated child, schedule, private namespace, and exact C4
   artifact contract;
2. malformed/expanded public and in-process contracts fail closed;
3. support/check/schedule/semantic/outdir/verify-HDL use the public source; and
4. generated structural top executes the full transaction matrix.

The executable top must prove the twelve scenarios from the readiness audit,
including aligned atomic capture; simultaneous/AW-first/W-first request issue;
four-cycle AW, W, and B stalls; BREADY low before request done; already-high
and delayed BVALID; zero WSTRB; matching and mismatched BID; raw OKAY plus one
non-OKAY BRESP; ignored commands in request and response phases; reset during
request/B wait; assertion-disabled mismatch terminal completion;
assertion-enabled alignment and BID failures; exact one AW/W/B/request/full
event per admitted command; and final idle.

## 12. Implementation Owner, Validation, And Rollback

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.22` implements this contract exactly.
It owns:

- new `AxiWriteTransactionComposition.pm`;
- PPIF import/dispatch/accumulator/cardinality/mixing/missing enumeration,
  object/block parsers, predicate, and `.axi` rejection;
- public source, support entry/counts, manifest prose/assertion, and t/1503;
- AXI mdBook shipped behavior and runnable commands;
- task/index/Memory/Knowledge Map synchronization; and
- focused child regressions, CLI/semantic/schedule/outdir/Verilator/Yosys/
  executable-top proof plus doctrine gates under RAM policy.

Rollback for `.22` removes only the new full-write module/parser/source/
support/manifest/test/docs/fact changes and restores `.21` active. Standalone
AW/W/B, the shipped request composition, capacity/status, and every deferred
surface remain byte-for-byte behaviorally unchanged.

This selector is documentation-only. Validate Knowledge Map generation/check,
mdBook, docs paths, bounded Memory, whitespace, and doctrines. Rollback removes
this contract/fact, restores `.21` active, removes `.22`, and restores the prior
task-index/book/Memory pointers; no behavior rollback is required.
