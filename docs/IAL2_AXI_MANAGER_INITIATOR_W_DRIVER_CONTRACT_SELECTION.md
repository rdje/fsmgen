# IAL2 AXI manager initiator — bounded W driver contract selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.9` (behavior-neutral contract
selection).

Status: exact public/generator/report/test contract selected. The following
leaf, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.10`, owns implementation.

This selector changes no parser, generator, public source, support-accounting
entry, capability manifest, test, generated artifact, runtime behavior, or HDL
behavior.

## 1. Outcome

The first AXI W driver will be a new additive `.ppif` object and generated
module named `axi_w_driver`. It accepts one one-shot local command containing
32-bit data and four byte strobes, drives one W beat with `WLAST = 1`, and uses
the corrected six-state priority-resolved schedule already proven by the AW
driver.

| Facet | Selected value |
| --- | --- |
| PPIF clause/object | `(axi-w-driver ...)` / `axi-w-driver` |
| parser contract `kind` | `axi_w_driver` |
| generator | `FSM::IAL2::ProtocolIntent::AxiWDriver` |
| generated result `kind` | `protocol_intent.axi_w_driver` |
| report schema | `fsmgen.ial2.protocol_intent.axi_w_driver.v1` |
| result mode | `driver` |
| public source | `ppif/axi_w_driver.ppif` |
| intent/actor/module name | `axi_w_driver` |
| generated IAL1 | `axi_w_driver.isf` |
| generated IAL0 | `axi_w_driver.fsm` |
| support id | `intent.ppif_axi_w_driver` |
| coverage key | `ial2_ppif_axi_w_driver_pipeline_cli` |
| focused test | `t/1500-ial2-axi-w-driver.t` |

This is a distinct generator rather than an option on `AxiAwDriver`: AW and W
are independent AXI channels with different payload contracts, and decision
`0017` does not make an AW/W monitor bundle into a transaction-level driver.

## 2. Selected public source

```text
(protocol-platform-intent axi_w_driver
  (profile axi4)
  (source
    (object axi-w-driver)
    (anchor (document IHI0022_L_2025-08) (section A2.3) (page 29))
    (anchor (document IHI0022_L_2025-08) (section A2.3.1) (page 30))
    (anchor (document IHI0022_L_2025-08) (section A2.3.2.1) (page 31))
    (anchor (document IHI0022_L_2025-08) (section A3.2.1) (page 53))
    (anchor (document IHI0022_L_2025-08) (section A3.2.1.1) (page 54)))
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
      (done w_done))))
```

The source carries all five audited anchors. Page numbers are physical PDF
pages and printed page numbers; they were rendered and visually checked in
`.8`.

### Binding semantics

The `(command ...)` block is the upstream order and contains only inputs. The
`(channel ...)` block is the driven W interface plus local status and contains
only outputs.

- `w_cmd_valid` is a one-shot trigger. The current single-transaction actor
  accepts it only while idle; no command-ready output or command queue is added.
- `cmd_wdata[31:0]` and `cmd_wstrb[3:0]` are sampled once on that trigger.
- `wready` is the subordinate-owned W acceptance input. It is grouped with the
  command inputs, matching the shipped AW source's placement of `awready`.
- `wvalid`, `wdata[31:0]`, `wstrb[3:0]`, and scalar `wlast` are driven W-channel
  outputs.
- `wlast` is not command data. The generator drives it to one when launching
  the only beat and holds it throughout any stall.
- `w_busy` is high from launch through acceptance; `w_done` is one pulse after
  the transaction completes through the standard ISF `(complete ...)` path.
- Every `cmd_wstrb` value is valid, including `4'b0000`.

The distinct `cmd_w*` and `w*` names are mandatory defaults, following the AW
driver and AHB requester separation between a local order and driven bus
signals. All bindings remain rebindable identifiers in authored `.ppif`.

## 3. Parser contract

### Root object and cardinality

`FSM::Adapter::IAL2::PPIF::_contract_from_root` gains an `@axi_w_drivers`
accumulator and an `axi-w-driver` clause arm. The selected root policy is:

- require an AXI-family root profile at root dispatch, then let the generator
  pin the first implementation to exact `axi4`, matching AW;
