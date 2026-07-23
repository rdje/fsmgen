# IAL2 AXI manager initiator — bounded B response acceptor contract selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.13` (behavior-neutral contract
selection).

Date: 2026-07-23

Status: exact public/generator/report/test contract selected. The following
leaf, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.14`, owns implementation.

This selector changes no parser, generator, public source, support-accounting
entry, capability manifest, test, generated artifact, runtime behavior, or HDL
behavior.

## 1. Selected Identity

| Facet | Selected value |
| --- | --- |
| PPIF clause/object | `(axi-b-response-acceptor ...)` / `axi-b-response-acceptor` |
| parser contract `kind` | `axi_b_response_acceptor` |
| generator | `FSM::IAL2::ProtocolIntent::AxiBResponseAcceptor` |
| generated result `kind` | `protocol_intent.axi_b_response_acceptor` |
| report schema | `fsmgen.ial2.protocol_intent.axi_b_response_acceptor.v1` |
| result mode | `acceptor` |
| public source | `ppif/axi_b_response_acceptor.ppif` |
| intent/actor/module | `axi_b_response_acceptor` |
| generated IAL1 | `axi_b_response_acceptor.isf` |
| generated IAL0 | `axi_b_response_acceptor.fsm` |
| HDL entry kind | `generated_acceptor_fsm` |
| support id | `intent.ppif_axi_b_response_acceptor` |
| coverage key | `ial2_ppif_axi_b_response_acceptor_pipeline_cli` |
| focused test | `t/1501-ial2-axi-b-response-acceptor.t` |

“Acceptor” is selected over “driver” because the primitive receives the
subordinate-owned B response and drives only the manager-owned READY side of
the channel. It is a distinct generator rather than a `ValidReadyChannel`
option because the existing generator is monitor-only and drives neither side.

## 2. Exact Public Source

```text
(protocol-platform-intent axi_b_response_acceptor
  (profile axi4)
  (source
    (object axi-b-response-acceptor)
    (anchor (document IHI0022_L_2025-08) (section A2.3) (page 29))
    (anchor (document IHI0022_L_2025-08) (section A2.3.1) (page 30))
    (anchor (document IHI0022_L_2025-08) (section A2.3.2.1) (page 31))
    (anchor (document IHI0022_L_2025-08) (section A3.3) (page 61))
    (anchor (document IHI0022_L_2025-08) (section A3.3.1) (page 61))
    (anchor (document IHI0022_L_2025-08) (section B1.1.3) (page 278)))
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
      (done b_done))))
