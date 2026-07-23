# IAL2 AXI manager initiator — AW+W request composition contract selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.17` (behavior-neutral contract
selection).

Date: 2026-07-23

Status: exact public/generator/report/test contract selected. The following
leaf, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.18`, owns implementation.

This selector changes no parser, generator, public source, support-accounting
entry, capability manifest, test, generated artifact, runtime behavior, or HDL
behavior.

## 1. Selected identity

| Facet | Selected value |
| --- | --- |
| PPIF clause/object | `(axi-write-request-composition ...)` / `axi-write-request-composition` |
| parser contract `kind` | `axi_write_request_composition` |
| generator | `FSM::IAL2::ProtocolIntent::AxiWriteRequestComposition` |
| generated result `kind` | `protocol_intent.axi_write_request_composition` |
| report schema | `fsmgen.ial2.protocol_intent.axi_write_request_composition.v1` |
| result mode | `write-request-composition` |
| public source | `ppif/axi_write_request_composition.ppif` |
| public intent/top | `axi_write_request_composition` |
| generated coordinator | `axi_write_request_coordinator` |
| generated IAL1 | `axi_aw_driver.isf`, `axi_w_driver.isf`, `axi_write_request_coordinator.isf` |
| generated child IAL0 | `axi_aw_driver.fsm`, `axi_w_driver.fsm`, `axi_write_request_coordinator.fsm` |
| structural IAL0/HDL entry | `axi_write_request_composition.fsm` / module `axi_write_request_composition` |
| HDL entry kind | `generated_composition_top` |
| composition lane | `C4` |
| support id | `intent.ppif_axi_write_request_composition` |
| coverage key | `ial2_ppif_axi_write_request_composition_pipeline_cli` |
| focused test | `t/1502-ial2-axi-write-request-composition.t` |

“Write request” is intentional: the composition retires after both AW and W
request transfers. It does not arm BREADY, capture BRESP/BID, or claim full
write-transaction completion. “Composition” is intentional because the
generator reuses the two shipped drivers and adds a third generated coordinator
under a structural top; it is not a monolithic new channel actor.

## 2. Exact public source

```text
(protocol-platform-intent axi_write_request_composition
  (profile axi4)
  (source
    (object axi-write-request-composition)
    (anchor (document IHI0022_L_2025-08) (section A3.2.1) (page A3-40))
    (anchor (document IHI0022_L_2025-08) (section A2.3) (page 29))
    (anchor (document IHI0022_L_2025-08) (section A2.3.1) (page 30))
    (anchor (document IHI0022_L_2025-08) (section A2.3.2.1) (page 31))
    (anchor (document IHI0022_L_2025-08) (section A3.2.1) (page 53))
    (anchor (document IHI0022_L_2025-08) (section A3.2.1.1) (page 54)))
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
      (done write_done))))
```

All six anchors are mandatory in that order. They are the union of the shipped
AW and W source evidence already audited and visually checked. The aggregate
source has one object only; it does not embed authored `(axi-aw-driver ...)` or
`(axi-w-driver ...)` objects.

### Binding semantics

`command` is the upstream aggregate request:

- `write_cmd_valid` is level-sampled for admission while idle. A one-cycle
  pulse while busy is ignored; no command-ready output or queue exists. If the
  signal remains asserted into a later idle cycle, it can be admitted then.
- `cmd_awaddr[31:0]`, `cmd_awid[3:0]`, `cmd_wdata[31:0]`, and
  `cmd_wstrb[3:0]` are captured atomically on the admitted edge.
- an idle admission attempt is legal only when `cmd_awaddr[1:0] == 2'b00`.

`aw-channel` and `w-channel` are the physical bus boundary. READY is input;
every other field in those blocks is output. `status` contains only aggregate
outputs. Child start, captured payload, busy, and done nets remain internal.

All public binding names are rebindable valid identifiers, matching the
standalone AW/W contracts. Widths, clause roles, fixed metadata, generated
child module/artifact names, coordinator name, and default public sample names
are not reconfigurable in this slice. Every public binding must be distinct
from every other public binding and every reserved generated internal name.

## 3. Fixed single-beat policy

The aggregate has no dynamic length/size/burst clauses. The structural top
wires exact-width literals to the AW child:

```text
aw_driver.cmd_awlen   <- 8'd0
aw_driver.cmd_awsize  <- 3'd2
aw_driver.cmd_awburst <- 2'b01
```