- require exactly one `(axi-w-driver ...)` object;
- reject mixing it with a valid-ready channel/bundle, manager-capacity object,
  AW driver, APB object, or AHB object; and
- include `(axi-w-driver ...)` in the missing-intent-object enumeration.

An AW driver and a W driver in the same source are therefore rejected. Their
future composition needs an explicit aggregate/transaction owner and must not
emerge accidentally from parser relaxation.

### Clause parsing

`_parse_axi_w_driver` requires exactly these top-level fields once each:

```text
role clock reset command channel
```

`_parse_axi_w_driver_command_block` accepts and requires:

```text
start=scalar data=width strobe=width ready=scalar
```

`_parse_axi_w_driver_channel_block` accepts and requires:

```text
valid=scalar data=width strobe=width last=scalar busy=scalar done=scalar
```

Any unsupported or duplicate clause fails at the PPIF parser. The resulting
contract is:

```text
kind       = axi_w_driver
name       = <object name>
role       = manager-to-subordinate
clock      = <identifier>
reset      = <normalized reset>
command    = { start, data{name,width}, strobe{name,width}, ready }
channel    = { valid, data{name,width}, strobe{name,width}, last, busy, done }
protocol   = <root profile>
source     = <object + anchors>
intent_name = <root name>
```

### `.axi` alias policy

The W driver ships only through generic `.ppif`. The implementation adds a
W-specific `.axi` rejection before the existing bundle/manager guard, with the
diagnostic substring `(axi-w-driver ...) remains unsupported for the first
profile-alias implementation`. This prevents silently accepting an unaccounted
W-driver `.axi` source without changing the existing AW alias behavior or the
existing bundle/manager diagnostic. No `.axi` fixture is added.

## 4. Generator normalization and fail-closed diagnostics

`AxiWDriver::_normalize_contract` mirrors the defensive AW generator envelope
and pins all first-slice semantics.

| Invalid contract | Required diagnostic substring |
| --- | --- |
| wrong contract kind | `AXI W driver IAL2 contract kind must be axi_w_driver` |
| profile other than exact AXI4 | `AXI W driver IAL2 contract profile must be axi4 in this slice` |
| wrong role | `AXI W driver IAL2 contract role must be manager-to-subordinate` |
| wrong command data width | `command.data.width must be 32 in this slice` |
| wrong channel data width | `channel.data.width must be 32 in this slice` |
| wrong command strobe width | `command.strobe.width must be 4 in this slice` |
| wrong channel strobe width | `channel.strobe.width must be 4 in this slice` |
| absent scalar/binding | identify the exact missing `command.*` or `channel.*` field |
| invalid identifier | identify the exact field and require an ISF identifier |
| duplicate interface/internal name | `AXI W driver IAL2 contract duplicates signal '<name>'` |
| W driver authored with `.axi` suffix | `(axi-w-driver ...) remains unsupported for the first profile-alias implementation` |

Root parser errors retain the AW-shaped wording with `axi-w-driver`: wrong
profile family, more than one object, mixed intent objects, duplicate/unsupported
clauses, and missing required blocks all identify the source and object.

The duplicate-name set includes clock, reset, every command/channel binding,
and reserved locals `data_q`, `strb_q`, and `active_q`. `wlast` is scalar by
construction; there is no author-controlled width or last value. Zero strobe is
not an error.

## 5. Exact generated IAL1 target

The generated actor is fixed as follows (binding substitutions are allowed;
control structure is not):

```text
(actor axi_w_driver
  (clock clk)
  (reset (rst_n async active_low))

  (interface
    (input w_cmd_valid)
    (input cmd_wdata (width 32))
    (input cmd_wstrb (width 4))
    (input wready)
    (output wvalid)
    (output wdata (width 32))
    (output wstrb (width 4))
    (output wlast)
    (output w_busy)
    (output w_done))

  (priority accept_w over launch_w)

  (rule launch_w launch_w_start
    (set active_q 1)
    (set w_busy 1)
    (set wvalid 1)
    (set wdata data_q)
    (set wstrb strb_q)
    (set wlast 1))

  (rule accept_w (& wvalid wready)
    (set active_q 0)
    (set w_busy 0)
    (set wvalid 0))

  (transaction w_issue
    (on w_cmd_valid
      (sample cmd_wdata as data_q)
      (sample cmd_wstrb as strb_q))
    (drive
      (launch_w_start 1))
    (while active_q
      (wait 1))
    (complete w_done)))
```