```

All six anchors are mandatory and use physical/printed Issue L page numbers.
The first five establish transport, dependencies, and response semantics; the
B1.1.3 signal list fixes direction and parameterized widths. `.12` rendered
and visually checked the newly relied page 278, and the earlier audits visually
checked pages 29-31.

### Binding semantics

The established AW/W two-block shape is preserved:

- `(command ...)` contains the one upstream order: arm one response receive;
- `(channel ...)` contains the physical B interface, stable captured response,
  and local activity/completion status.

The exact binding rules are:

- `b_accept_cmd_valid` is a one-shot arm pulse admitted only while the actor is
  idle. There is no arm-ready output or queue; the caller uses `b_busy`.
- `bvalid`, `bid[3:0]`, and `bresp[1:0]` are subordinate-owned inputs.
- `bready` is the only AXI bus signal driven by the manager primitive. It is
  raised after arm without waiting for `bvalid` and remains high until the one
  handshake.
- `response_bid[3:0]` and `response_bresp[1:0]` are registered capture outputs,
  updated on `bvalid && bready` and held until a later response is accepted.
- `b_busy` is high from the arm rule through response acceptance.
- `b_done` is one standard one-cycle ISF completion pulse after the armed
  transaction observes activity cleared. It is logically associated with the
  captured response but is not claimed to coincide with the physical
  handshake edge.

All names are rebindable identifiers, but every binding must be distinct.
`captured-id` and `captured-response` are explicit rather than reusing `id` and
`response`, so no input aliases a registered output.

## 3. Parser Contract

### Root cardinality and mixing

`FSM::Adapter::IAL2::PPIF::_contract_from_root` gains an
`@axi_b_response_acceptors` accumulator and an `axi-b-response-acceptor` clause
arm. Root policy is:

- require an AXI-family root profile at parser dispatch, then pin exact `axi4`
  in the generator;
- require exactly one `(axi-b-response-acceptor ...)` object;
- reject mixing it with Valid-Ready channels/bundles, manager-capacity-status,
  AW/W drivers, or any APB/AHB object;
- include it in every other standalone object's mixing test; and
- include `(axi-b-response-acceptor ...)` in the missing-intent enumeration.

The B acceptor therefore cannot appear beside AW/W in one source. That would
silently create an aggregate without a coordinator or selected HDL entry.

### Object and binding parsing

`_parse_axi_b_response_acceptor` requires exactly these object clauses once:

```text
role clock reset command channel
```

`_parse_axi_b_response_acceptor_command_block` accepts and requires:

```text
arm=scalar
```

`_parse_axi_b_response_acceptor_channel_block` accepts and requires:

```text
valid=scalar
ready=scalar
id=width
response=width
captured-id=width
captured-response=width
busy=scalar
done=scalar
```

The generic binding parser normalizes hyphens to underscores, so the generator
contract is:

```text
kind       = axi_b_response_acceptor
name       = <object name>
role       = subordinate-to-manager
clock      = <identifier>
reset      = <normalized reset>
command    = { arm }
channel    = {
  valid, ready,
  id{name,width}, response{name,width},
  captured_id{name,width}, captured_response{name,width},
  busy, done
}
protocol   = <root profile>
source     = <object + anchors>
intent_name = <root name>
```

Duplicate and unsupported clauses fail in the PPIF parser before generator
normalization.

### `.axi` policy

The implementation is generic `.ppif` only. `_validate_profile_alias_contract`
adds a B-specific rejection before the bundle/manager guard:

```text
(axi-b-response-acceptor ...) remains unsupported for the first profile-alias implementation
```

No `.axi` fixture or alias capability is added.

## 4. Generator Normalization And Diagnostics

`AxiBResponseAcceptor::_normalize_contract` must fail closed with these exact
diagnostic substrings:

| Invalid contract | Required substring |
| --- | --- |
| wrong kind | `AXI B response acceptor IAL2 contract kind must be axi_b_response_acceptor` |
| profile other than exact AXI4 | `AXI B response acceptor IAL2 contract profile must be axi4 in this slice` |
| wrong role | `AXI B response acceptor IAL2 contract role must be subordinate-to-manager` |
| wrong bus ID width | `channel.id.width must be 4 in this slice` |
| wrong captured ID width | `channel.captured_id.width must be 4 in this slice` |
| wrong bus response width | `channel.response.width must be 2 in this slice` |
| wrong captured response width | `channel.captured_response.width must be 2 in this slice` |
| missing scalar/binding | name the exact `command.*` or `channel.*` field |
| invalid identifier | name the exact field and require an ISF identifier |
| duplicate interface/internal name | `AXI B response acceptor IAL2 contract duplicates signal '<name>'` |
| `.axi` source | `(axi-b-response-acceptor ...) remains unsupported for the first profile-alias implementation` |

The duplicate-name set includes clock, reset, every command/channel binding,
and reserved generated names `active_q` and `arm_b_start`. Root parser errors
must identify wrong profile family, multiple objects, mixed objects,
duplicate/unknown clauses, and missing blocks with the new object spelling.

## 5. Exact Generated IAL1 Target

The generated actor is fixed as follows, subject only to authored binding
substitution:

```text
(actor axi_b_response_acceptor
  (clock clk)
  (reset (rst_n async active_low))

  (interface
    (input b_accept_cmd_valid)
    (input bvalid)
    (input bid (width 4))
    (input bresp (width 2))
    (output bready)
    (output response_bid (width 4))
    (output response_bresp (width 2))
    (output b_busy)
    (output b_done))

  (priority accept_b over arm_b)

  (rule arm_b arm_b_start
    (set active_q 1)
    (set b_busy 1)
    (set bready 1))

  (rule accept_b (& active_q bvalid bready)
    (set response_bid bid)
    (set response_bresp bresp)
    (set active_q 0)
    (set b_busy 0)
    (set bready 0))

  (transaction b_receive
    (on b_accept_cmd_valid)
    (drive
      (arm_b_start 1))
    (while active_q
      (wait 1))
    (complete b_done)))
