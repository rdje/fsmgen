# IAL2 AXI manager initiator - bounded R beat acceptor contract selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.29` (behavior-neutral contract
selection).

Date: 2026-07-23

Status: exact public/generator/report/test contract selected. The following
leaf, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.30`, owns implementation.

This selector changes no parser, generator, public source, support-accounting
entry, capability manifest, test, generated artifact, runtime behavior, or HDL
behavior.

## 1. Selected Identity

| Facet | Selected value |
| --- | --- |
| PPIF clause/object | `(axi-r-beat-acceptor ...)` / `axi-r-beat-acceptor` |
| parser contract `kind` | `axi_r_beat_acceptor` |
| current reference generator | `FSM::IAL2::ProtocolIntent::AxiRBeatAcceptor` |
| generated result `kind` | `protocol_intent.axi_r_beat_acceptor` |
| report schema | `fsmgen.ial2.protocol_intent.axi_r_beat_acceptor.v1` |
| result mode | `acceptor` |
| public source | `ppif/axi_r_beat_acceptor.ppif` |
| intent/actor/module | `axi_r_beat_acceptor` |
| generated IAL1 | `axi_r_beat_acceptor.isf` |
| generated IAL0 | `axi_r_beat_acceptor.fsm` |
| HDL entry kind | `generated_acceptor_fsm` |
| support id | `intent.ppif_axi_r_beat_acceptor` |
| coverage key | `ial2_ppif_axi_r_beat_acceptor_pipeline_cli` |
| focused test | `t/1505-ial2-axi-r-beat-acceptor.t` |

“Beat acceptor” is selected over “response acceptor” because one R transfer is
not necessarily the complete read response. The name makes the semantic unit
explicit and prevents the B-channel one-response completion model from leaking
into a potentially multi-beat R transaction.

This is a distinct generator rather than a mode on `AxiBResponseAcceptor` or
`ValidReadyChannel`: the public payload vocabulary and report scope are
R-specific, and the generic channel generator remains a monitor that does not
drive READY or own captured storage.

## 2. Exact Public Source

```text
(protocol-platform-intent axi_r_beat_acceptor
  (profile axi4)
  (source
    (object axi-r-beat-acceptor)
    (anchor (document IHI0022_L_2025-08) (section A2.3) (page 29))
    (anchor (document IHI0022_L_2025-08) (section A2.3.1) (page 30))
    (anchor (document IHI0022_L_2025-08) (section A2.3.2.2) (page 32))
    (anchor (document IHI0022_L_2025-08) (section A2.6) (page 41))
    (anchor (document IHI0022_L_2025-08) (section A3.2.2) (page 55))
    (anchor (document IHI0022_L_2025-08) (section A3.3.2) (page 62))
    (anchor (document IHI0022_L_2025-08) (section A5.1.1) (page 90))
    (anchor (document IHI0022_L_2025-08) (section B1.2.2) (page 281)))
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
      (done r_beat_done))))