This must schedule to six states with `compile_issues = []` and exactly these
priority-resolution triples:

```text
accept_w : launch_w : active_q
accept_w : launch_w : w_busy
accept_w : launch_w : wvalid
```

The acceptance rule clears valid on the same edge that recognizes
`WVALID && WREADY`; continuously-high READY therefore cannot accept the same
command twice. Data/strobe/last are written only at launch and remain stable
through any stall. Lowering remains IAL2 -> generated `axi_w_driver.isf` ->
generated `axi_w_driver.fsm` -> HDL, never direct IAL2 -> IAL0.

## 6. Exact report contract

The report schema is
`fsmgen.ial2.protocol_intent.axi_w_driver.v1`, with:

- `mode = driver`;
- `layering` identical to AW (`source_layer = IAL2`, generated formats `isf`
  and `fsm`, `direct_ial2_to_ial0 = false`);
- `source_object { id, intent_name, anchors[] }`;
- `target_protocol { profile = axi4, object = axi-w-driver,
  role = manager-to-subordinate }`;
- `driver { name, actor_name }`;
- cloned `bindings { clock, reset, command, channel }`;
- `single_beat { data_width = 32, strobe_width = 4, last_value = 1,
  all_zero_strobe_allowed = true }`;
- generated IAL1/IAL0/HDL-entry artifacts; and
- the exact static rules and residue below.

### Enforced static rules

1. profile must be `axi4` and object must be `axi-w-driver`;
2. role must be `manager-to-subordinate`;
3. W data width is 32;
4. W strobe width is 4 and equals data width divided by eight;
5. the first slice emits one beat with scalar `WLAST` fixed high while valid;
6. all-zero WSTRB is legal;
7. command inputs and driven channel/status outputs are distinct; and
8. direct IAL2-to-IAL0 lowering is forbidden.

### Exact unsupported-residue ids

| Id | Meaning |
| --- | --- |
| `axi_w_driver_aw_coordination_deferred` | no coordinated AW+W transaction launch or completion |
| `axi_w_driver_b_response_completion_deferred` | no B-channel observation, response, or transaction completion |
| `axi_w_driver_multi_beat_deferred` | no beat counter, data sequence, or dynamic `WLAST` |
| `axi_w_driver_outstanding_transactions_deferred` | one active command only; no queue or multiple outstanding writes |
| `axi_w_driver_burst_address_coupling_deferred` | no AWLEN/AWSIZE/address coupling to the W beat |
| `axi_w_driver_ar_r_channels_deferred` | read-address/read-data behavior remains outside this write primitive |
| `axi_w_driver_capacity_core_integration_deferred` | no integration with `AxiManagerCapacityStatus` |
| `axi_w_driver_transaction_interface_deferred` | decision `0020`'s protocol-neutral transaction interface/composition is not activated |
| `axi_w_driver_profile_alias_deferred` | no `.axi` W-driver source |
| `axi_w_driver_verification_output_deferred` | no direct verification-output generation from this IAL2 source |
| `axi_w_driver_backend_variants_deferred` | no backend-language variants or VHDL behavior |

AHB and APB are unchanged and outside this AXI generator; that scope statement
belongs in docs/task acceptance rather than pretending to be an AXI report
capability.