```

The schedule contract is exactly:

- six states;
- `compile_issues = []`;
- one transaction `b_receive`;
- rule blocks `arm_b` with three assignments and `accept_b` with five;
- exactly three priority resolutions:

```text
accept_b : arm_b : active_q
accept_b : arm_b : b_busy
accept_b : arm_b : bready
```

The acceptance rule owns payload capture and clears ready/activity on the same
edge that sees `active_q && BVALID && BREADY`. If `BVALID` remains high, the
next edge has `BREADY = 0`, so the same arm cannot accept twice. Captured
outputs have no assignment outside `accept_b` and therefore remain stable.

Lowering is always:

```text
IAL2 -> axi_b_response_acceptor.isf -> axi_b_response_acceptor.fsm -> HDL
```

## 6. Exact Behavioral Contract

For every accepted one-shot arm:

1. while unarmed, `BREADY = 0` and no physical response is accepted;
2. assert ready/busy without waiting for BVALID;
3. hold ready/busy until one response transfer;
4. accept and capture exactly one `BVALID && BREADY` edge;
5. clear ready/busy on that edge;
6. preserve the captured ID/status until a later accepted response; and
7. emit exactly one one-cycle done pulse after transaction retirement.

The actor supports one active arm and no queue. A command pulse while busy is
not admitted. Same-cycle re-arm, next-response throughput, and back-to-back
accepted transfers are unsupported. If another response is presented after
the first acceptance, the subordinate must hold it while BREADY is low, as AXI
requires.

The B payload's stability while `BVALID && !BREADY` is a subordinate
obligation. This acceptor does not generate the generic monitor assertions in
its first slice.

## 7. Exact Report Contract

Schema:
`fsmgen.ial2.protocol_intent.axi_b_response_acceptor.v1`.

Required top-level content:

- `mode = acceptor`;
- standard `layering` with source IAL2, generated `isf`/`fsm`, and
  `direct_ial2_to_ial0 = false`;
- `source_object { id, intent_name, anchors[] }`;
- `target_protocol { profile = axi4, object = axi-b-response-acceptor,
  role = subordinate-to-manager }`;
- `acceptor { name, actor_name }`;
- cloned `bindings { clock, reset, command, channel }`;
- `bounded_response` exactly:

```text
arming_policy       = explicit_one_response
ready_policy        = assert_after_arm_without_waiting_for_valid
accept_condition    = bvalid && bready
id_width             = 4
response_width       = 2
capture_policy       = on_accept_and_hold_until_next_accept
done_policy          = one_pulse_per_accepted_arm_after_transaction_retirement
back_to_back_supported = false
```

- generated IAL1/IAL0 artifacts and selected HDL entry; and
- exact static rules and residue below.

### Enforced static rules

1. profile must be `axi4` and object must be
   `axi-b-response-acceptor`;
2. role must be `subordinate-to-manager`;
3. one explicit arm owns one response acceptance;
4. BREADY is manager-driven and asserted after arm without waiting for BVALID;
5. B ID width and captured ID width are 4;
6. B response width and captured response width are 2;
7. capture occurs only on `BVALID && BREADY` and is held until the next
   accepted response;
8. busy/ready clear on acceptance and done is one later pulse;
9. all bindings and reserved internal names are distinct; and
10. direct IAL2-to-IAL0 lowering is forbidden.

### Unsupported residue

The report must contain these IDs in this order:

1. `axi_b_response_acceptor_aw_w_coordination_deferred`
2. `axi_b_response_acceptor_capacity_core_integration_deferred`
3. `axi_b_response_acceptor_outstanding_back_to_back_deferred`
4. `axi_b_response_acceptor_id_width_fixed`
5. `axi_b_response_acceptor_response_width_variants_deferred`
6. `axi_b_response_acceptor_extended_response_signals_deferred`
7. `axi_b_response_acceptor_status_interpretation_deferred`
8. `axi_b_response_acceptor_subordinate_stall_assertions_deferred`
9. `axi_b_response_acceptor_burst_coupling_deferred`
10. `axi_b_response_acceptor_ar_r_channels_deferred`
11. `axi_b_response_acceptor_transaction_interface_deferred`
12. `axi_b_response_acceptor_profile_alias_deferred`
13. `axi_b_response_acceptor_verification_output_deferred`
14. `axi_b_response_acceptor_backend_variants_deferred`

The details must state the corresponding `.12` deferrals honestly. In
particular, status interpretation is not covered merely because raw BRESP is
captured, and capacity integration is not covered merely because the stable
captured ID plus done pulse form a compatible future seam.

## 8. Public Accounting And Manifest

Add one `RegressionCorpus` entry beside AW/W:

```text
id                           intent.ppif_axi_b_response_acceptor
relpath                      ppif/axi_b_response_acceptor.ppif
family                       protocol_fixture
classification               supported_smoke
coverage                     ial2_ppif_axi_b_response_acceptor_pipeline_cli
source_kind                  ppif
strict_supported             1
expected_module_name         axi_b_response_acceptor
expected_semantic_source_root_kind fsm
```

Update t/248:

- add the coverage key to the required coverage lists/map;
- protocol fixtures: 299 -> 300;
- supported-smoke: 340 -> 341; and
- strict-supported: 340 -> 341.

Extend the `.ppif` current-boundary prose in
`LanguageSurfaceSection.pm` with “the bounded AXI manager B write-response
acceptor source” and add the exact matching t/297 regex. It must remain adjacent
in meaning to the AW/W primitives and must not claim a complete manager.

## 9. Exact Focused Test

`t/1501-ial2-axi-b-response-acceptor.t` must contain four top-level subtests,
matching t/1500's organization:

1. **adapter/report/generated artifacts** — identity table, six exact anchors,
   bindings, bounded-response fields, ISF/FSM shape, state/priority contract,
   static rules, and ordered residue;
2. **fail-closed contract** — wrong profile/role, all four width mismatches,
   duplicate clauses/bindings, duplicate object, mixed object, and `.axi`
   rejection;
3. **CLI and external HDL validation** — strict check JSON, semantic JSON,
   schedule JSON, outdir `.isf`/`.fsm`/HDL, and `--verify-hdl` Verilator lint +
   Yosys synthesis; and
4. **generated-HDL cardinality/capture** — executable Verilator harness.

The executable harness must include:

- unarmed BVALID produces no handshake;
- scenario 1 holds `BVALID` with `BID = 4'h3`, `BRESP = 2'b10` before arm and
  after acceptance, yet produces only one handshake and one done pulse;
- captured outputs equal `3`/`2` and remain stable while the still-high
  unowned BVALID cannot transfer;
- scenario 2 arms with BVALID low, observes BREADY/busy held for at least four
  cycles, then accepts one cycle of BVALID with `BID = 4'h9`,
  `BRESP = 2'b11`;