```

All eight anchors are mandatory and use physical/printed Issue L page numbers.
The `.28` audit rendered and visually verified them. They establish handshake,
read dependency/capacity, data/last/response/ID semantics, and complete signal
direction/width ownership.

### Binding semantics

- `r_accept_cmd_valid` is a one-shot arm pulse admitted only while idle. There
  is no arm-ready output or queue; callers observe `r_busy`.
- `rvalid`, `rid[3:0]`, `rdata[31:0]`, `rresp[1:0]`, and `rlast` are
  subordinate-owned inputs.
- `rready` is the only AXI bus signal driven by the manager primitive. It rises
  after arm without waiting for RVALID and remains high until one handshake.
- `response_rid[3:0]`, `response_rdata[31:0]`,
  `response_rresp[1:0]`, and `response_rlast` are registered outputs updated
  together on `rvalid && rready` and held until a later accepted beat.
- `r_busy` is high from arm launch through beat acceptance.
- `r_beat_done` is one standard one-cycle ISF completion pulse after the armed
  receive transaction observes activity cleared.

The done pulse is logically associated with the captured beat but is later
than the physical acceptance edge. `response_rlast = 1` is not required, and
no response/status/ID/length validation occurs inside this primitive.

All authored names are rebindable identifiers, but every external binding and
reserved internal name must be distinct.

## 3. Parser Contract

### Root cardinality and mixing

`FSM::Adapter::IAL2::PPIF::_contract_from_root` gains an
`@axi_r_beat_acceptors` accumulator and an `axi-r-beat-acceptor` clause arm.
Root policy is:

- require an AXI-family root profile at parser dispatch, then pin exact `axi4`
  in the generator;
- require exactly one `(axi-r-beat-acceptor ...)` object;
- reject mixing it with Valid-Ready channels/bundles, manager-capacity-status,
  AW/AR/W/B primitives, write compositions, or APB/AHB objects;
- include it in every other standalone object's mixing predicate; and
- include `(axi-r-beat-acceptor ...)` in the missing-intent enumeration.

AR and R remain separate sources in this slice. Allowing them side by side
would create an aggregate without selected coordination, one HDL entry, or an
honest transaction-completion contract.

### Object and binding parsing

`_parse_axi_r_beat_acceptor` requires exactly these object clauses once:

```text
role clock reset command channel
```

`_parse_axi_r_beat_acceptor_command_block` accepts and requires:

```text
arm=scalar
```

`_parse_axi_r_beat_acceptor_channel_block` accepts and requires:

```text
valid=scalar
ready=scalar
id=width
data=width
response=width
last=scalar
captured-id=width
captured-data=width
captured-response=width
captured-last=scalar
busy=scalar
done=scalar
```

The normalized contract is:

```text
kind       = axi_r_beat_acceptor
name       = <object name>
role       = subordinate-to-manager
clock      = <identifier>
reset      = <normalized reset>
command    = { arm }
channel    = {
  valid, ready,
  id{name,width}, data{name,width}, response{name,width}, last,
  captured_id{name,width}, captured_data{name,width},
  captured_response{name,width}, captured_last,
  busy, done
}
protocol   = <root profile>
source     = <object + anchors>
intent_name = <root name>
```

Duplicate and unsupported clauses fail in the PPIF parser before generator
normalization.

### `.axi` policy

The implementation is generic `.ppif` only.
`_validate_profile_alias_contract` adds this exact rejection before generic
bundle/manager guards:

```text
(axi-r-beat-acceptor ...) remains unsupported for the first profile-alias implementation
```

No `.axi` fixture or alias capability is added.

## 4. Generator Normalization And Diagnostics

`AxiRBeatAcceptor::_normalize_contract` must fail closed with these diagnostic
substrings:

| Invalid contract | Required substring |
| --- | --- |
| wrong kind | `AXI R beat acceptor IAL2 contract kind must be axi_r_beat_acceptor` |
| profile other than exact AXI4 | `AXI R beat acceptor IAL2 contract profile must be axi4 in this slice` |
| wrong role | `AXI R beat acceptor IAL2 contract role must be subordinate-to-manager` |
| wrong bus ID width | `channel.id.width must be 4 in this slice` |
| wrong captured ID width | `channel.captured_id.width must be 4 in this slice` |
| wrong bus data width | `channel.data.width must be 32 in this slice` |
| wrong captured data width | `channel.captured_data.width must be 32 in this slice` |
| wrong bus response width | `channel.response.width must be 2 in this slice` |
| wrong captured response width | `channel.captured_response.width must be 2 in this slice` |
| missing scalar/binding | name the exact `command.*` or `channel.*` field |
| invalid identifier | name the exact field and require an ISF identifier |
| duplicate interface/internal name | `AXI R beat acceptor IAL2 contract duplicates signal '<name>'` |
| `.axi` source | `(axi-r-beat-acceptor ...) remains unsupported for the first profile-alias implementation` |

The duplicate-name set includes clock, reset, every command/channel binding,
and reserved generated names `active_q` and `arm_r_start`. The parser must
diagnose wrong profile family, duplicate object, mixed objects,
duplicate/unknown clauses, malformed reset, and missing blocks using the new
object spelling.

## 5. Exact Generated IAL1 Target

Subject only to authored binding substitution, the generator emits:

```text
(actor axi_r_beat_acceptor
  (clock clk)
  (reset (rst_n async active_low))

  (interface
    (input r_accept_cmd_valid)
    (input rvalid)
    (input rid (width 4))
    (input rdata (width 32))
    (input rresp (width 2))
    (input rlast)
    (output rready)
    (output response_rid (width 4))
    (output response_rdata (width 32))
    (output response_rresp (width 2))
    (output response_rlast)
    (output r_busy)
    (output r_beat_done))

  (priority accept_r over arm_r)

  (rule arm_r arm_r_start
    (set active_q 1)
    (set r_busy 1)
    (set rready 1))

  (rule accept_r (& active_q rvalid rready)
    (set response_rid rid)
    (set response_rdata rdata)
    (set response_rresp rresp)
    (set response_rlast rlast)
    (set active_q 0)
    (set r_busy 0)
    (set rready 0))

  (transaction r_receive
    (on r_accept_cmd_valid)
    (drive
      (arm_r_start 1))
    (while active_q
      (wait 1))
    (complete r_beat_done)))
