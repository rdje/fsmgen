# IAL2 APB PPIF Completer Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.562`

Date: 2026-06-26

## Outcome

FSMGen now ships the first generated APB completer behavior through the
generic `.ppif` IAL2 container:

```text
ppif/apb_completer.ppif
```

The source uses the explicit APB profile and one APB completer object:

```text
(profile apb)
(apb-completer apb_completer ...)
```

This is a `.ppif` behavior, not a `.apb` profile-alias behavior. The `.apb`
suffix remains bounded to `ppif/apb_requester_transfer.apb` and still rejects
APB completer sources in this slice.

## Source Shape

The shipped source shape is:

```text
(protocol-platform-intent apb_completer
  (profile apb)
  (source
    (object fsmgen-apb-completer)
    (anchor
      (document FSMGEN-APB-REQUESTER-CAPTURE-WORKSHEET)
      (section completer-model)
      (page stage-1)))
  (apb-completer apb_completer
    (role completer)
    (clock clk)
    (reset (rst_n active_low async))
    (control
      (wait-cycles wait_cycles width 4))
    (bus
      (select PSEL)
      (enable PENABLE)
      (write PWRITE)
      (address PADDR width 32)
      (write-data PWDATA width 32)
      (ready PREADY)
      (read-data PRDATA width 32)
      (error PSLVERR))
    (storage
      (register reg0
        (address 0 width 32)
        (data reg_data_q width 32 reset 0)))
    (transfer apb_complete
      (setup-detect (select 1) (enable 0))
      (wait-cycles wait_cycles)
      (read register)
      (write register)
      (unmapped-address error))))
```

The implementation is deliberately narrow. It requires one `(apb-completer
...)` object under `(profile apb)`, role `completer`, an active-low async
reset, 32-bit APB address/write-data/read-data bindings, a 4-bit
`wait_cycles` control input, exactly one 32-bit address-0 register with reset
value 0, setup detection `PSEL && !PENABLE`, register read/write behavior, and
`PSLVERR` for unmapped addresses.

## Lowering And Reports

The APB completer `.ppif` source lowers through the mandatory reviewable chain:

```text
.ppif / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0 -> HDL
```

The generated review artifacts are:

```text
apb_completer.isf
apb_completer.fsm
```

The generated HDL module is:

```text
apb_completer
```

The IAL2 report schema is:

```text
fsmgen.ial2.protocol_intent.apb_completer.v1
```

Support accounting records the sample as:

```text
entry_id: intent.ppif_apb_completer
coverage: ial2_ppif_apb_completer_pipeline_cli
source_kind: ppif
```

Check JSON and semantic JSON keep `ppif/apb_completer.ppif` as the public
source path while describing the generated `.fsm` semantic root.

The generated IAL1 transaction uses an internal storage bit named
`apb_complete_done_q` as the terminal completion pulse target. That bit is not
a public APB port; it makes the generated transaction return to idle while the
public APB interface remains `PSEL`, `PENABLE`, `PWRITE`, `PADDR`, `PWDATA`,
`wait_cycles`, `PREADY`, `PRDATA`, and `PSLVERR`.

## CLI Examples

Emit the APB completer IAL2 report without writing HDL:

```bash
./bin/fsmgen --emit-schedule-json ppif/apb_completer.ppif
```

Run a strict check without writing HDL:

```bash
./bin/fsmgen --strict --check --json ppif/apb_completer.ppif
```

Emit normalized semantic JSON:

```bash
./bin/fsmgen --strict --emit-semantic-json ppif/apb_completer.ppif
```

Materialize generated review artifacts and HDL:

```bash
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-completer \
  --output /tmp/fsmgen-apb-completer/apb_completer.sv \
  ppif/apb_completer.ppif
```

The `.apb` suffix remains requester-transfer only:

```bash
./bin/fsmgen --strict --check --json /tmp/apb_completer.apb
```

That path rejects APB completer content with a profile-alias boundary
diagnostic.

## Residue

The APB completer report keeps these future APB owners explicit:

```text
apb_interconnect_multi_peripheral_decode_deferred
apb_profile_alias_completer_deferred
apb_profile_alias_composition_deferred
apb_multi_register_decode_deferred
apb_protection_and_strobes_deferred
apb_alternate_widths_deferred
apb_back_to_back_policy_deferred
```

The existing hand-authored lower-layer fixture `fsm/apb_completer.fsm` remains
a supported direct IAL0 APB completer fixture. The generated `.ppif` completer
path is a reviewable IAL2-to-IAL1-to-IAL0 implementation of the bounded public
contract above; it is not a promise that generated text is byte-identical to
the hand-authored fixture.

## Non-Goals

This `.562` slice does not add multi-peripheral APB interconnect/decode
generation, does not widen `.apb` beyond requester-transfer, does not add
sidebands, alternate widths, multiple register decode, byte lanes,
back-to-back policy, direct IAL2-to-IAL0 lowering, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, or
VHDL behavior. The later fixed one-requester/one-completer APB composition
behavior is documented separately.

## Validation

The behavior was validated with:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c t/1471-ial2-apb-completer.t
perl -Iperl -c t/248-regression-corpus-accounting.t
prove -Iperl t/1471-ial2-apb-completer.t
prove -Iperl t/248-regression-corpus-accounting.t
```

The final `.562` closeout also reruns the repository doctrine gates.

## Rollback

Rollback of `.562` removes `ppif/apb_completer.ppif`, the APB completer
generator and parser dispatch, the support-accounting entry, focused tests,
this behavior record, its Knowledge Map fact card, and the README/ROADMAP/
mdBook/task-tree/memory updates. The APB requester-transfer `.ppif` and `.apb`
behaviors remain owned by their earlier slices.
