# AXI IAL2 Examples

AXI is the first shipped IAL2 protocol profile. It is not the definition of
IAL2. The generic IAL2 rules, including the mandatory generated `.isf` then
generated `.fsm` review-artifact chain, are in
[IAL2 Protocol and Platform Intent](16-ial2-protocol-platform-intent.md).

Every example in this chapter is checked in under `ppif/`. The examples are
organized by authoring mode, not by implementation module.

## Mode Map

| Mode | Start with | What it demonstrates |
| --- | --- | --- |
| Guided mode | `ppif/axi_aw_valid_ready.ppif` and `ppif/axi_aw_valid_ready.axi` | A single AXI AW Valid-Ready monitor, source anchors, generated assertions, and `.ppif`/`.axi` profile-alias parity for the selected first alias. |
| Initiator mode | `ppif/axi_aw_driver.ppif` | A bounded AXI manager AW address-channel **driver**: it drives `AWVALID` and the AW payload against `AWREADY`, holds payload stable under backpressure, and accepts exactly one AW transfer per accepted command. |
| More-control mode | `ppif/axi_manager_capacity_status.ppif`, `ppif/axi_manager_capacity_status_id_family.ppif`, and `ppif/axi_manager_capacity_status_transaction_envelope.ppif` | Bounded manager capacity/status, ID-family metadata, and logical transaction metadata while staying in the public AXI manager shell. |
| Raw/full-control mode | `ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif` | A deep shipped AXI manager shape with dynamic read transactions, same-ID issue-order queueing, burst-last response demux, runtime beat-count/`RLAST` validation, and multi-beat read-data output banks. |

Raw/full-control mode is still IAL2. It does not mean raw HDL, direct backend
generation, or bypassing generated review artifacts.

## Guided Mode

The smallest AXI source is the AW Valid-Ready monitor:

```text
(protocol-platform-intent axi_aw_valid_ready
  (profile axi4)
  (source
    (object axi-valid-ready-aw)
    (anchor (document IHI0022_L_2025-08) (section A3.2.1) (page A3-40)))
  (valid-ready-channel axi_aw
    (channel AW)
    (role manager-to-subordinate)
    (clock clk)
    (reset (rst_n active_low async))
    (valid awvalid)
    (ready awready)
    (payload
      (awaddr width 32)
      (awlen width 8))))
```

Run the generic `.ppif` source:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_aw_valid_ready.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/axi_aw_valid_ready.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_aw_valid_ready.ppif
./bin/fsmgen --quiet --outdir generated ppif/axi_aw_valid_ready.ppif
```

Run the selected `.axi` profile alias:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_aw_valid_ready.axi
```

The alias is still IAL2 over the same PPIF-backed model. It reports
`source_kind` as `ial2_profile_alias`; the generic file reports `source_kind`
as `ppif`.

The guided `--outdir` path writes these review artifacts before HDL:

```text
generated/axi_aw_valid_ready_monitor.isf
generated/axi_aw_valid_ready_monitor.fsm
```

The generated `.isf` contains the monitor transaction and the stall-stability
assertions. The generated `.fsm` contains the corresponding `+assert` carriers
and the one-cycle `axi_aw_valid_ready_monitor_done` pulse.

## Initiator Mode (Driving)

The guided AW source *observes* a handshake. The initiator source *drives* it.
`ppif/axi_aw_driver.ppif` is a bounded AXI manager AW address-channel driver: on
a one-shot command trigger it samples the command payload, asserts `AWVALID` and
drives the AW payload (`AWADDR`/`AWID`/`AWLEN`/`AWSIZE`/`AWBURST`) held stable
until the subordinate raises `AWREADY`, accepts that transfer exactly once,
then pulses a one-cycle `aw_done`.

```text
(protocol-platform-intent axi_aw_driver
  (profile axi4)
  (source
    (object axi-aw-driver)
    (anchor (document IHI0022_L_2025-08) (section A3.2.1) (page A3-40)))
  (axi-aw-driver axi_aw_driver
    (role manager-to-subordinate)
    (clock clk)
    (reset (rst_n active_low async))
    (command
      (start aw_cmd_valid)
      (address cmd_awaddr width 32)
      (id cmd_awid width 4)
      (length cmd_awlen width 8)
      (size cmd_awsize width 3)
      (burst cmd_awburst width 2)
      (ready awready))
    (channel
      (valid awvalid)
      (address awaddr width 32)
      (id awid width 4)
      (length awlen width 8)
      (size awsize width 3)
      (burst awburst width 2)
      (busy aw_busy)
      (done aw_done))))
```

The `(command …)` block is the *upstream* order (what transfer to issue) and the
`(channel …)` block is the *driven* AW bus interface — two distinct signal sets,
so the command inputs never alias the driven outputs. The generated actor asserts
`AWVALID` before waiting, holds it (and the payload) stable across the wait,
clears it on the accepted-transfer edge, and completes with a one-cycle pulse
— the same VALID-hold/payload-stable obligation the AW monitor *checks*, here
*guaranteed* by the driver.

