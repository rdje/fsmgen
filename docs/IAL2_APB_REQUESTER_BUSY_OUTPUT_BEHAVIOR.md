# IAL2 APB Requester Busy Output Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.572`

Date: 2026-06-27

## Outcome

FSMGen now ships additive busy-capable APB requester-transfer and fixed
requester/completer composition IAL2 samples:

```text
ppif/apb_requester_transfer_busy.ppif
ppif/apb_requester_transfer_busy.apb
ppif/apb_composition_busy.ppif
ppif/apb_composition_busy.apb
```

The older no-busy APB requester-transfer and fixed-composition samples remain
unchanged. They still expose `done`, `last_error`, and `last_read_data`, and
they still report `apb_requester_busy_status_deferred`.

## Source Shape

Busy is selected by adding an optional one-bit response binding to the APB
requester response block:

```text
(response
  (busy busy)
  (done done)
  (read-data last_read_data width 32)
  (error last_error))
```

The rest of the requester contract remains the existing bounded APB shape:
explicit `(profile apb)`, role `requester`, 32-bit address/write/read data,
setup `PSEL=1/PENABLE=0`, access `PSEL=1/PENABLE=1`, completion on `PREADY`,
sampling of `PRDATA` and `PSLVERR`, and latency `(min 2) (max 16)`.

The first busy composition is still the fixed one-requester/one-completer
shape. It propagates the embedded requester `busy` output to the generated
`apb_tb` top.

## Lowering And Semantics

The busy requester-transfer samples lower through:

```text
.ppif/.apb -> generated apb_requester.isf -> generated apb_requester.fsm -> HDL
```

The generated requester HDL module is `apb_requester` and exposes:

```text
busy
done
last_error
last_read_data[31:0]
```

The busy composition samples lower through generated endpoint review artifacts
plus the generated top:

```text
apb_requester.isf
apb_completer.isf
apb_requester.fsm
apb_completer.fsm
apb_tb.fsm
```

The selected HDL entry is `apb_tb.fsm`, and generated HDL includes modules
`apb_tb`, `apb_requester`, and `apb_completer`. The top-level composition
interface exposes `busy`, `done`, `last_error`, and `last_read_data[31:0]`.

`busy` is low in idle before a transfer is accepted, high during setup and
access progress after acceptance, remains high on the completion pulse cycle,
and returns low after the requester reaches idle again. The generated IAL0
review artifact makes this visible by clearing `busy` in the generated idle
state and asserting it in generated setup/access phase states.

## Support Accounting

The new support entries are:

```text
intent.ppif_apb_requester_transfer_busy
intent.apb_profile_alias_requester_transfer_busy
intent.ppif_apb_composition_busy
intent.apb_profile_alias_composition_busy
```

Their coverage buckets are:

```text
ial2_ppif_apb_requester_transfer_busy_pipeline_cli
ial2_apb_profile_alias_requester_transfer_busy_pipeline_cli
ial2_ppif_apb_composition_busy_pipeline_cli
ial2_apb_profile_alias_composition_busy_pipeline_cli
```

The `.ppif` samples use source kind `ppif`. The `.apb` samples use source kind
`ial2_profile_alias`. Check JSON and semantic JSON preserve the authored
`.ppif` or `.apb` source path.

## CLI Examples

Requester-transfer schedule, check, semantic JSON, and materialization:

```bash
./bin/fsmgen --emit-schedule-json ppif/apb_requester_transfer_busy.ppif
./bin/fsmgen --strict --check --json ppif/apb_requester_transfer_busy.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/apb_requester_transfer_busy.ppif
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-requester-busy \
  --output /tmp/fsmgen-apb-requester-busy/apb_requester_busy.sv \
  ppif/apb_requester_transfer_busy.ppif
```

Profile-alias requester-transfer:

```bash
./bin/fsmgen --emit-schedule-json ppif/apb_requester_transfer_busy.apb
./bin/fsmgen --strict --check --json ppif/apb_requester_transfer_busy.apb
./bin/fsmgen --strict --emit-semantic-json ppif/apb_requester_transfer_busy.apb
```

Busy composition:

```bash
./bin/fsmgen --emit-schedule-json ppif/apb_composition_busy.ppif
./bin/fsmgen --strict --check --json ppif/apb_composition_busy.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/apb_composition_busy.ppif
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-composition-busy \
  --output /tmp/fsmgen-apb-composition-busy/apb_tb_busy.sv \
  ppif/apb_composition_busy.ppif
```

Profile-alias busy composition:

```bash
./bin/fsmgen --emit-schedule-json ppif/apb_composition_busy.apb
./bin/fsmgen --strict --check --json ppif/apb_composition_busy.apb
./bin/fsmgen --strict --emit-semantic-json ppif/apb_composition_busy.apb
```

## Residue

Busy-capable requester-transfer reports remove
`apb_requester_busy_status_deferred` and keep:

```text
apb_requester_status_field_deferred
```

Busy-capable composition reports also remove
`apb_requester_busy_status_deferred` and keep the same named status-field
residue. Existing no-busy APB requester-transfer and composition samples keep
their previous busy/status residue.

The following APB owners remain deferred:

```text
apb_multi_peripheral_decode_deferred
apb_interconnect_multi_peripheral_decode_deferred
apb_multi_register_decode_deferred
apb_protection_and_strobes_deferred
apb_alternate_widths_deferred
apb_back_to_back_policy_deferred
```

## Diagnostics

The parser accepts optional `(busy NAME)` only in APB requester response
blocks. Unsupported `(status ...)` clauses fail closed with a diagnostic that
points to the busy-only slice and the required `done`, `read-data`, and `error`
fields. The normal generator validation continues to reject duplicate signal
names and non-identifier response bindings.

## Non-Goals

This slice does not migrate existing APB samples in place, add named status
fields, add multi-peripheral APB interconnect/decode, add multi-register
decode, add APB sidebands or strobes, add alternate widths, add back-to-back
transfer policy, add direct IAL2-to-IAL0 lowering, add direct backend lowering,
add verification-output generation, add backend-language variants, change AXI
behavior, or add VHDL behavior.

## Validation

Closeout validation covers parser/generator syntax, busy and no-busy APB
focused tests, support accounting, capability manifest alignment, direct
schedule/check/semantic/outdir probes, mdBook build, Knowledge Map
synchronization, memory checks, docs path checks, and the repository doctrine
gate.

## Rollback

Rollback of `.572` removes the four busy samples, optional APB requester
response `busy` parsing, busy output generation, fixed composition busy top
propagation, support-accounting entries, focused tests, this behavior record,
its Knowledge Map fact card, and the README/ROADMAP/mdBook/task-tree/memory
updates. Existing no-busy APB requester-transfer, completer, composition, and
`.apb` alias behavior remains owned by earlier slices.
