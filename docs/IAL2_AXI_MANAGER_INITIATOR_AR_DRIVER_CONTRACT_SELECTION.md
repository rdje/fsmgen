# IAL2 AXI manager initiator — bounded AR driver contract selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.25` (behavior-neutral contract
selection).

Date: 2026-07-23

Status: exact public/generator/report/test contract selected. The following
leaf, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.26`, owns implementation.

This selector changes no parser, generator, public source, support-accounting
entry, capability manifest, test, generated artifact, runtime behavior, or HDL
behavior.

## 1. Selected identity

The audited AR primitive becomes a new additive `.ppif` object and generated
module named `axi_ar_driver`. It accepts one idle local command, captures the
complete core AR request tuple, drives exactly one read-address handshake, and
reports address-request acceptance only.

| Facet | Selected value |
| --- | --- |
| PPIF clause/object | `(axi-ar-driver ...)` / `axi-ar-driver` |
| parser contract `kind` | `axi_ar_driver` |
| generator | `FSM::IAL2::ProtocolIntent::AxiArDriver` |
| generated result `kind` | `protocol_intent.axi_ar_driver` |
| report schema | `fsmgen.ial2.protocol_intent.axi_ar_driver.v1` |
| result mode | `driver` |
| public source | `ppif/axi_ar_driver.ppif` |
| intent/actor/module name | `axi_ar_driver` |
| generated IAL1 | `axi_ar_driver.isf` |
| generated IAL0 | `axi_ar_driver.fsm` |
| support id | `intent.ppif_axi_ar_driver` |
| coverage key | `ial2_ppif_axi_ar_driver_pipeline_cli` |
| focused test | `t/1504-ial2-axi-ar-driver.t` |

This is a distinct generator rather than a mode on `AxiAwDriver`. The transport
architecture is intentionally shared, but AW and AR remain independent AXI
channels with different dependency and completion boundaries.

## 2. Exact public source

```text
(protocol-platform-intent axi_ar_driver
  (profile axi4)
  (source
    (object axi-ar-driver)
    (anchor (document IHI0022_L_2025-08) (section A2.3) (page 29))
    (anchor (document IHI0022_L_2025-08) (section A2.3.1) (page 30))
    (anchor (document IHI0022_L_2025-08) (section A2.3.2.2) (page 32))
    (anchor (document IHI0022_L_2025-08) (section A2.6) (page 41))
    (anchor (document IHI0022_L_2025-08) (section A3.1) (page 42))
    (anchor (document IHI0022_L_2025-08) (section A3.1.1) (page 43))
    (anchor (document IHI0022_L_2025-08) (section A3.1.2) (page 44))
    (anchor (document IHI0022_L_2025-08) (section A3.1.4) (page 46))
    (anchor (document IHI0022_L_2025-08) (section B1.2.1) (page 279)))
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
      (done ar_done))))