## 7. Implementation owner (`.10`)

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.10` owns exactly:

1. add `FSM::IAL2::ProtocolIntent::AxiWDriver` with AW-equivalent defensive
   APIs, normalization, ISF lowering envelope, report cloning, and the exact
   schedule/report above;
2. wire `PPIF.pm` import, dispatch, root accumulator/clause/cardinality/return,
   binding parsers, predicate, missing-object diagnostic, and W-only `.axi`
   rejection;
3. add the exact `ppif/axi_w_driver.ppif` source in section 2;
4. support-account it as `intent.ppif_axi_w_driver` / coverage
   `ial2_ppif_axi_w_driver_pipeline_cli` / expected module `axi_w_driver` /
   semantic root `fsm`;
5. update `t/248`: allow the coverage key and classification, protocol fixture
   count 298 -> 299, supported-smoke and strict-supported counts 339 -> 340;
6. extend `LanguageSurfaceSection.pm` and its `t/297` assertions to state the
   exact bounded W source alongside AW;
7. add `t/1500-ial2-axi-w-driver.t` with the contract and executable regression
   in section 8;
8. extend the mdBook initiator mode with the shipped W example, commands,
   generated artifacts, guarantees, and residue; and
9. synchronize task tree/index, Memory, Knowledge Map, and generated map.

It must preserve `ppif/axi_aw_driver.ppif`, its schema/support identity/report,
and `t/1499` unchanged except for shared PPIF parser coexistence.

## 8. Executable regression contract

`t/1500` mirrors the four-subtest AW owner:

1. **Adapter/generator shape** — assert layer/kind/mode/schema/source/target,
   exact interfaces, launch/accept rules, priority, active wait, six states,
   no compile issues, three exact priority resolutions, generated `.fsm`,
   bindings, `single_beat`, static rules, and all residue ids.
2. **Fail closed** — at minimum: non-AXI root profile, non-AXI4 family member,
   wrong role, missing command/channel block, data width 16, strobe width 2,
   duplicate binding name, duplicate/mixed W object, and `.axi` alias use.
3. **CLI surfaces** — strict check JSON, semantic JSON, schedule JSON, outdir
   `.isf`/`.fsm`/HDL, and `--verify-hdl` with Verilator lint and Yosys
   synthesis.
4. **Generated-HDL cardinality** — two commands:
   - `WREADY = 1` continuously and `cmd_wstrb = 4'b0000`, proving one legal
     acceptance and one done pulse rather than rejecting/duplicating it;
   - `WREADY = 0`, nonzero data/strobes, at least four stalled cycles checking
     `WVALID`, busy, `WDATA`, `WSTRB`, and `WLAST = 1`, followed by a one-cycle
     READY pulse.

The final totals must be `handshakes = 2`, `done_pulses = 2`, and final
`WVALID = w_busy = 0`. A timeout makes the subtest fail.

Focused cross-surface validation is:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiWDriver.pm
prove -Iperl t/1500-ial2-axi-w-driver.t
./bin/fsmgen --quiet --strict --check --json ppif/axi_w_driver.ppif
./bin/fsmgen --verify-hdl ppif/axi_w_driver.ppif
scripts/run_with_ram_guard.sh prove -Iperl \
  t/248-regression-corpus-accounting.t \
  t/297-capability-manifest.t \
  t/1499-ial2-axi-aw-driver.t
mdbook build docs/book
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
scripts/check_docs_relative_paths.sh
git diff --check
scripts/check_doctrines.sh
```

Heavy/broad Perl and `fsmgen` work remains behind the RAM guard as required by
repo doctrine.

## 9. Explicit deferrals

The implementation must not add or imply:

- an AW+W combined writer or any cross-channel dependency scheduler;
- B response handling or full write-transaction completion;
- multi-beat data, dynamic `WLAST`, burst counters, or AWLEN/AWSIZE coupling;
- outstanding/queued/overlapping write commands;
- integration with the capacity/status core;
- the decision-`0020` protocol-neutral transaction interface or role
  composition;
- a `.axi` W-driver alias;
- direct IAL2-to-IAL0/backend lowering;
- IAL2 verification-output generation;
- backend-language variants or VHDL behavior;
- changes to AHB or APB; or
- unrelated AR/R behavior.

## 10. Rollback

Rollback of this selection is documentation-only: remove this note and its
Knowledge Map fact card, restore `.9` to pending/remove `.10`, restore the
task-tree index/book/Memory pointers, regenerate `KNOWLEDGE_MAP.md`, and commit
the reversal. No parser, source, generator, test, runtime, or HDL behavior is
present in this leaf.

## 11. Conclusion

The contract is closed. `.10` may implement one new additive
`(axi-w-driver ...)` source with no remaining spelling, width, scheduling,
diagnostic, report, residue, support, test, or ownership ambiguity.