The exact report values are:

```text
address_width             = 32
address_alignment_bytes   = 4
id_width                  = 4
data_width                = 32
strobe_width              = 4
all_zero_strobe_allowed   = true
awlen                     = 0
awsize                    = 2
awburst                   = 1
awburst_name              = INCR
wlast                     = 1
beat_count                = 1
request_completion        = both_aw_and_w_accepted
```

AWLEN=0 announces one beat; AWSIZE=2 announces four bytes; W emits exactly one
final 32-bit beat. WSTRB remains arbitrary, including zero. Four-byte alignment
keeps every byte lane inside the selected full-width beat. Dynamic metadata,
narrow/unaligned placement, address stepping, and multiple beats are rejected
or absent rather than inferred.

## 4. Parser contract

### Root cardinality and mixing

`FSM::Adapter::IAL2::PPIF::_contract_from_root` gains an
`@axi_write_request_compositions` accumulator and an
`axi-write-request-composition` clause arm. Root policy is:

- require an AXI-family root, then pin exact `axi4` in the generator;
- require exactly one aggregate object;
- reject mixing with Valid-Ready channels/bundles, capacity/status, standalone
  AW/W/B, APB, or AHB objects;
- include the aggregate in every sibling standalone mixing test; and
- include `(axi-write-request-composition ...)` in the missing-intent
  enumeration.

The parser must not infer this composition merely because standalone AW and W
objects coexist; such coexistence remains a mixed-object error.

### Exact object blocks

`_parse_axi_write_request_composition` requires exactly once:

```text
role clock reset command aw-channel w-channel status
```

The block parsers require:

```text
command:
  start=scalar address=width id=width data=width strobe=width

aw-channel:
  ready=scalar valid=scalar address=width id=width
  length=width size=width burst=width

w-channel:
  ready=scalar valid=scalar data=width strobe=width last=scalar

status:
  busy=scalar done=scalar
```

Hyphenated block names normalize to `aw_channel` and `w_channel`. The generator
contract is:

```text
kind         = axi_write_request_composition
name         = <object name>
actor_name   = <object name> unless explicitly supplied internally
role         = manager-to-subordinate
clock        = <identifier>
reset        = <normalized asynchronous active-low reset>
command      = { start, address{name,width}, id{name,width},
                 data{name,width}, strobe{name,width} }
aw_channel   = { ready, valid, address{name,width}, id{name,width},
                 length{name,width}, size{name,width}, burst{name,width} }
w_channel    = { ready, valid, data{name,width}, strobe{name,width}, last }
status       = { busy, done }
protocol     = axi4
source       = <object + six anchors>
intent_name  = <root name>
```

Duplicate/unknown clauses, missing blocks, malformed width forms, and nested
child objects fail in the parser before generation.

### `.axi` policy

The generic `.ppif` source is the only public surface. Alias validation adds:

```text
(axi-write-request-composition ...) remains unsupported for the first profile-alias implementation
```

No `.axi` fixture, support entry, or capability claim is added.

## 5. Generator normalization and diagnostics

`AxiWriteRequestComposition::_normalize_contract` must fail closed with these
diagnostic substrings:

| Invalid contract | Required substring |
| --- | --- |
| wrong kind | `AXI write request composition IAL2 contract kind must be axi_write_request_composition` |
| profile other than exact AXI4 | `AXI write request composition IAL2 contract profile must be axi4 in this slice` |
| wrong role | `AXI write request composition IAL2 contract role must be manager-to-subordinate` |
| reset mode/polarity | `AXI write request composition reset must be asynchronous active-low in this slice` |
| command address width | `command.address.width must be 32 in this slice` |
| command ID width | `command.id.width must be 4 in this slice` |
| command data width | `command.data.width must be 32 in this slice` |
| command strobe width | `command.strobe.width must be 4 in this slice` |
| AW address width | `aw_channel.address.width must be 32 in this slice` |
| AW ID width | `aw_channel.id.width must be 4 in this slice` |
| AW length width | `aw_channel.length.width must be 8 in this slice` |
| AW size width | `aw_channel.size.width must be 3 in this slice` |
| AW burst width | `aw_channel.burst.width must be 2 in this slice` |
| W data width | `w_channel.data.width must be 32 in this slice` |
| W strobe width | `w_channel.strobe.width must be 4 in this slice` |
| missing binding | identify the exact `command.*`, `aw_channel.*`, `w_channel.*`, or `status.*` field |
| invalid identifier | identify the exact field and require an ISF identifier |
| duplicate interface/internal name | `AXI write request composition IAL2 contract duplicates signal '<name>'` |
| `.axi` source | `(axi-write-request-composition ...) remains unsupported for the first profile-alias implementation` |