Run it end to end:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_aw_driver.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/axi_aw_driver.ppif
./bin/fsmgen --quiet --outdir generated ppif/axi_aw_driver.ppif
./bin/fsmgen --verify-hdl ppif/axi_aw_driver.ppif
```

The schedule report uses `fsmgen.ial2.protocol_intent.axi_aw_driver.v1` and
reports `mode` `driver`. The `--outdir` path writes
`generated/axi_aw_driver.isf` then `generated/axi_aw_driver.fsm` before HDL, and
`--verify-hdl` passes verilator lint and yosys synthesis for the generated
`axi_aw_driver` module.

This is the first AXI **initiator** (bus-driving) source. It complements the
capacity/status response core; it drives only the AW address channel. W
write-data drive, AR read-address drive, burst/address generation, the AXI
attribute signals (`AWLOCK`/`AWCACHE`/`AWPROT`/`AWQOS`/`AWREGION`/`AWUSER`), a
configurable `AWID` width, and integration with the capacity/status core remain
future increments (see the report's `unsupported_residue`).

### Single-transfer correctness guarantee

The generated ISF uses a one-state inline launch handoff and two concurrent
rules. `launch_aw` registers the sampled payload and raises `AWVALID` plus the
active/busy state. `accept_aw`, guarded by `AWVALID && AWREADY`, clears
`AWVALID` and the active/busy state on the same rising edge that accepts the
transfer. Explicit `accept_aw`-over-`launch_aw` priority resolves their shared
writes, and the transaction waits on the latched active bit rather than
depending on a later resample of `AWREADY`.

The focused executable regression covers both continuously-high `AWREADY` and
a four-cycle payload stall followed by a one-cycle `AWREADY` pulse. Across two
commands it requires exactly two rising-edge `AWVALID && AWREADY` acceptances,
two one-cycle `aw_done` pulses, stable payload throughout the stall, and final
`AWVALID = aw_busy = 0`. The generated schedule has six states, no compile
issues, and three explicit priority resolutions; generated HDL also passes
Verilator lint and Yosys synthesis.

W remains the next functional direction: a later single-beat primitive will
drive `WVALID`, 32-bit `WDATA`, 4-bit `WSTRB`, and `WLAST = 1` against
`WREADY`. AW/W transaction composition and the proposed protocol-neutral
transaction interface remain separate future owners.

## More-Control Mode

Move to manager capacity/status when the user needs AXI manager-level control
instead of a single channel monitor.

`ppif/axi_manager_capacity_status.ppif` introduces:

- read and write pending-capacity limits;
- `submit-policy try`;
- abstract read/write submit and completion events;
- status outputs such as can-accept, full, pending, and slots-available.

`ppif/axi_manager_capacity_status_id_family.ppif` adds ID-family metadata:

```text
(id-families
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid))
  (read (width 4) (request-id axi0_arid) (response-id axi0_rid)))
```

`ppif/axi_manager_capacity_status_transaction_envelope.ppif` adds logical
transactions over that capacity/status shell:

```text
(transactions
  (write w0
    (tag wr0)
    (request axi0_write_submit)
    (completion axi0_write_complete)
    (id auto))
  (read r0
    (tag rd0)
    (request axi0_read_submit)
    (completion axi0_read_complete)
    (id (value 3))))
```

Useful more-control probes are:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_id_family.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_transaction_envelope.ppif
```

The schedule report for these manager examples uses
`fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1` and records that
the generated review-artifact formats are `isf` and `fsm`. The transaction
semantic JSON keeps the authored `.ppif` source path and support-accounts the
checked-in transaction-envelope example as
`intent.ppif_axi_manager_capacity_status_transaction_envelope`.

## Raw/Full-Control Mode

The raw/full-control AXI example for this chapter is:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif
```

This checked-in source stays inside one bounded shipped AXI manager family, but
it exposes several explicit controls at once:

- three dynamic read transactions `r0`, `r1`, and `r2`;
- `same-id-ordering` with `dynamic-id-reuse issue-order-queue`;
- burst-last `response-demux` with generated transaction completions;
- multi-beat read-data capture by `RID`;
- raw `ARLEN` burst-length capture with AXI `axlen-plus-one` encoding;
- runtime beat-count/`RLAST` validation;
- per-transaction data/status output-bank prefixes and valid masks.

Validate that deep shape with:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif
```

Use `--emit-schedule-json` or `--outdir` on this family when reviewing a
specific implementation slice. For routine documentation review, the strict
check is usually the fastest proof that the checked-in source still parses and
passes the selected static contract.

## Residue

The shipped AXI IAL2 surface is broad but bounded. The following are not
claimed by this chapter:

- full AXI manager behavior;
- arbitrary cardinalities;
- complete scoreboards;
- authored/general different-ID interleaving beyond selected families;
- broader `.axi` manager profile-alias behavior beyond the selected AW
  Valid-Ready alias;
- direct IAL2-to-HDL or IAL2-to-IAL0 lowering;
- verification-output generation;
- backend-language variants;
- VHDL behavior.

Those items need future task-tree leaves before they can become user-facing
behavior.

## Validation Used For This Chapter

This chapter was validated from checked-in sources with:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_aw_valid_ready.ppif
./bin/fsmgen --quiet --strict --check --json ppif/axi_aw_valid_ready.axi
./bin/fsmgen --quiet --strict --check --json ppif/axi_aw_driver.ppif
./bin/fsmgen --verify-hdl ppif/axi_aw_driver.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_id_family.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif
./bin/fsmgen --quiet --outdir /tmp/fsmgen-doc-axi-691-out ppif/axi_aw_valid_ready.ppif
```

The temporary outdir probe produced `axi_aw_valid_ready_monitor.isf` and
`axi_aw_valid_ready_monitor.fsm`, confirming that the guided example still
exposes the review artifacts the chapter describes. The AW driver check and
`--verify-hdl` confirm that the initiator example is accepted and lowers to
lint/synthesis-clean HDL. The focused `t/1499-ial2-axi-aw-driver.t` generated-HDL
simulation separately proves the transfer-cardinality, completion-pulse, and
stalled-payload guarantees described above.
