# IAL2 AXI manager initiator — AW address-channel driver contract selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.3` (no-behavior contract selection).
Status: contract recorded; no parser/generator/source/support-accounting/manifest/
test/artifact/behavior change in this leaf. The implementation is the following
leaf (`.4`).

This note resolves the open questions in
`docs/IAL2_AXI_MANAGER_INITIATOR_AW_DRIVER_READINESS_AUDIT.md` §8 and fixes the
exact contract the implementation leaf will build. It mirrors the AHB
contract-selection precedent
(`docs/IAL2_AHB_REQUESTER_BUSY_INSERTION_CONTRACT_SELECTION.md`).

## Selected contract

### Names

| Facet | Selected value | Rationale |
|---|---|---|
| clause head / object | `(axi-aw-driver …)` | Parallel to `ahb-requester`/`apb-requester`/`manager-capacity-status`/`valid-ready-channel` clause heads in `_contract_from_root` (`PPIF.pm:259`). |
| contract `kind` (parser) | `axi_aw_driver` | Matched by a new `_is_axi_aw_driver_contract` predicate. |
| generator module | `FSM::IAL2::ProtocolIntent::AxiAwDriver` | Same envelope as `AhbRequester.pm`. |
| result `kind` (generate) | `protocol_intent.axi_aw_driver` | Mirrors `protocol_intent.ahb_requester` (`AhbRequester.pm:49`). |
| report `schema` | `fsmgen.ial2.protocol_intent.axi_aw_driver.v1` | Mirrors `fsmgen.ial2.protocol_intent.ahb_requester.v1` (`AhbRequester.pm:513`). |
| public source | `ppif/axi_aw_driver.ppif` | New additive fixture; `(profile axi4)`. |
| generated actor / module | `<name>` → `<name>.isf` → `<name>.fsm` | As `AhbRequester.pm:30-31`. |

### Command inputs vs driven AW outputs (distinct signal sets)

Following the AHB requester's split between `local_command.*` (the transfer to
issue) and `bus.*` (the driven channel) — they are separate bindings with
separate names (`AhbRequester.pm:157-208`). The AW driver samples the command
into `*_q` locals on the trigger, then drives the AW channel from those locals.

**Inputs (environment → driver):** `aw_cmd_valid`(1, one-shot trigger),
`cmd_awaddr`(32), `cmd_awid`(4), `cmd_awlen`(8), `cmd_awsize`(3),
`cmd_awburst`(2), `awready`(1, handshake ack).

**Outputs (driver → AW channel / environment):** `awvalid`(1), `awaddr`(32),
`awid`(4), `awlen`(8), `awsize`(3), `awburst`(2), `aw_busy`(1),
`aw_done`(1, one-cycle pulse).

Names above are the default spelling; all are contract-bound identifiers, so a
consumer may rebind them (as the AHB requester rebinds every signal).

### Payload set — full burst-describing set

The first slice drives the **full burst-describing set**
`{awaddr, awid, awlen, awsize, awburst}`, not `awaddr`+`awlen` only. Driving only
address and length would issue an under-specified AW transfer (no ID, size, or
burst type). This is the audit's §8 recommendation.

### AWID width — pinned in the first slice

`awid`/`cmd_awid` width is **pinned to 4** in the first slice, consistent with
the AHB requester's "pin all widths" discipline (`AhbRequester.pm:617-628`).
Configurable ID width is deferred as residue (`axi_aw_driver_id_width_fixed`).

### Width pins (fail-closed, first slice)

`cmd_awaddr`/`awaddr` = 32, `cmd_awid`/`awid` = 4, `cmd_awlen`/`awlen` = 8,
`cmd_awsize`/`awsize` = 3, `cmd_awburst`/`awburst` = 2. Reject any other width
(`confess`, like `AhbRequester.pm:622`). Profile pinned to `axi4`.

## Generated ISF (target, fixed)