```

All nine anchors refer to physical PDF pages in the tracked
`IHI0022_L_2025-08` artifact. The source keeps protocol facts, project width
pins, and unsupported residue distinguishable.

### Binding semantics

The `(command ...)` block contains upstream inputs plus subordinate-owned
ARREADY. The `(channel ...)` block contains driven AR signals and local status.

- `ar_cmd_valid` is a one-shot local trigger, admitted only while idle. There
  is no command-ready output and no queue.
- `cmd_araddr[31:0]`, `cmd_arid[3:0]`, `cmd_arlen[7:0]`,
  `cmd_arsize[2:0]`, and `cmd_arburst[1:0]` are sampled together on admission.
- `arready` is subordinate-owned. The driver cannot wait for it before
  asserting ARVALID.
- `arvalid`, `araddr[31:0]`, `arid[3:0]`, `arlen[7:0]`,
  `arsize[2:0]`, and `arburst[1:0]` are manager-driven.
- `ar_busy` is high while this zero-depth primitive owns the admitted request.
- `ar_done` is a one-cycle pulse after exactly one accepted
  `ARVALID && ARREADY` transfer.
- `ar_done` does not mean RVALID, RLAST, successful RRESP, or read-transaction
  completion.

The distinct `cmd_ar*` and `ar*` names are mandatory public defaults, while all
bindings remain rebindable identifiers in authored `.ppif`.

The payload is deliberately dynamic rather than fixed to LEN=0/SIZE=2/INCR.
The driver transports authored metadata; it does not validate its legal
cross-product or accept the R beats that metadata requests. Those obligations
remain visible in report residue and in the later full-read composition.

## 3. Parser contract

### Root object and cardinality

`FSM::Adapter::IAL2::PPIF::_contract_from_root` gains an `@axi_ar_drivers`
accumulator and an `axi-ar-driver` clause arm. The root policy is:

- require an AXI-family root profile at parser dispatch, then let generator
  normalization pin this implementation to exact `axi4`;
- require exactly one `(axi-ar-driver ...)` object;
- reject mixing it with Valid-Ready, capacity/status, AW/W/B, write
  composition, APB, or AHB objects; and
- include `(axi-ar-driver ...)` in the missing-intent-object enumeration.

An AR driver and a future R acceptor cannot appear together merely by relaxing
cardinality. Their coordination requires an explicit composition owner.

### Clause parsing

`_parse_axi_ar_driver` requires exactly these top-level clauses once each:

```text
role clock reset command channel
```

`_parse_axi_ar_driver_command_block` accepts and requires:

```text
start=scalar address=width id=width length=width size=width burst=width ready=scalar
```

`_parse_axi_ar_driver_channel_block` accepts and requires:

```text
valid=scalar address=width id=width length=width size=width burst=width busy=scalar done=scalar
```

Every absent, duplicate, or unsupported clause fails in the parser. The
normalized parser contract is:

```text
kind        = axi_ar_driver
name        = <object name>
role        = manager-to-subordinate
clock       = <identifier>
reset       = <normalized reset>
command     = { start, address{name,width}, id{name,width},
                length{name,width}, size{name,width}, burst{name,width}, ready }
channel     = { valid, address{name,width}, id{name,width},
                length{name,width}, size{name,width}, burst{name,width}, busy, done }
protocol    = <root profile>
source      = <object + anchors>
intent_name = <root name>
```

### `.axi` alias policy

The AR driver ships only through generic `.ppif`. The existing `.axi` guard
gains an AR-specific rejection with diagnostic substring:

```text
(axi-ar-driver ...) remains unsupported for the first profile-alias implementation
```

No `.axi` fixture or support entry is added. Existing `.axi` behavior remains
unchanged.

## 4. Generator normalization and diagnostics

`AxiArDriver::_normalize_contract` mirrors the defensive corrected AW driver
envelope and pins the first-slice contract.

| Invalid contract | Required diagnostic substring |
| --- | --- |
| wrong kind | `AXI AR driver IAL2 contract kind must be axi_ar_driver` |
| profile other than exact AXI4 | `AXI AR driver IAL2 contract profile must be axi4 in this slice` |
| wrong role | `AXI AR driver IAL2 contract role must be manager-to-subordinate` |
| command/channel address width | identify the exact field and require 32 |
| command/channel ID width | identify the exact field and require 4 |
| command/channel length width | identify the exact field and require 8 |
| command/channel size width | identify the exact field and require 3 |
| command/channel burst width | identify the exact field and require 2 |
| absent scalar/binding | identify the exact missing `command.*` or `channel.*` field |
| invalid identifier | identify the field and require an ISF identifier |
| duplicate interface/internal name | `AXI AR driver IAL2 contract duplicates interface/internal signal '<name>'` |
| malformed source anchors | identify `source.anchors[index]` and the missing field |
| `.axi` source | the exact profile-alias substring above |

Root parser diagnostics must identify the source and `axi-ar-driver` object for
wrong profile family, cardinality, mixing, duplicate/unsupported clauses, and
missing blocks.

The duplicate-name set includes clock, reset, every command/channel binding,
and reserved locals `addr_q`, `id_q`, `len_q`, `size_q`, `burst_q`, and
`active_q`.

The public fixture pins active-low asynchronous reset. Generator normalization
must retain the shared PPIF reset model and reject malformed reset bindings;
it does not invent a separate AXI reset language.

## 5. Exact generated IAL1 target

Binding substitutions are allowed; this control structure is fixed:

```text
(actor axi_ar_driver
  (clock clk)
  (reset (rst_n async active_low))

  (interface
    (input ar_cmd_valid)
    (input cmd_araddr (width 32))
    (input cmd_arid (width 4))
    (input cmd_arlen (width 8))
    (input cmd_arsize (width 3))
    (input cmd_arburst (width 2))
    (input arready)
    (output arvalid)
    (output araddr (width 32))
    (output arid (width 4))
    (output arlen (width 8))
    (output arsize (width 3))
    (output arburst (width 2))
    (output ar_busy)
    (output ar_done))

  (priority accept_ar over launch_ar)

  (rule launch_ar launch_ar_start
    (set active_q 1)
    (set ar_busy 1)
    (set arvalid 1)
    (set araddr addr_q)
    (set arid id_q)
    (set arlen len_q)
    (set arsize size_q)
    (set arburst burst_q))

  (rule accept_ar (& arvalid arready)
    (set active_q 0)
    (set ar_busy 0)
    (set arvalid 0))

  (transaction ar_issue
    (on ar_cmd_valid
      (sample cmd_araddr as addr_q)
      (sample cmd_arid as id_q)
      (sample cmd_arlen as len_q)
      (sample cmd_arsize as size_q)
      (sample cmd_arburst as burst_q))
    (drive
      (launch_ar_start 1))
    (while active_q
      (wait 1))
    (complete ar_done)))