```

The exact schedule contract is:

- 13 interface ports: six inputs and seven outputs;
- six states;
- `compile_issues = []`;
- one transaction `r_receive`;
- `arm_r` with three assignments and `accept_r` with seven; and
- exactly three priority resolutions:

```text
accept_r : arm_r : active_q
accept_r : arm_r : r_busy
accept_r : arm_r : rready
```

All four captured outputs are assigned only by `accept_r`, so they remain
stable between accepted beats. Lowering is always:

```text
IAL2 -> axi_r_beat_acceptor.isf -> axi_r_beat_acceptor.fsm -> HDL
```

## 6. Exact Behavioral Contract

For every admitted one-shot arm:

1. while unarmed, `RREADY = 0` and no beat is accepted;
2. assert ready/busy without waiting for RVALID;
3. hold ready/busy until one transfer;
4. accept and capture exactly one `RVALID && RREADY` edge;
5. clear ready/busy on that edge;
6. preserve the captured tuple until a later accepted beat; and
7. emit exactly one later one-cycle beat-done pulse.

An arm pulse while busy is not admitted. Same-cycle rearm, queued arms, and
back-to-back accepted beats are unsupported. If the subordinate presents the
next beat while RREADY is low, it retains RVALID and payload under the AXI
transmitter obligation until a later arm.

Reset while idle or active clears ready/busy, ownership, and pending done. An
active reset abort does not create a handshake or done pulse. Captured fields
use the generated output reset defaults and are replaced only on a later
accepted beat.

The actor captures raw RLAST and RRESP. It does not define read completion,
status success, data validity after an error response, or request ownership.

## 7. Exact Report Contract

Schema:
`fsmgen.ial2.protocol_intent.axi_r_beat_acceptor.v1`.

Required top-level content:

- `mode = acceptor`;
- standard `layering` with source IAL2, generated `isf`/`fsm`, and
  `direct_ial2_to_ial0 = false`;
- `source_object { id, intent_name, anchors[] }`;
- `target_protocol { profile = axi4, object = axi-r-beat-acceptor,
  role = subordinate-to-manager }`;
- `acceptor { name, actor_name }`;
- cloned `bindings { clock, reset, command, channel }`;
- `bounded_beat` exactly:

```text
arming_policy             = explicit_one_beat
ready_policy              = assert_after_arm_without_waiting_for_valid
accept_condition          = rvalid && rready
id_width                  = 4
data_width                = 32
response_width            = 2
last_width                = 1
capture_policy            = on_accept_and_hold_until_next_accept
done_event                = r_beat_accepted
done_policy               = one_pulse_per_accepted_arm_after_transaction_retirement
includes_read_completion  = false
back_to_back_supported    = false
```

- generated IAL1/IAL0 artifacts plus the selected HDL entry; and
- the exact static rules and ordered residue below.

### Enforced static rules

1. profile is `axi4` and object is `axi-r-beat-acceptor`;
2. role is `subordinate-to-manager`;
3. one explicit arm owns one R beat acceptance;
4. RREADY is manager-driven and asserts after arm without waiting for RVALID;
5. RID and captured RID widths are 4;
6. RDATA and captured RDATA widths are 32;
7. RRESP and captured RRESP widths are 2;
8. RLAST and captured RLAST are scalar and captured raw;
9. capture occurs only on `RVALID && RREADY` and is held until the next
   accepted beat;
10. busy/ready clear on acceptance and beat-done is one later pulse;
11. beat-done does not imply RLAST, response success, ID match, length
    satisfaction, or read completion;
12. all bindings and reserved internal names are distinct; and
13. direct IAL2-to-IAL0 lowering is forbidden.

### Unsupported residue

The report contains these IDs in this order:

1. `axi_r_beat_acceptor_ar_coordination_deferred`
2. `axi_r_beat_acceptor_repeated_multi_beat_deferred`
3. `axi_r_beat_acceptor_arlen_rlast_validation_deferred`
4. `axi_r_beat_acceptor_read_completion_deferred`
5. `axi_r_beat_acceptor_id_match_deferred`
6. `axi_r_beat_acceptor_response_interpretation_deferred`
7. `axi_r_beat_acceptor_capacity_core_integration_deferred`
8. `axi_r_beat_acceptor_outstanding_back_to_back_deferred`
9. `axi_r_beat_acceptor_widths_fixed`
10. `axi_r_beat_acceptor_extended_response_signals_deferred`
11. `axi_r_beat_acceptor_subordinate_stall_assertions_deferred`
12. `axi_r_beat_acceptor_transaction_interface_deferred`
13. `axi_r_beat_acceptor_profile_alias_deferred`
14. `axi_r_beat_acceptor_verification_output_deferred`
15. `axi_r_beat_acceptor_backend_variants_deferred`

Details must preserve `.28`'s exclusions. In particular, raw RLAST capture is
not ARLEN/RLAST validation; raw RRESP capture is not status interpretation;
and stable captured RID is not an ARID/RID ownership proof.

## 8. Public Accounting And Manifest

Add one `RegressionCorpus` entry beside AR/B:

```text
id                           intent.ppif_axi_r_beat_acceptor
relpath                      ppif/axi_r_beat_acceptor.ppif
family                       protocol_fixture
classification               supported_smoke
coverage                     ial2_ppif_axi_r_beat_acceptor_pipeline_cli
source_kind                  ppif
strict_supported             1
expected_module_name         axi_r_beat_acceptor
expected_semantic_source_root_kind fsm
```

Update t/248:

- add the coverage key to the required coverage lists/map;
- protocol fixtures: 303 -> 304;
- supported-smoke: 344 -> 345; and
- strict-supported: 344 -> 345.

Extend the `.ppif` boundary prose in `LanguageSurfaceSection.pm` with “the
bounded AXI manager R read-data beat acceptor source” and add the exact matching
t/297 regex. The prose must say explicit one-beat acceptance/raw capture and
must not advertise a complete read transactor.

## 9. Exact Focused Test

`t/1505-ial2-axi-r-beat-acceptor.t` contains exactly four top-level subtests:

1. **adapter/report/generated artifacts** - identity, eight exact anchors,
   bindings, `bounded_beat`, static rules, ordered residue, exact ISF/FSM and
   13-port/six-state/3+7-assignment/three-priority schedule;
2. **fail-closed contract** - wrong profile/role, all six width mismatches,
   malformed reset, duplicate/unknown/missing clauses and bindings, duplicate
   object/name, mixed object, and `.axi` rejection;
3. **CLI and external HDL validation** - strict check JSON, semantic JSON,
   schedule JSON, outdir `.isf`/`.fsm`/HDL, and `--verify-hdl` Verilator lint +
   Yosys synthesis; and
4. **generated-HDL cardinality/capture/reset** - executable Verilator proof.

The harness must prove:

- unarmed RVALID produces no handshake;
- already-high RVALID with RID `3`, RDATA `32'h12345678`, RRESP `2`, and
  RLAST `0` accepts exactly once for one arm;
