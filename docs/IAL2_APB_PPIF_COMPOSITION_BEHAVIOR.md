# IAL2 APB PPIF Composition Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.566`

Date: 2026-06-26

## Outcome

FSMGen now ships the first generated APB requester/completer composition
through the generic `.ppif` IAL2 container:

```text
ppif/apb_composition.ppif
```

The source uses the explicit APB profile, one APB requester object, one APB
completer object, and one explicit APB composition object:

```text
(profile apb)
(apb-requester apb_requester ...)
(apb-completer apb_completer ...)
(apb-composition apb_tb ...)
```

This is a fixed one-requester/one-completer composition behavior. It is not a
multi-peripheral APB interconnect/decode behavior. The later `.569`
alias-widening slice also exposes the same bounded fixed composition through:

```text
ppif/apb_composition.apb
```

## Source Shape

The shipped source shape is:

```text
(protocol-platform-intent apb_composition
  (profile apb)
  (source
    (object fsmgen-apb-composition)
    (anchor
      (document FSMGEN-APB-REQUESTER-CAPTURE-WORKSHEET)
      (section requester-completer-composition)
      (page stage-1)))
  (apb-requester apb_requester
    ...)
  (apb-completer apb_completer
    ...)
  (apb-composition apb_tb
    (role composition)
    (clock clk)
    (reset (rst_n active_low async))
    (children
      (requester apb_requester)
      (completer apb_completer))
    (wiring
      (requester-to-completer apb)
      (control wait_cycles))))
```

The implementation is deliberately narrow. It requires explicit `(profile apb)`,
exactly one requester object, exactly one completer object, and exactly one
composition object. The requester and completer share the same `clk` and
active-low async `rst_n`, the APB address/write/read data widths are 32 bits,
and `wait_cycles` is a 4-bit control input to the completer.

## Lowering And Reports

The APB composition `.ppif` source lowers through the mandatory reviewable
chain:

```text
.ppif / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0 -> HDL
```

The generated review artifacts are:

```text
apb_requester.isf
apb_completer.isf
apb_requester.fsm
apb_completer.fsm
apb_tb.fsm
```

The selected HDL entry is:

```text
apb_tb.fsm
```

The generated HDL modules include:

```text
apb_tb
apb_requester
apb_completer
```

The generated top interface is:

```text
input  clk
input  rst_n
input  start
input  req_write
input  req_addr[31:0]
input  req_wdata[31:0]
input  wait_cycles[3:0]
output done
output last_error
output last_read_data[31:0]
```

Requester `busy` is not exposed by the shipped composition top. The public
requester response contract exposes `done`, `error`, and `read_data`, and this
composition mirrors those response values as `done`, `last_error`, and
`last_read_data`.

The APB bus wiring is explicit:

- requester outputs `PSEL`, `PENABLE`, `PWRITE`, `PADDR`, and `PWDATA` drive
  the completer;
- completer outputs `PREADY`, `PRDATA`, and `PSLVERR` drive the requester;
- top-level `start`, `req_write`, `req_addr`, and `req_wdata` drive the
  requester;
- top-level `wait_cycles` drives the completer; and
- top-level response outputs come from the requester.

The IAL2 report schema is:

```text
fsmgen.ial2.protocol_intent.apb_composition.v1
```

Support accounting records the sample as:

```text
entry_id: intent.ppif_apb_composition
coverage: ial2_ppif_apb_composition_pipeline_cli
source_kind: ppif
expected_top_name: apb_tb
expected_child_modules: [apb_requester, apb_completer]
expected_semantic_source_root_kind: top
```

Check JSON and semantic JSON keep `ppif/apb_composition.ppif` as the public
source path. The normalized semantic root kind is `top` because the generated
composition artifact is an IAL0 `?top` root.

## CLI Examples

Emit the APB composition IAL2 report without writing HDL:

```bash
./bin/fsmgen --emit-schedule-json ppif/apb_composition.ppif
```

Run a strict check without writing HDL:

```bash
./bin/fsmgen --strict --check --json ppif/apb_composition.ppif
```

Emit normalized semantic JSON:

```bash
./bin/fsmgen --strict --emit-semantic-json ppif/apb_composition.ppif
```

Materialize generated review artifacts and HDL:

```bash
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-composition \
  --output /tmp/fsmgen-apb-composition/apb_tb.sv \
  ppif/apb_composition.ppif
```

Without `--outdir`, the CLI lowers from the selected `apb_tb.fsm` entry and
does not write the generated review artifacts into the repository root. With
`--outdir`, it writes all generated `.isf` and `.fsm` review artifacts before
the HDL output.

The `.apb` profile alias now mirrors this bounded fixed composition source:

```bash
./bin/fsmgen --strict --check --json ppif/apb_composition.apb
```

The alias preserves the authored `.apb` public source path, support-accounts as
`intent.apb_profile_alias_composition`, and lowers through the same generated
`apb_requester.isf`, `apb_completer.isf`, `apb_requester.fsm`,
`apb_completer.fsm`, and `apb_tb.fsm` review artifacts.

## Residue

The APB composition report keeps these future APB owners explicit:

```text
apb_interconnect_multi_peripheral_decode_deferred
apb_requester_busy_status_deferred
apb_multi_register_decode_deferred
apb_protection_and_strobes_deferred
apb_alternate_widths_deferred
apb_back_to_back_policy_deferred
```

The APB requester-transfer and completer reports keep requester busy/status,
multi-register decode, sidebands/strobes, alternate widths, back-to-back
policy, and multi-peripheral interconnect/decode separate from the shipped
fixed composition behavior.

## Non-Goals

This `.566` slice does not add a multi-peripheral APB interconnect/decode
surface, does not expose a requester `busy` status, does not add sidebands,
strobes, alternate widths, multiple register decode, byte lanes, back-to-back
policy, direct IAL2-to-IAL0 lowering, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, or
VHDL behavior. The later `.569` slice documents the matching `.apb` alias
exposure.

## Validation

The behavior was validated with:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -c bin/fsmgen
perl -Iperl -c t/1472-ial2-apb-composition.t
prove -Iperl t/1472-ial2-apb-composition.t
prove -Iperl t/1471-ial2-apb-completer.t
prove -Iperl t/1470-ial2-apb-profile-alias.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
./bin/fsmgen --quiet --strict --check --json ppif/apb_composition.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_composition.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition.ppif
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-composition-closeout-r2 \
  --output /tmp/fsmgen-apb-composition-closeout-r2/apb_tb.sv \
  ppif/apb_composition.ppif
```

The final `.566` closeout also reruns the repository doctrine gates.

## Rollback

Rollback of `.566` removes `ppif/apb_composition.ppif`, the APB composition
generator and parser dispatch, multi-artifact PPIF CLI selection support, the
support-accounting entry, focused tests, this behavior record, its Knowledge
Map fact card, and the README/ROADMAP/mdBook/task-tree/memory updates.
Rollback of `.569` separately removes `ppif/apb_composition.apb` and the alias
support-accounting entry. The APB requester-transfer `.ppif`/`.apb` and APB
completer `.ppif`/`.apb` behaviors remain owned by their respective slices.