The duplicate-name set includes clock/reset, all public bindings, coordinator
ports, child status/start nets, and reserved locals `active_q`, `aw_seen_q`, and
`w_seen_q`. Fixed child object/module names, instance names, artifacts, and the
structural top name must also be collision-checked before artifact assembly.

Dynamic metadata or nested child clauses fail as unsupported syntax. Runtime
misalignment is different: it is data-dependent, so the generated guard drops
the admission and the generated assertion reports the caller error.

## 6. Exact generated coordinator IAL1

The default coordinator is fixed as follows; public binding substitution is
allowed only at the aggregate boundary and is mapped onto these internal pins:

```text
(actor axi_write_request_coordinator
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input write_cmd_valid)
    (input cmd_awaddr (width 32))
    (input cmd_awid (width 4))
    (input cmd_wdata (width 32))
    (input cmd_wstrb (width 4))
    (input aw_done)
    (input w_done)
    (output aw_cmd_valid)
    (output aw_cmd_awaddr (width 32))
    (output aw_cmd_awid (width 4))
    (output w_cmd_valid)
    (output w_cmd_wdata (width 32))
    (output w_cmd_wstrb (width 4))
    (output write_busy)
    (output write_done))

  (priority finish_join over latch_aw)
  (priority finish_join over latch_w)
  (priority finish_join over launch_join)
  (priority finish_join over clear_done)
  (priority launch_join over latch_aw)
  (priority launch_join over latch_w)
  (priority launch_join over clear_child_starts)

  (rule launch_join
    (& (! active_q) write_cmd_valid (! cmd_awaddr[0]) (! cmd_awaddr[1]))
    (set active_q 1)
    (set aw_seen_q 0)
    (set w_seen_q 0)
    (set aw_cmd_valid 1)
    (set aw_cmd_awaddr cmd_awaddr)
    (set aw_cmd_awid cmd_awid)
    (set w_cmd_valid 1)
    (set w_cmd_wdata cmd_wdata)
    (set w_cmd_wstrb cmd_wstrb)
    (set write_busy 1))

  (rule clear_child_starts (| aw_cmd_valid w_cmd_valid)
    (set aw_cmd_valid 0)
    (set w_cmd_valid 0))

  (rule latch_aw (& active_q aw_done)
    (set aw_seen_q 1))

  (rule latch_w (& active_q w_done)
    (set w_seen_q 1))

  (rule finish_join (& active_q (| aw_seen_q aw_done) (| w_seen_q w_done))
    (set active_q 0)
    (set aw_seen_q 0)
    (set w_seen_q 0)
    (set write_busy 0)
    (set write_done 1))

  (rule clear_done write_done
    (set write_done 0))

  (transaction aligned_command_check
    (assert
      (=> (& (! active_q) write_cmd_valid)
          (& (! cmd_awaddr[0]) (! cmd_awaddr[1])))
      "single-beat AXI write address must be four-byte aligned")))
```

The coordinator schedule contract is:

- `state_count = 0`, `transactions = []`, and `compile_issues = []`;
- six rule DT blocks with assignment counts `10, 2, 1, 1, 5, 1` in the order
  shown;
- five realized priority resolutions:

```text
launch_join : clear_child_starts : aw_cmd_valid
finish_join : latch_aw           : aw_seen_q
launch_join : clear_child_starts : w_cmd_valid
finish_join : latch_w            : w_seen_q
finish_join : clear_done         : write_done
```

- two compatible same-value fan-in groups for zeroing `aw_seen_q` and
  `w_seen_q` from launch/finish.

The extra declared priorities preserve the intended dominance if later
factoring changes guard proof; only the five overlapping writes appear in the
current resolution report. Indexed address bits are mandatory. The modulo
equals-zero form is not selected because the readiness probe exposed the
current multi-bit equality-to-zero width-warning path.

## 7. Child generation and structural top