- holding RVALID high and mutating every input after that acceptance creates no
  second handshake and cannot change the captured tuple;
- a delayed-valid arm holds RREADY/busy for at least four cycles;
- a command while that arm is busy is ignored;
- the delayed beat captures RID `9`, RDATA `32'hcafef00d`, RRESP `3`, RLAST
  `1` exactly once;
- reset while idle and reset while active leave ready/busy/done low, and the
  active-reset abort creates neither handshake nor done;
- after reset, a one-cycle RVALID captures RID `5`, RDATA `32'h0badc0de`,
  RRESP `0`, RLAST `1`;
- total `handshakes = 3`, `done_pulses = 3`; and
- final captured tuple is `5/0badc0de/0/1`, with ready/busy low.

Count handshakes at rising edges. Do not equate the later done cycle with the
physical capture edge.

## 10. Implementation Touch Points

`.30` owns one atomic additive slice:

- new `perl/FSM/IAL2/ProtocolIntent/AxiRBeatAcceptor.pm`;
- PPIF import/result dispatch/alias guard/root accumulator+clause+cardinality+
  all mixing predicates/return/object parser/binding parsers/missing
  enumeration/predicate;
- new `ppif/axi_r_beat_acceptor.ppif`;
- `RegressionCorpus.pm` plus t/248 accounting;
- `LanguageSurfaceSection.pm` plus t/297 assertion;
- new exact four-subtest `t/1505-ial2-axi-r-beat-acceptor.t`;
- AXI mdBook shipped source/commands/semantics/test section;
- task-tree/index/Memory/Knowledge Map/behavior fact; and
- no unrelated generator, alias, backend, or protocol changes.

