# IAL2 APB PPIF Requester-Transfer Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.550`

Date: 2026-06-26

## Outcome

FSMGen now ships the first APB IAL2 source-shape behavior through the generic
`.ppif` container:

```text
ppif/apb_requester_transfer.ppif
```

The source uses the explicit APB profile and one APB requester object:

```text
(profile apb)
(apb-requester apb_requester ...)
```

In this `.550` slice, APB was not exposed through a `.apb` suffix and `.apb`
remained a known unsupported alias candidate. The later `.554` slice ships the
bounded `.apb` profile alias at `ppif/apb_requester_transfer.apb`; this page
continues to describe the generic `.ppif` APB source shape. APB is also not an
AXI behavior: AXI is only the first profile-alias example, while this slice
proves the same `.ppif` IAL2 container can carry a non-AXI protocol profile.

## Source Shape

The shipped source shape is:

```text
(protocol-platform-intent apb_requester_transfer
  (profile apb)
  (source
    (object fsmgen-apb-requester-transfer)
    (anchor
      (document FSMGEN-APB-REQUESTER-CAPTURE-WORKSHEET)
      (section transfer-protocol)
      (page stage-1)))
  (apb-requester apb_requester
    (role requester)
    (clock clk)
    (reset (rst_n active_low async))
    (request
      (start start)
      (write req_write)
      (address req_addr width 32)
      (write-data req_wdata width 32))
    (response
      (done done)
      (read-data last_read_data width 32)
      (error last_error))
    (bus
      (address PADDR width 32)
      (write PWRITE)
      (write-data PWDATA width 32)
      (select PSEL)
      (enable PENABLE)
      (ready PREADY)
      (read-data PRDATA width 32)
      (error PSLVERR))
    (transfer apb_transfer
      (setup (select 1) (enable 0))
      (access (select 1) (enable 1))
      (complete-on ready)
      (sample read-data error)
      (latency (min 2) (max 16)))))
```

The first implementation is deliberately narrow. It requires one
`(apb-requester ...)` object under `(profile apb)`, role `requester`, 32-bit
address/write-data/read-data bindings, setup `PSEL=1/PENABLE=0`, access
`PSEL=1/PENABLE=1`, completion on `PREADY`, sampling of `PRDATA` and
`PSLVERR`, and latency `(min 2) (max 16)`.

## Lowering And Reports

The APB `.ppif` source lowers through the mandatory reviewable chain:

```text
.ppif / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0 -> HDL
```

The generated review artifacts are:

```text
apb_requester.isf
apb_requester.fsm
```

The generated HDL module is:

```text
apb_requester
```

The IAL2 report schema is:

```text
fsmgen.ial2.protocol_intent.apb_requester_transfer.v1
```

Support accounting records the sample as:

```text
entry_id: intent.ppif_apb_requester_transfer
coverage: ial2_ppif_apb_requester_transfer_pipeline_cli
source_kind: ppif
```

Check JSON and semantic JSON keep `ppif/apb_requester_transfer.ppif` as the
public source path while describing the generated `.fsm` semantic root.

## CLI Examples

Emit the APB IAL2 report without writing HDL:

```bash
./bin/fsmgen --emit-schedule-json ppif/apb_requester_transfer.ppif
```

Run a strict check without writing HDL:

```bash
./bin/fsmgen --strict --check --json ppif/apb_requester_transfer.ppif
```

Emit normalized semantic JSON:

```bash
./bin/fsmgen --strict --emit-semantic-json ppif/apb_requester_transfer.ppif
```

Materialize generated review artifacts and HDL:

```bash
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-ppif \
  --output /tmp/fsmgen-apb-ppif/apb_requester.sv \
  ppif/apb_requester_transfer.ppif
```

At `.550` closeout, the `.apb` suffix was still rejected even when the file
contents matched the APB `.ppif` sample:

```bash
./bin/fsmgen --strict --check --json /tmp/apb_requester_transfer.apb
```

That reported `source suffix '.apb' is a known IAL2 alias candidate but is not
supported in this slice`. Current `.apb` behavior is documented in
[IAL2_APB_PROFILE_ALIAS_BEHAVIOR](IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md).

## Residue

The APB requester-transfer report keeps these future APB owners explicit:

```text
apb_multi_peripheral_decode_deferred
apb_protection_and_strobes_deferred
apb_completer_and_interconnect_generation_deferred
apb_alternate_widths_deferred
apb_back_to_back_policy_deferred
```

## Non-Goals

This `.550` slice did not accept `.apb` or any other new suffix, did not extend
`.axi`, did not add APB completer or interconnect generation, did not add
verification-output behavior, did not add direct IAL2-to-backend lowering, and
did not change VHDL behavior.

## Validation

The behavior was validated with:

```bash
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm
perl -c t/1436-ial2-ppif-parser-cli.t
./bin/fsmgen --emit-schedule-json ppif/apb_requester_transfer.ppif
./bin/fsmgen --strict --check --json ppif/apb_requester_transfer.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/apb_requester_transfer.ppif
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-ppif-r1 \
  --output /tmp/fsmgen-apb-ppif-r1/apb_requester.sv \
  ppif/apb_requester_transfer.ppif
./bin/fsmgen --strict --check --json /tmp/fsmgen-apb-ppif-r1/apb_requester_transfer.apb
prove -Iperl t/1091-isf-parser-apb-requester.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
```

The broad `t/1436-ial2-ppif-parser-cli.t` file was also attempted. A normal
PATH run reached an unrelated existing AXI `--verify-hdl` Verilator
warning-as-error case, and a reduced-path run was stopped while spending
minutes in an existing AXI dynamic check case. The APB path itself passed the
direct parser/CLI/report/support-accounting/suffix checks above.

## Rollback

Rollback of `.550` removes `ppif/apb_requester_transfer.ppif`, the APB
requester-transfer generator and parser dispatch, the support-accounting entry,
the focused tests, this behavior record, its Knowledge Map fact card, and the
README/ROADMAP/mdBook task-tree/memory updates. `.apb` support is owned by the
later `.554` slice.