The generator invokes the existing `AxiAwDriver` and `AxiWDriver` generators
unchanged. It synthesizes their internal contracts with fixed actor/module
names and these command pins:

```text
AW child:
  aw_cmd_valid, aw_cmd_awaddr[31:0], aw_cmd_awid[3:0],
  cmd_awlen[7:0], cmd_awsize[2:0], cmd_awburst[1:0], awready

W child:
  w_cmd_valid, w_cmd_wdata[31:0], w_cmd_wstrb[3:0], wready
```

The structural top has exactly three children in this order:

| Role | Instance | Module/artifact |
| --- | --- | --- |
| AW driver | `aw_driver` | `axi_aw_driver` / `axi_aw_driver.fsm` |
| W driver | `w_driver` | `axi_w_driver` / `axi_w_driver.fsm` |
| coordinator | `coordinator` | `axi_write_request_coordinator` / `axi_write_request_coordinator.fsm` |

All share `clk` and `rst_n`. Exact connection families are:

1. public command inputs to the coordinator inputs;
2. AW/W child done outputs to coordinator `aw_done`/`w_done`;
3. coordinator child-start and captured-payload outputs to the corresponding
   child command inputs;
4. `8'd0`, `3'd2`, and `2'b01` direct actuals to AW length/size/burst;
5. public READY inputs to the respective children;
6. child AW/W bus outputs to public top outputs; and
7. coordinator busy/done to public aggregate status outputs.

Child `aw_busy`, `w_busy`, `aw_done`, `w_done`, starts, and captured payload
are internal nets. No B net exists. The top uses explicit `?wiring` and is the
only selected HDL entry. Its IAL0 item has:

```text
kind            = generated_composition_top
format          = fsm
entry_artifact  = axi_write_request_composition.fsm
child_artifacts = [axi_aw_driver.fsm,
                   axi_w_driver.fsm,
                   axi_write_request_coordinator.fsm]
selected        = true
```

The top file includes the three generated child definitions following the APB
composition pattern. Direct IAL2-to-IAL0 generation and a monolithic AW/W actor
are forbidden.

## 8. Exact result, report, CLI, and semantic contract

The returned result contains:

```text
layer = IAL2
kind  = protocol_intent.axi_write_request_composition
mode  = write-request-composition

generated_ial1.format = isf
generated_ial1.items  = [AW, W, coordinator]

generated_ial0.format = fsm
generated_ial0.items  = [AW, W, coordinator, structural top]
generated_ial0.files  = four artifact-name -> text entries

generated_ial1_schedule_reports = [AW, W, coordinator]
```

Every IAL1 item and schedule entry has `object_name`, `role`, artifact name,
format/report, and deterministic order. Roles are `aw-driver`, `w-driver`, and
`coordinator`.

The report schema is
`fsmgen.ial2.protocol_intent.axi_write_request_composition.v1` and contains:

- `mode = write-request-composition`;
- standard `layering` with `direct_ial2_to_ial0 = false`;
- `source_object { id, intent_name, anchors[] }`;
- `target_protocol { profile = axi4,
  object = axi-write-request-composition,
  role = manager-to-subordinate }`;
- `composition` with `name`, `topology = parallel_aw_w_request_join`,
  `child_instance_count = 3`, exact child/instance identities, explicit wiring
  policy, shared reset/clock, and top-port metadata;
- `bindings { clock, reset, command, aw_channel, w_channel, status }`;
- `single_beat_policy` containing every exact value from section 3;
- `coordinator`:

```text
actor_name              = axi_write_request_coordinator
admission_policy        = idle_level_sampled
queue_depth             = 0
payload_capture         = atomic_on_admission
alignment_guard         = cmd_awaddr[1:0] == 2'b00
alignment_assertion     = idle_admission_attempt_implies_four_byte_aligned
child_start_policy      = one_registered_pulse_each
completion_history      = remember_aw_done_and_w_done_independently
completion_policy       = one_pulse_after_both_request_channels_accept
response_completion     = false
```

- `children[]` summaries for AW, W, and coordinator, including their generated
  artifact boundaries;
- `generated_schedules { count = 3, items = [full AW, W, coordinator schedule
  reports] }` so aggregate `--emit-schedule-json` preserves all three;
- `generated_artifacts` listing three IAL1 items, four IAL0 files/items, and
  the selected structural top; and