The implementation must preserve the mandatory layered lowering and keep
public syntax/report wording backend-language-neutral. The Perl module name is
the current reference implementation, not the definition of the IAL contract.

## 11. Validation And Rollback

Implementation validation includes:

- Perl syntax for the new generator, PPIF adapter, support/manifest modules,
  and t/1505;
- focused t/1505 including `--verify-hdl` and executable generated HDL;
- guarded t/1499-t/1505 plus t/248 and t/297;
- strict check of the public source;
- mdBook, Knowledge Map, Memory, docs-path, whitespace, and doctrine gates.

Rollback of `.30` removes the additive module/source/test/support/manifest/
book/fact wiring and restores counts. All shipped AW/AR/W/B/composition and
capacity/status behavior remains unaffected.

This `.29` selector rolls back by removing this contract/fact, restoring `.29`
active, removing `.30`, and restoring task-index/book/Memory pointers. No
behavior rollback is required.

## 12. Preserved Deferrals

No part of this contract activates AR/R composition, fixed-single-beat or
multi-beat read completion, repeated reception/rearm policy, ARLEN/RLAST
validation, RRESP interpretation/aggregation, RID/ARID ownership, capacity
integration, outstanding/back-to-back/queue/demux behavior, configurable or
extended R widths/sidebands, decision `0020`, `.axi` aliases,
verification-output generation, direct backend lowering, backend-language
variants/VHDL, AHB, or APB behavior.