- total `handshakes = 2`, `done_pulses = 2`;
- final capture is `9`/`3`; and
- final BREADY/busy are low.

The test must count handshakes at rising edges and must not equate the later
done pulse cycle with the physical capture edge.

## 10. Implementation Touch Points

`.14` owns one atomic additive slice:

- new `perl/FSM/IAL2/ProtocolIntent/AxiBResponseAcceptor.pm`;
- PPIF import/dispatch/alias guard/root accumulator+clause+cardinality+mixing+
  return/object parser/binding parsers/predicate;
- new `ppif/axi_b_response_acceptor.ppif`;
- `RegressionCorpus.pm` plus t/248 accounting;
- `LanguageSurfaceSection.pm` plus t/297 assertion;
- new `t/1501-ial2-axi-b-response-acceptor.t`;
- AXI mdBook shipped source/commands/semantics/test section;
- task-tree/index/Memory/Knowledge Map/fact card; and
- no unrelated generator or protocol changes.

## 11. Validation And Rollback

Implementation validation must include:

- Perl syntax for the new generator, PPIF adapter, support/manifest modules,
  and t/1501;
- focused t/1501, including `--verify-hdl` and executable generated HDL;
- guarded t/248 + t/297 + t/1499 + t/1500;
- strict check of the new public source;
- mdBook, Knowledge Map, Memory, docs-path, whitespace, and doctrine gates.

Rollback of `.14` removes the additive module/source/test/support/manifest/
book/fact wiring and restores counts. AW/W and the capacity/status core must
remain byte-for-byte unaffected.

This `.13` selector itself rolls back by removing this contract/fact,
restoring `.13` active, removing `.14`, and restoring task-index/book/Memory
pointers; no behavior rollback is required.

## 12. Preserved Deferrals

No part of this contract activates AW/W/B composition, a complete write
transactor, capacity/status integration, outstanding/back-to-back responses,
configurable/extended B widths and sidebands, response interpretation,
multi-beat/burst coupling, AR/R, decision `0020`'s protocol-neutral transaction
interface, `.axi` aliases, verification-output generation, direct backend
lowering, backend-language variants/VHDL, or AHB/APB behavior.