- exact `enforced_static_rules` and `unsupported_residue` below.

`--emit-schedule-json` returns this aggregate report, including the three full
schedule reports. `--emit-semantic-json` selects the structural top as root
kind `top`, reports lane `C4`, instance count three, child modules in the order
above, and preserves the public `.ppif` source identity. `--outdir` writes the
three `.isf` review artifacts and all four `.fsm` files. Generated HDL contains
the top and all three child modules. Strict failure emits no partial artifacts.

### Enforced static rules

1. profile is exact `axi4`, object is
   `axi-write-request-composition`, and role is
   `manager-to-subordinate`;
2. reset is shared asynchronous active-low and clock is shared;
3. one idle admission atomically captures address32/ID4/data32/strobe4;
4. admitted addresses are four-byte aligned, enforced by guard and assertion;
5. AW metadata is fixed to LEN 0, SIZE 2, BURST INCR;
6. W is one final 32-bit beat and every WSTRB value, including zero, is legal;
7. unchanged AW/W children each receive one registered start pulse;
8. aggregate busy remains high until both independent done events are seen;
9. aggregate done means both request channels accepted and never B response
   completion;
10. all public/generated names and artifacts are distinct; and
11. lowering is IAL2 -> three generated IAL1 children -> three generated IAL0
    children -> structural IAL0 top, never direct IAL2 -> IAL0.

### Unsupported residue

The report preserves these ids in order:

1. `axi_write_request_composition_b_response_completion_deferred`
2. `axi_write_request_composition_capacity_core_integration_deferred`
3. `axi_write_request_composition_multi_beat_w_deferred`
4. `axi_write_request_composition_dynamic_aw_metadata_deferred`
5. `axi_write_request_composition_narrow_unaligned_transfers_deferred`
6. `axi_write_request_composition_outstanding_queueing_deferred`
7. `axi_write_request_composition_back_to_back_admission_deferred`
8. `axi_write_request_composition_id_width_fixed`
9. `axi_write_request_composition_extended_axi_attributes_deferred`
10. `axi_write_request_composition_ar_r_channels_deferred`
11. `axi_write_request_composition_transaction_interface_deferred`
12. `axi_write_request_composition_profile_alias_deferred`
13. `axi_write_request_composition_verification_output_deferred`
14. `axi_write_request_composition_backend_variants_deferred`

The corresponding details must distinguish bus request completion from full
write completion, state that queue depth is zero, and keep decision `0020`'s
protocol-neutral transaction interface director-gated.

## 9. Public accounting and manifest

Add one `RegressionCorpus` entry beside the standalone AXI primitives:

```text
id                             intent.ppif_axi_write_request_composition
relpath                        ppif/axi_write_request_composition.ppif
family                         protocol_fixture
classification                 supported_smoke
coverage                       ial2_ppif_axi_write_request_composition_pipeline_cli
source_kind                    ppif
strict_supported               1
expected_module_name           axi_write_request_composition
expected_top_name              axi_write_request_composition
expected_lane                  C4
expected_instance_count        3
expected_child_modules         [axi_aw_driver, axi_w_driver,
                                axi_write_request_coordinator]
expected_semantic_source_root_kind top
```

Update `t/248`:

- add the coverage key to required coverage maps/lists;
- protocol fixtures: 300 -> 301;
- supported-smoke entries: 341 -> 342; and
- strict-supported entries: 341 -> 342.

Extend `.ppif` current-boundary prose in `LanguageSurfaceSection.pm` with “the
bounded AXI manager single-beat AW+W write-request composition source” and add
the exact `t/297` assertion. The prose must say request completion and must not
claim B response or full transaction completion.

## 10. Exact focused test

`t/1502-ial2-axi-write-request-composition.t` has four top-level subtests:

1. **adapter/report/generated composition** — exact public source/anchors,
   identity, bindings, fixed policy, coordinator, children, three schedules,
   ordered artifacts, structural top, eleven static rules, and fourteen
   residue ids;
2. **fail-closed contract** — wrong root/profile/role/reset, every width
   mismatch, duplicate/unknown/missing clauses, dynamic metadata, nested/mixed
   children, duplicate names/artifacts, multiple aggregate objects, and `.axi`
   rejection;
3. **CLI and external HDL** — strict check JSON, aggregate schedule JSON,
   semantic top/C4/three-child JSON, outdir three ISF/four FSM artifacts,
   `--verify-hdl` Verilator lint + Yosys synthesis; and
