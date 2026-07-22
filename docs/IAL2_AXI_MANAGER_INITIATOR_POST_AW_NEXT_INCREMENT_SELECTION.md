# IAL2 AXI manager initiator — post-AW next-increment selection

Owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.5` (no-behavior selector).
Status: selection recorded; no parser, generator, public-source, test, artifact,
or runtime behavior changes in this leaf.

This note selects the safe continuation after the bounded AW address-channel
driver shipped in `.4`. It keeps W write-data drive as the next functional
direction, but it also resolves the registered-output timing concern recorded
by `.4` before any W implementation can copy that pattern.

## Decision

**Functional direction: a bounded W write-data channel driver, leading toward a
coherent AXI write transaction. Immediate next owner: `.6`, a driven
Valid-Ready single-transfer correctness readiness audit.**

The audit is an implementation prerequisite, not a pivot. It must determine the
smallest exact correction that makes one accepted command produce exactly one
bus transfer when `READY` stays asserted, first on the shipped AW driver and
then as a reusable requirement for a later W driver. It must select the next
contract or implementation owner rather than changing behavior itself.

The later bounded W candidate remains deliberately small: one single-beat
write-data transfer with `WVALID`, 32-bit `WDATA`, 4-bit `WSTRB`, `WLAST = 1`,
and `WREADY`, driven from distinct command inputs and exposing bounded
busy/done status. Multi-beat sequencing, AW/W transaction composition, B
response completion, outstanding transactions, and integration with the
capacity/status core remain later owners.

## Why correctness is the immediate prerequisite

The shipped AW source promises one address transfer per command. A generated
artifact probe disproved that promise for the continuously-ready case:

1. `aw_issue_drive_1` raises `assert_aw_start`; the generated registered
   `awvalid` becomes `1` on the following clock edge.
2. `aw_issue_while_entry_2` observes `AWREADY = 1` and selects
   `aw_issue_drive_5` on the next edge. The first `AWVALID && AWREADY`
   transfer occurs on that edge.
3. `deassert_aw_start` is enabled only while `aw_issue_drive_5` is active.
   Its registered `awvalid = 0` assignment therefore takes effect one edge
   later. `AWVALID && AWREADY` remains true on that second edge, producing a
   second transfer from the same command.

The result is reproducible from the shipped public source:

```bash
./bin/fsmgen --quiet --strict \
  --outdir /tmp/fsmgen-axi-aw-handshake-probe \
  --output /tmp/fsmgen-axi-aw-handshake-probe/axi_aw_driver.sv \
  ppif/axi_aw_driver.ppif
rg -n 'aw_issue_(while_entry_2|drive_5)|deassert_aw_start|awvalid_next' \
  /tmp/fsmgen-axi-aw-handshake-probe/axi_aw_driver.{fsm,sv}
```

A temporary Verilator timing harness held `AWREADY = 1`, pulsed one
`aw_cmd_valid`, and counted `AWVALID && AWREADY` at rising edges. It reported
`HANDSHAKES=2` and failed an `expected exactly one AW transfer` assertion. The
root cause is therefore the generated state/register schedule, not lint,
synthesis, or payload instability.

This is a correctness blocker for copying the AW implementation idiom into W.
The existing `--verify-hdl` lane proves that the HDL parses and synthesizes; it
does not prove transaction cardinality.

## Candidate comparison

| Candidate | Assessment | Disposition |
| --- | --- | --- |
| Implement a standalone W driver immediately | Smallest new channel surface, but cloning the AW assert/wait/deassert schedule would duplicate a proven two-transfer bug when `WREADY` remains high. | Deferred behind `.6`. |
| Audit and correct driven Valid-Ready single-transfer timing | Small, behavior-neutral first step; protects the shipped AW promise and establishes a reusable acceptance invariant for W. | **Selected immediate owner (`.6`).** |
| Combine AW and W into one writer now | Must coordinate two independent AXI channels, command lifetime, completion policy, and potentially different backpressure timing while the primitive handshake is not yet correct. | Deferred. |
| Add multi-beat W sequencing now | Adds beat indexing, `WLAST`, payload/strobe sourcing, and burst-length coupling before single-beat transfer cardinality is sound. | Deferred. |
| Add AR drive | Symmetric address work, but does not advance the selected write path and ultimately couples to R completion. | Deferred. |
| Add burst/address generation or capacity-core integration | Cross-channel/cross-generator work and substantially larger than the primitive timing prerequisite. | Deferred. |

## Decision 0020 framing

The AW driver and future W driver are **bus-side primitive role blocks** under
the transaction-layered/composable-role North Star. They are not themselves the
future protocol-neutral `write(addr, data, len)` interface. The present thread
may shape command/status bindings so later composition is possible, but it must
not activate or silently invent that future interface while decision 0020's
horizon tree remains proposed.

Similarly, decision 0017 defines the aggregate artifact contract for authored
multi-channel Valid-Ready monitor bundles. It does not by itself define AW/W
write-transaction coordination. A future AW+W writer needs its own exact
contract for independent channel progress, command ownership, and completion.

## `.6` audit obligations

The readiness audit must:

- reproduce and structurally explain the continuously-ready double-transfer
  case from checked-in `ppif/axi_aw_driver.ppif`;
- identify whether the narrow owner is generated ISF shape, existing ISF
  scheduling semantics, a new bounded ISF construct, or direct backend timing;
- compare at least one lowering-clean correction candidate and select the next
  exact behavior owner;
- specify an executable regression that counts accepted transfers, not only
  lint/synthesis success;
- preserve AW payload stability while stalled and one-cycle completion status;
- turn `exactly one VALID && READY acceptance per accepted command` into a
  required invariant for the later W driver;
- keep W source syntax, W implementation, AW/W composition, multi-beat
  sequencing, B response completion, profile aliases, verification-output,
  backend variants, and VHDL outside the audit behavior boundary.

The mandatory lowering chain remains
`IAL2 -> generated IAL1/.isf -> generated IAL0/.fsm -> HDL`.
