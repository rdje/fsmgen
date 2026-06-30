# IAL2 AHB Two-Subordinate Interconnect Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.730`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.730` ships the first bounded public
generic `.ppif` AHB two-subordinate interconnect/decode source:

```text
ppif/ahb_interconnect_two_subordinate.ppif
```

The source support-accounts as:

```text
entry_id: intent.ppif_ahb_interconnect_two_subordinate
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_two_subordinate_pipeline_cli
module_name: ahb_tb
composition_child_count: 4
```

The matching `.ahb` alias is not shipped in this slice. A two-subordinate
aggregate routed through an `.ahb` source still fails closed; a later task-tree
leaf must explicitly select that alias before behavior changes.

## Public Source Contract

The shipped source contains exactly one AHB requester object, two distinct AHB
subordinate objects, and one AHB interconnect object. The interconnect
children are:

```text
(requester requester amba_requester)
(subordinate status ahb_status_subordinate)
(subordinate control ahb_control_subordinate)
```

The static address map is:

```text
status:  STATUS_BASE=0, STATUS_SIZE=4
control: CONTROL_BASE=4, CONTROL_SIZE=4
```

Each subordinate child must have exactly one matching address-map window.
Windows must be static 32-bit, positive, 4-byte aligned, and non-overlapping.
Duplicate subordinate object names, duplicate child instance names, duplicate
child object references, unreferenced subordinate objects, missing windows,
unknown windows, overlapping windows, duplicate address-map parameters, and
unsupported cardinalities fail closed.

The two-subordinate interconnect wiring block contains only requester/global
AHB bus names. Per-subordinate select, local address, ready-out, response, and
read-data names come from each subordinate object's `(bus ...)` block. Scalar
`subordinate-select`, `subordinate-ready-out`, `subordinate-response`, and
`subordinate-read-data` wiring clauses remain required for the existing
one-subordinate source and are rejected for the two-subordinate source.

## Generated Review Artifacts

The source lowers through generated IAL1 review artifacts before generated
IAL0:

```text
amba_requester.isf
ahb_status_subordinate.isf
ahb_control_subordinate.isf
ahb_interconnect.isf
```

Generated IAL0 artifacts are:

```text
amba_requester.fsm
ahb_status_subordinate.fsm
ahb_control_subordinate.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

The generated HDL entry remains:

```text
ahb_tb
```

## Generated Decode Behavior

The selected behavior remains single-requester and fixed-grant:

```text
HGRANT = 1
active_transfer = HTRANS != 2'b00
```

On a status-window hit, the generated interconnect asserts `HSEL_STATUS`,
drives `HADDR_STATUS = HADDR`, and muxes `HREADYOUT_STATUS`, `HRDATA_STATUS`,
and one-bit `HRESP_STATUS` back to the requester.

On a control-window hit, the generated interconnect asserts `HSEL_CONTROL`,
drives `HADDR_CONTROL = HADDR - 4`, and muxes `HREADYOUT_CONTROL`,
`HRDATA_CONTROL`, and one-bit `HRESP_CONTROL` back to the requester.

Unselected subordinate selects are zero and unselected local addresses are
zero. Unmapped active transfers still produce the interconnect-owned two-cycle
ERROR response:

```text
cycle 1: HREADY = 0, HRESP = 2'b01, HRDATA = 0
cycle 2: HREADY = 1, HRESP = 2'b01, HRDATA = 0
```

## Reports And Residue

The report schema remains:

```text
fsmgen.ial2.protocol_intent.ahb_interconnect.v1
```

The selected topology is:

```text
one_requester_two_subordinate_static_window_interconnect
```

The report records four generated child instances, three endpoint child
instances, both subordinate bindings, both address windows, both subordinate
response mux sources, and `supported_subordinate_cardinality = 2`.

The two-subordinate `.ppif` report keeps
`ahb_aggregate_profile_alias_deferred` because matching `.ahb` alias behavior
has not shipped. It removes the old one-subordinate report's
`ahb_multi_subordinate_decode_deferred` residue and uses
`ahb_broader_interconnect_decode_deferred` for remaining AHB interconnect work
such as broader cardinality, arbitration, bus matrices, dynamic/programmed
windows, optional signals, burst continuation, byte lanes, direct backend,
verification outputs, backend-language variants, and VHDL.

## Validation

Focused validation for the slice:

```bash
prove -Iperl t/1480-ial2-ahb-interconnect-two-subordinate.t
prove -Iperl t/1478-ial2-ahb-interconnect.t
prove -Iperl t/1479-ial2-ahb-interconnect-profile-alias.t
prove -Iperl t/297-capability-manifest.t
prove -Iperl t/248-regression-corpus-accounting.t
```

The guarded `t/248` invocation was attempted through
`scripts/run_with_ram_guard.sh -- prove -Iperl t/248-regression-corpus-accounting.t`;
the guard terminated before the test because host memory was already above the
repository cutoff. The direct accounting test was then run as a lightweight
functional check and passed.