4. **generated structural-top behavior** — executable Verilator proof through
   the real top plus all three generated children.

The HDL harness must prove:

- a misaligned idle pulse launches neither AW nor W with assertions disabled;
- the emitted assertion has the exact aligned-idle-admission implication;
- command 1 changes all aggregate payload immediately after admission, yet the
  children use the captured original values; with AWREADY/WREADY already high
  and zero WSTRB, it produces one transfer per child and one aggregate done;
- command 2 accepts AW first, holds W stalled for at least four cycles with
  stable WVALID/WDATA/WSTRB/WLAST, ignores one command pulse while busy, then
  accepts W and completes once;
- command 3 accepts W first, holds AW stalled for at least four cycles with
  stable AWVALID/address/ID/LEN/SIZE/BURST, then accepts AW and completes once;
- fixed AW outputs are always LEN=0, SIZE=2, BURST=1 and WLAST is always one
  while valid;
- held READY never causes a second transfer; and
- totals are `aw_handshakes = 3`, `w_handshakes = 3`,
  `done_pulses = 3`, followed by final AWVALID/WVALID/busy/done low.

The test must count physical handshakes independently from child done and
aggregate done timing. A timeout fails the test.

## 11. Implementation owner (`.18`)

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.18` owns exactly:

1. add `FSM::IAL2::ProtocolIntent::AxiWriteRequestComposition` with defensive
   normalization, unchanged AW/W child generation, coordinator scheduling,
   structural top assembly, result/report cloning, and exact contract above;
2. wire `PPIF.pm` import, dispatch, accumulator/clause/cardinality/mixing,
   block parsers, predicate, missing-object text, and composition-only `.axi`
   rejection;
3. add the exact public source from section 2;
4. add the support entry/counts/coverage in section 9;
5. update `LanguageSurfaceSection.pm` and `t/297` without weakening standalone
   object boundaries;
6. add the four-subtest `t/1502` owner in section 10;
7. update the AXI mdBook from selected-not-generated to shipped, with runnable
   source/CLI/artifact/behavior/residue documentation; and
8. synchronize task tree/index, Memory, fact card, Knowledge Map, validation,
   and commit.

The implementation must preserve `AxiAwDriver.pm`, `AxiWDriver.pm`, their
public sources, schemas, reports, and executable tests except for exercising
them through the new shared PPIF dispatch/composition owner.

Focused validation is:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiWriteRequestComposition.pm
prove -Iperl t/1502-ial2-axi-write-request-composition.t
./bin/fsmgen --quiet --strict --check --json \
  ppif/axi_write_request_composition.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/axi_write_request_composition.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json \
  ppif/axi_write_request_composition.ppif
./bin/fsmgen --quiet --verify-hdl \
  ppif/axi_write_request_composition.ppif
scripts/run_with_ram_guard.sh -- prove -Iperl \
  t/248-regression-corpus-accounting.t \
  t/297-capability-manifest.t \
  t/1499-ial2-axi-aw-driver.t \
  t/1500-ial2-axi-w-driver.t
mdbook build docs/book
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
scripts/check_docs_relative_paths.sh
git diff --check
scripts/check_doctrines.sh
```

Broad/heavy runs remain subject to the documented RAM-guard policy and macOS
false-high fallback.

## 12. Explicit deferrals and rollback

The implementation does not add B acceptance, BRESP/BID handling, full write
completion, capacity/status integration, command queues, multiple outstanding
writes, back-to-back throughput, dynamic AW metadata, multi-beat W, narrow or
unaligned transfer placement, extended AXI attributes, AR/R, decision `0020`'s
transaction interface, `.axi` aliases, verification-output generation, direct
backend lowering, backend-language variants, VHDL, AHB, or APB behavior.

Rollback of this selector is documentation-only: remove this note and its fact
card, restore `.17` active/remove `.18`, restore the prior task-index/book/Memory
pointers, regenerate `KNOWLEDGE_MAP.md`, and commit. No parser, generator,
source, test, runtime, or HDL rollback is required.

The contract is closed. `.18` may implement the additive composition with no
remaining syntax, width, metadata, alignment, coordinator, child-wiring,
artifact, schema, diagnostic, residue, support, test, or ownership ambiguity.