```

The interface has seven inputs and eight outputs. The rules have eight and
three assignments respectively. The scheduler must produce exactly six states:

```text
ar_issue_idle_0
ar_issue_drive_1
ar_issue_while_entry_2
ar_issue_wait_3
ar_issue_while_check_4
ar_issue_done_5
```

`compile_issues` must be empty, and the exact priority-resolution triples are:

```text
accept_ar : launch_ar : active_q
accept_ar : launch_ar : ar_busy
accept_ar : launch_ar : arvalid
```

The acceptance rule clears valid on the edge that recognizes the handshake.
Continuously-high ARREADY therefore accepts once. The payload is written only
at launch and remains stable during stalls. A one-cycle delayed ARREADY pulse
cannot be lost because control waits on latched `active_q`.

Lowering is always:

```text
IAL2 -> generated axi_ar_driver.isf -> generated axi_ar_driver.fsm -> HDL
```

Direct IAL2-to-IAL0 lowering is forbidden.

## 6. Exact report contract

The report schema is
`fsmgen.ial2.protocol_intent.axi_ar_driver.v1`, with:

- `mode = driver`;
- `layering { source_layer=IAL2, generated_ial1_format=isf,
  generated_ial0_format=fsm, direct_ial2_to_ial0=false }`;
- `source_object { id, intent_name, anchors[] }`;
- `target_protocol { profile=axi4, object=axi-ar-driver,
  role=manager-to-subordinate }`;
- `driver { name, actor_name }`;
- cloned `bindings { clock, reset, command, channel }`;
- generated IAL1/IAL0/selected-HDL-entry artifacts;
- `enforced_static_rules[]` and exact `unsupported_residue[]`; and
- this machine-readable request scope:

```text
request_scope = {
  address_width         = 32,
  id_width              = 4,
  length_width          = 8,
  size_width            = 3,
  burst_width           = 2,
  done_event            = ar_request_accepted,
  includes_read_response = false
}
```

### Enforced static rules

1. profile must be `axi4` and object must be `axi-ar-driver`;
2. role must be `manager-to-subordinate`;
3. address/ID/length/size/burst widths are 32/4/8/3/2 on both sides;
4. the first slice drives the complete core AR request payload;
5. ARVALID is launched independently of ARREADY and accepted exactly once;
6. `ar_done` means accepted AR request, not read response/completion;
7. command inputs and driven channel/status outputs are distinct; and
8. direct IAL2-to-IAL0 lowering is forbidden.

### Exact unsupported-residue ids

| Id | Meaning |
| --- | --- |
| `axi_ar_driver_id_width_fixed` | ARID is pinned to four bits |
| `axi_ar_driver_attributes_deferred` | extended AR attributes and sidebands are absent |
| `axi_ar_driver_request_legality_deferred` | no 4KB, reserved-encoding, WRAP, alignment, size/data-width, or cross-field validation |
| `axi_ar_driver_r_channel_deferred` | no RREADY, RID/RDATA/RRESP/RLAST capture, beat accounting, or ID match |
| `axi_ar_driver_request_only_completion` | done is request acceptance; full read completion requires composition |
| `axi_ar_driver_capacity_core_integration_deferred` | no physical-to-abstract capacity/status adapter |
| `axi_ar_driver_outstanding_deferred` | one active request, no queue or multiple outstanding reads |
| `axi_ar_driver_transaction_interface_deferred` | decision `0020` remains director-gated |
| `axi_ar_driver_profile_alias_deferred` | no `.axi` AR-driver source |
| `axi_ar_driver_verification_output_deferred` | no verification-output generation |
| `axi_ar_driver_backend_variants_deferred` | no direct backend, backend-language variant, or VHDL behavior |

The R-channel residue must state the complete-manager obligation clearly: once
a read request is issued, later composition must accept every returned beat
described by that request. The AR primitive neither discharges nor hides that
obligation.

## 7. Exact implementation owner (`.26`)

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.26` owns exactly:

