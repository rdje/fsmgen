# IAL2 AHB Subordinate PPIF Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.715`

Date: 2026-06-29

## Outcome

FSMGen now ships the first public generated AHB subordinate behavior through
the generic `.ppif` IAL2 container:

```text
ppif/ahb_lite_subordinate.ppif
```

The source uses the explicit AHB profile and one AHB subordinate object:

```text
(profile ahb)
(ahb-subordinate ahb_lite_subordinate ...)
```

This is not a `.ahb` profile-alias source yet. The `.ahb` alias remains scoped
to the bounded requester sample `ppif/ahb_requester.ahb`.

## Source Shape

The shipped source shape is:

```text
(protocol-platform-intent ahb_lite_subordinate
  (profile ahb)
  (source
    (object fsmgen-ahb-lite-subordinate)
    (anchor
      (document ARM-AMBA-AHB-IHI0033-C-2021-09)
      (section bounded-ahb-lite-subordinate)
      (page first-public-contract)))
  (ahb-subordinate ahb_lite_subordinate
    (role subordinate)
    (clock clk)
    (reset (rst_n active_low async))
    (control
      (wait-cycles wait_cycles width 4))
    (bus
      (select HSEL)
      (ready-in HREADY)
      (address HADDR width 32)
      (transfer HTRANS width 2)
      (write HWRITE)
      (size HSIZE width 3)
      (write-data HWDATA width 32)
      (ready-out HREADYOUT)
      (response HRESP width 1)
      (read-data HRDATA width 32))
    (storage
      (register reg0
        (address 0 width 32)
        (data reg_data_q width 32 reset 0)))
    (transfer ahb_lite_access
      (accept-when (select 1) (ready-in 1))
      (idle 2'b00)
      (busy 2'b01)
      (nonseq 2'b10)
      (seq 2'b11)
      (supported-transfer nonseq)
      (ignored-transfer idle)
      (ignored-transfer busy)
      (wait-cycles wait_cycles)
      (read register)
      (write register)
      (unmapped-address error)
      (unsupported-size error)
      (unsupported-transfer error)
      (response (okay 1'b0) (error 1'b1))
      (error-completion two-cycle))))
```

The implementation is deliberately narrow. It requires one
`(ahb-subordinate ...)` object under `(profile ahb)`, role `subordinate`, an
active-low async reset, 32-bit address/write-data/read-data bindings, a 2-bit
`HTRANS`, a 3-bit `HSIZE`, a 4-bit `wait_cycles` control input, a one-bit
AHB-Lite/common-AHB `HRESP`, and exactly one 32-bit address-0 register with
reset value 0.

## Lowering And Reports

The AHB subordinate `.ppif` source lowers through the mandatory reviewable
chain:

```text
.ppif / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0 -> HDL
```

The generated review artifacts are:

```text
ahb_lite_subordinate.isf
ahb_lite_subordinate.fsm
```

The generated HDL module is:

```text
ahb_lite_subordinate
```

The IAL2 report schema is:

```text
fsmgen.ial2.protocol_intent.ahb_subordinate.v1
```

Support accounting records the sample as:

```text
entry_id: intent.ppif_ahb_lite_subordinate
coverage: ial2_ppif_ahb_lite_subordinate_pipeline_cli
source_kind: ppif
```

Check JSON and semantic JSON keep `ppif/ahb_lite_subordinate.ppif` as the
public source path while describing the generated `.fsm` semantic root.

## Output Reset And Defaults

The generated IAL1 artifact records selected reset/default metadata on public
outputs:

```text
(output HREADYOUT (reset 1) (default 1))
(output HRESP (reset 0) (default 0))
(output HRDATA (width 32) (reset 0) (default 0))
```

The generated `.fsm` carries the reset values in `+size` entries and emits
idle output default assignments in the transaction entry state:

```text
(HREADYOUT 1 (reset 1))
(HRESP 1 (reset 0))
(HRDATA 32 (reset 0))

(<- (HRDATA> 0))
(<- (HREADYOUT> 1))
(<- (HRESP> 0))
```

That behavior depends on the generated-IAL1 output default/reset substrate
shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.714`.

## Transfer Behavior

The generated subordinate starts a transaction only when:

```text
HSEL && HREADY && (HTRANS == NONSEQ || HTRANS == SEQ)
```

`IDLE` and `BUSY` are ignored by not starting the transaction; output defaults
therefore keep zero-wait OKAY:

```text
HREADYOUT = 1
HRESP     = 0
HRDATA    = 0
```

For accepted transfers, generated IAL1 samples `HADDR`, `HWRITE`, `HSIZE`,
`HTRANS`, and `wait_cycles`, drives a pending data phase with `HREADYOUT=0`,
waits the sampled count, then resolves the transfer:

- selected `NONSEQ` word writes to address `0` update `reg_data_q` from
  `HWDATA` and complete with OKAY;
- selected `NONSEQ` word reads from address `0` drive `HRDATA` from
  `reg_data_q` and complete with OKAY;
- `SEQ` is treated as unsupported burst continuation and returns ERROR;
- unsupported sizes return ERROR;
- unmapped addresses return ERROR.

ERROR completion is the selected two-cycle policy:

```text
cycle 1: HREADYOUT = 0, HRESP = 1, HRDATA = 0
cycle 2: HREADYOUT = 1, HRESP = 1, HRDATA = 0
```

The generated behavior performs no write update on ERROR.

## CLI Examples

Run a strict check without writing HDL:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ppif
```

Emit the AHB subordinate IAL2 report without writing HDL:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate.ppif
```

Emit normalized semantic JSON:

```bash
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate.ppif
```

Materialize generated review artifacts and HDL:

```bash
./bin/fsmgen --quiet --outdir /tmp/fsmgen-ahb-subordinate \
  --output /tmp/fsmgen-ahb-subordinate/ahb_lite_subordinate.sv \
  ppif/ahb_lite_subordinate.ppif
```

## Residue

The AHB subordinate report keeps these future owners explicit:

```text
ahb_subordinate_profile_alias_deferred
ahb_interconnect_generation_deferred
ahb_subordinate_optional_signal_residue
ahb_burst_seq_support_deferred
ahb_verification_output_deferred
```

This slice does not add AHB subordinate `.ahb` alias exposure, AHB
interconnect/decode, optional/property-gated AHB signals, burst `SEQ`
continuation, byte-lane or narrow-transfer behavior, legacy two-bit `HRESP`
compatibility, direct backend lowering, verification-output generation,
backend-language variants, AXI behavior, APB behavior, or VHDL behavior.

## Validation

The behavior was validated with:

```bash
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c t/1475-ial2-ahb-subordinate.t
prove -v t/1475-ial2-ahb-subordinate.t
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --outdir /tmp/fsmgen-ahb-subordinate-inspect \
  --output /tmp/fsmgen-ahb-subordinate-inspect/ahb_lite_subordinate.sv \
  ppif/ahb_lite_subordinate.ppif
```

Focused coverage in `t/1475-ial2-ahb-subordinate.t` checks the public source
shape, generated IAL1 output reset/default metadata, generated IAL0 reset and
idle defaults, selected register read/write behavior, two-cycle ERROR paths,
fail-closed diagnostics, schedule/report JSON, semantic JSON, support
accounting, and outdir artifact emission.
