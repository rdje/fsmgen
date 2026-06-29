# IAL2 AHB Interconnect/Decode Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.723`

Date: 2026-06-29

## Outcome

FSMGen now ships the selected bounded public AHB interconnect/decode behavior
through the generic `.ppif` IAL2 container:

```text
ppif/ahb_interconnect.ppif
```

The source uses explicit AHB profile selection and embeds all selected objects
in one authored source:

```text
(profile ahb)
(ahb-requester amba_requester ...)
(ahb-subordinate ahb_lite_subordinate ...)
(ahb-interconnect ahb_tb ...)
```

This is the first public aggregate AHB IAL2 source. It is not an aggregate
`.ahb` alias, not a multi-subordinate fabric, not a multiple-manager arbiter,
not a bus matrix, and not a direct IAL2-to-IAL0 or IAL2-to-HDL path.

## Source Shape

The shipped interconnect object has exactly one requester child, one
subordinate child, one static address-map window, one decode block, and one
wiring block:

```text
(ahb-interconnect ahb_tb
  (role interconnect)
  (clock clk)
  (reset (rst_n active_low async))
  (children
    (requester requester amba_requester)
    (subordinate regs ahb_lite_subordinate))
  (address-map ahb_decode
    (window regs
      (base REG_BASE width 32 default 0)
      (size REG_SIZE width 32 default 4)))
  (decode
    (overlap reject)
    (priority source-order)
    (unmapped-address error))
  (wiring ahb_bus
    (grant HGRANT)
    (request HBUSREQ)
    (ready HREADY)
    (response HRESP width 2)
    (read-data HRDATA width 32)
    (address HADDR width 32)
    (transfer HTRANS width 2)
    (write HWRITE)
    (size HSIZE width 3)
    (burst HBURST width 3)
    (protection HPROT width 4)
    (lock HLOCK)
    (write-data HWDATA width 32)
    (subordinate-select HSEL_REGS)
    (subordinate-ready-out HREADYOUT_REGS)
    (subordinate-response HRESP_REGS width 1)
    (subordinate-read-data HRDATA_REGS width 32)))
```

The embedded requester and subordinate are the same selected public endpoint
objects used by `ppif/ahb_requester.ppif` and
`ppif/ahb_lite_subordinate.ppif`, with the subordinate's bus-facing names
bound to the decoded interconnect names (`HSEL_REGS`, `HADDR_REGS`,
`HREADYOUT_REGS`, `HRESP_REGS`, and `HRDATA_REGS`).

## Lowering And Reports

The interconnect source lowers through the mandatory reviewable chain:

```text
.ppif / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0 -> HDL
```

Generated IAL1 review artifacts:

```text
amba_requester.isf
ahb_lite_subordinate.isf
ahb_interconnect.isf
```

Generated IAL0 review artifacts:

```text
amba_requester.fsm
ahb_lite_subordinate.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

The generated HDL entry is:

```text
ahb_tb
```

The IAL2 report schema is:

```text
fsmgen.ial2.protocol_intent.ahb_interconnect.v1
```

Support accounting records the sample as:

```text
entry_id: intent.ppif_ahb_interconnect
coverage: ial2_ppif_ahb_interconnect_pipeline_cli
source_kind: ppif
```

Check JSON reports module `ahb_tb`, `composition_child_count: 3`, and the
support-accounting identity above. Semantic JSON keeps the public source path
and reports the generated composition root as a `top`.

## Decode And Response Behavior

The generated interconnect uses one static window:

```text
REG_BASE = 0
REG_SIZE = 4
```

The selected hit policy is:

```text
active_transfer = HTRANS != 2'b00
hit_regs = active_transfer && HADDR >= REG_BASE && HADDR < REG_BASE + REG_SIZE
```

On a hit, the generated interconnect:

- drives `HSEL_REGS=1`;
- drives local subordinate address `HADDR_REGS = HADDR - REG_BASE`;
- drives requester/global `HREADY = HREADYOUT_REGS`;
- drives requester `HRDATA = HRDATA_REGS`;
- maps subordinate `HRESP_REGS=0` to requester `HRESP=2'b00`; and
- maps subordinate `HRESP_REGS=1` to requester `HRESP=2'b01`.

On inactive/no-transfer cycles, the generated defaults are:

```text
HGRANT     = 1
HREADY     = 1
HRESP      = 2'b00
HRDATA     = 0
HSEL_REGS  = 0
HADDR_REGS = 0
```

On an unmapped active transfer, the interconnect owns a two-cycle ERROR:

```text
cycle 1: HREADY = 0, HRESP = 2'b01, HRDATA = 0
cycle 2: HREADY = 1, HRESP = 2'b01, HRDATA = 0
```

The interconnect never generates RETRY or SPLIT. The single-requester grant
policy is fixed:

```text
HGRANT = 1
```

## Aggregate Top

The generated aggregate top is `ahb_tb.fsm`. It instantiates:

```text
requester     amba_requester
interconnect  ahb_interconnect
regs          ahb_lite_subordinate
```

The top wires requester AHB drive signals into the interconnect, interconnect
grant/ready/response/read-data back to the requester, interconnect global
`HREADY` and decoded select/address into the subordinate, requester
transfer/write/size/write-data signals into the subordinate, and subordinate
ready/response/read-data signals back into the interconnect.

## Diagnostics

Malformed interconnect sources fail closed. Focused coverage verifies
diagnostics for:

- non-AHB profile under an interconnect source;
- missing required requester or subordinate child references;
- address-map windows that do not match the subordinate child instance;
- subordinate response width other than the selected one-bit `HRESP_REGS`; and
- aggregate `.ahb` interconnect aliases.

The aggregate `.ahb` rejection preserves the shipped endpoint-alias boundary:
`.ahb` currently accepts exactly one bounded requester endpoint or one bounded
subordinate endpoint, not an aggregate interconnect source.

## Residue

The shipped interconnect report keeps these future owners explicit:

```text
ahb_aggregate_profile_alias_deferred
ahb_multi_subordinate_decode_deferred
ahb_multi_requester_arbitration_deferred
ahb_bus_matrix_deferred
ahb_optional_signal_residue
ahb_burst_seq_support_deferred
ahb_verification_output_deferred
```

AHB completer behavior, aggregate `.ahb` aliases, multi-subordinate fabrics,
multiple managers, bus matrices, programmable/multiple windows, optional AHB
signals, burst `SEQ` continuation, byte-lane or narrow-transfer behavior,
legacy two-bit subordinate `HRESP`, direct backend lowering, verification
output generation, backend-language variants, AXI behavior, APB behavior, and
VHDL behavior remain future work.

## Validation

The behavior was validated with:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c t/1478-ial2-ahb-interconnect.t
prove -Iperl t/1478-ial2-ahb-interconnect.t
prove -Iperl t/1473-ial2-ahb-requester.t t/1475-ial2-ahb-subordinate.t t/1477-ial2-ahb-subordinate-profile-alias.t
prove -Iperl t/297-capability-manifest.t
scripts/run_with_ram_guard.sh prove -Iperl t/248-regression-corpus-accounting.t
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ppif
```

Focused coverage in `t/1478-ial2-ahb-interconnect.t` checks the public source
shape, generated IAL1/IAL0 artifact names, interconnect decode and response
mapping, aggregate top wiring, schedule/check/semantic JSON, support
accounting, fail-closed diagnostics, and outdir artifact emission.