1. add `FSM::IAL2::ProtocolIntent::AxiArDriver` with defensive API validation,
   exact normalization, corrected rule-pair ISF, scheduler lowering, cloning,
   report, request scope, static rules, and residue above;
2. wire the PPIF import, result dispatch, root accumulator/clause/cardinality/
   mixing/profile/return, object and command/channel parsers, missing-object
   enumeration, contract predicate, and AR-specific `.axi` rejection;
3. add the exact nine-anchor `ppif/axi_ar_driver.ppif` source in section 2;
4. add `intent.ppif_axi_ar_driver` / `ial2_ppif_axi_ar_driver_pipeline_cli` /
   expected module `axi_ar_driver` / semantic root `fsm`;
5. update `t/248`: allow the coverage key/classification and move protocol
   fixtures 302 -> 303, supported fixtures 343 -> 344, and strict-supported
   fixtures 343 -> 344;
6. extend `LanguageSurfaceSection.pm` and exact `t/297` assertions to name the
   shipped bounded AR driver alongside the write-side actors;
7. add exact four-subtest `t/1504-ial2-axi-ar-driver.t` from section 8;
8. extend the AXI mdBook chapter with the shipped source, commands, artifacts,
   request-only semantics, generated-HDL proof, and residue; and
9. synchronize task tree/index, Memory, behavior fact, and Knowledge Map.

It must preserve every shipped AW/W/B/request/full-write and capacity/status
surface. Shared PPIF changes are additive only.

## 8. Exact four-subtest regression

`t/1504-ial2-axi-ar-driver.t` contains exactly four top-level subtests.

### 1. Adapter, report, artifacts, and schedule

Assert layer/kind/mode/schema/source/target; all command/channel names and
widths; 15 interface ports; launch and acceptance rules; active wait;
`request_scope`; all static rules/residue IDs; one generated `.isf`; one
generated `.fsm`; six exact states; no compile issues; and the exact three
priority resolutions.

### 2. Malformed sources fail closed

Exercise at least: non-AXI root profile; AXI-family profile other than axi4;
wrong role; missing clock/reset/command/channel; duplicate/unsupported clause;
wrong command and channel widths for every payload field; invalid identifier;
duplicate public/internal name; duplicate AR object; mixed AR/AW object;
malformed anchor; and `.axi` alias use. Every case requires a targeted
diagnostic.

### 3. CLI and external validation

Prove strict check JSON with matched support; semantic JSON with FSM root;
schedule/report JSON; outdir `.isf`, `.fsm`, and selected HDL; Verilator lint;
and Yosys synthesis through `--verify-hdl`.

### 4. Generated-HDL behavior

The executable test must prove:

- continuously-high ARREADY accepts exactly one transfer and emits one done;
- delayed ARREADY holds ARVALID and all five captured fields stable for at
  least four cycles while upstream command inputs mutate;
- a one-cycle ARREADY pulse is not lost;
- a command presented while busy is ignored;
- reset while idle leaves outputs/status low;
- reset while stalled cancels the request without a late done;
- a fresh post-reset command works;
- dynamic metadata values include nonzero ARLEN and distinct size/burst values;
- done is one cycle; and
- final ARVALID, busy, and done are low.

The harness counts handshakes only on rising `clk` edges and checks all five
payload fields at acceptance. Expected totals must be exact and documented in
the test after the scenario sequence is finalized; no `>=` cardinality checks
are allowed.

## 9. Validation and rollback

The implementation slice runs syntax, focused AW-through-AR initiator tests,
`t/248`, `t/297`, strict/schedule/semantic/outdir/Verilator/Yosys/executable
proof, mdBook build, Knowledge Map generation/check, bounded Memory/docs-path/
whitespace checks, and `scripts/check_doctrines.sh`. Heavy/broad test runs use
the repository RAM guard.

Rollback for `.25` removes this contract note/fact, restores `.25` to active,
removes `.26`, and restores task-index/book/Memory pointers. No behavior
rollback is required because this leaf changes none.