```
(actor <name>
  (clock clk)
  (reset (rst_n async active_low))
  (watchdog 65536)
  (interface
    (input aw_cmd_valid)
    (input cmd_awaddr (width 32))
    (input cmd_awid (width 4))
    (input cmd_awlen (width 8))
    (input cmd_awsize (width 3))
    (input cmd_awburst (width 2))
    (input awready)
    (output awvalid)
    (output awaddr (width 32))
    (output awid (width 4))
    (output awlen (width 8))
    (output awsize (width 3))
    (output awburst (width 2))
    (output aw_busy)
    (output aw_done))
  (storage
    (var aw_done_q (width 1) (reset 0)))
  (drive accept_command
    (aw_busy 1) (aw_done 0))
  (drive assert_aw
    (aw_busy 1) (aw_done 0)
    (awvalid 1)
    (awaddr addr_q) (awid id_q) (awlen len_q) (awsize size_q) (awburst burst_q))
  (drive finish
    (aw_busy 0) (aw_done 1)
    (awvalid 0))
  (transaction aw_issue
    (on aw_cmd_valid
      (sample cmd_awaddr as addr_q)
      (sample cmd_awid as id_q)
      (sample cmd_awlen as len_q)
      (sample cmd_awsize as size_q)
      (sample cmd_awburst as burst_q))
    (local addr_q (width 32))
    (local id_q (width 4))
    (local len_q (width 8))
    (local size_q (width 3))
    (local burst_q (width 2))
    (drive accept_command)
    (drive assert_aw)
    (when awready (drive finish))
    (complete aw_done_q)))
```

The exact ISF spelling (idle-drive defaults, whether `assert_aw` holds across a
`!awready` stall via a loop vs. re-entry) is finalized in the implementation
leaf against the ISF scheduler's semantics; the shape above is the fixed intent.
The AXI stability obligation — `awvalid` held and payload stable until `awready`
— is the property the AW monitor checks (`ValidReadyChannel.pm:325-344`) and the
driver must guarantee.

## Report shape (fixed)

The `report` mirrors `AhbRequester.pm:512-567`:
`schema` = `fsmgen.ial2.protocol_intent.axi_aw_driver.v1`; `mode` = `driver`;
`layering { source_layer=IAL2, generated_ial1_format=isf, generated_ial0_format=fsm,
direct_ial2_to_ial0=false }`; `source_object { id, anchors }`;
`target_protocol { profile=axi4, object='axi-aw-driver', role='manager-to-subordinate' }`;
`bindings { clock, reset, command, channel }`; `generated_artifacts { ial1, ial0,
hdl_entry }`; `enforced_static_rules[]`; `unsupported_residue[]`.

## Enforced static rules (first slice)

- profile must be `axi4`; object must be `axi-aw-driver`; role
  manager-to-subordinate.
- required bindings: name, clock, reset, `aw_cmd_valid`, `awready`, `awvalid`,
  the command payload (`cmd_awaddr`/`cmd_awid`/`cmd_awlen`/`cmd_awsize`/
  `cmd_awburst`), the driven payload (`awaddr`/`awid`/`awlen`/`awsize`/`awburst`),
  and status (`aw_busy`/`aw_done`).
- width pins as above; reject other widths.
- reject duplicate interface/internal signal names.
- identifiers must be ISF identifiers; reset polarity from `_n` suffix unless
  explicit.
- direct IAL2→IAL0 lowering forbidden.

## Unsupported residue (first slice)

- `axi_aw_driver_id_width_fixed` — AWID width pinned to 4; configurable width
  deferred.
- `axi_aw_driver_attributes_deferred` — `AWLOCK`/`AWCACHE`/`AWPROT`/`AWQOS`/
  `AWREGION`/`AWUSER` not driven.
- `axi_aw_driver_w_channel_deferred` — W write-data drive is a later increment
  (AW+W bundle, decision `0017`).
- `axi_aw_driver_ar_channel_deferred` — AR read-address drive deferred.
- `axi_aw_driver_burst_address_generation_deferred` — INCR/WRAP address stepping
  and multi-beat sequencing deferred.
- `axi_aw_driver_capacity_core_integration_deferred` — no wiring to
  `AxiManagerCapacityStatus.pm`.
- `axi_aw_driver_profile_alias_deferred` — `.axi` alias surfacing deferred
  (requires relaxing the `.axi` guard `PPIF.pm:224`).
- `axi_aw_driver_verification_output_deferred` — verification-output generation
  and backend-language variants deferred.

## Implementation leaf (`.4`) touch points (from the audit §5)

`use` at `PPIF.pm:19-20`; `axi-aw-driver` clause + `_parse_axi_aw_driver` +
`@axi_aw_drivers` accumulator + missing-intent enumeration in `_contract_from_root`
(`PPIF.pm:259`); `_is_axi_aw_driver_contract` predicate + dispatch arm in
`parse_source` (`PPIF.pm:99`); `AxiAwDriver.pm`; `ppif/axi_aw_driver.ppif`;
`RegressionCorpus.pm` entry `intent.ppif_axi_aw_driver` (gated by `t/248`);
`LanguageSurfaceSection.pm:69-92` boundary prose (gated by `t/297`); new
`t/14xx-ial2-axi-aw-driver.t` modeled on `t/1473`; a mdBook initiator section in
`docs/book/src/16a-ial2-axi.md`.
