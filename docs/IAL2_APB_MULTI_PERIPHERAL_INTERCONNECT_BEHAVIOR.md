# IAL2 APB Multi-Peripheral Interconnect/Decode Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.585`

Date: 2026-06-27

## Outcome

FSMGen now ships bounded APB multi-peripheral interconnect/decode for generated
APB composition sources:

```text
ppif/apb_composition_multi_peripheral.ppif
ppif/apb_composition_multi_peripheral.apb
```

The new sources preserve the existing APB composition report schema and lower
through generated IAL1 review artifacts before generated IAL0 FSM artifacts.
Existing one-requester/one-completer APB composition, busy/status, and
multi-register APB samples remain unchanged.

## Source Shape

The shipped public source remains an `(apb-composition ...)` object. The
multi-peripheral form uses one requester child, two or more peripheral
children, a static address map, and a closed decode policy:

```lisp
(children
  (requester requester apb_requester)
  (peripheral status apb_status_regs)
  (peripheral control apb_control_regs))
(address-map apb_decode
  (window status
    (base STATUS_BASE width 32 default 0)
    (size STATUS_SIZE width 32 default 256))
  (window control
    (base CONTROL_BASE width 32 default 256)
    (size CONTROL_SIZE width 32 default 256)))
(decode
  (overlap reject)
  (priority source-order)
  (unmapped-address error))
```

Each peripheral object must be an embedded APB completer. Each address-map
window name must match one peripheral instance. Base and size defaults are
static decimal values, width 32, 4-byte aligned, non-overlapping, and within
the 32-bit address space. The fixed `(completer INSTANCE OBJECT)` child form
remains the one-requester/one-completer composition shape and cannot be mixed
with `(peripheral ...)` children.

## Generated Behavior

The generated composition emits:

```text
apb_requester.isf
apb_status_regs.isf
apb_control_regs.isf
apb_interconnect.isf
apb_requester.fsm
apb_status_regs.fsm
apb_control_regs.fsm
apb_interconnect.fsm
apb_tb.fsm
```

`apb_interconnect.fsm` fans out requester control/data to each peripheral-side
APB bus, decodes `PSEL && PADDR` against the static windows, forwards only the
selected peripheral `PSEL`, translates local peripheral address as
`PADDR - base`, muxes selected `PREADY`/`PRDATA`/`PSLVERR` back to the
requester, and returns `PREADY=1`, `PRDATA=0`, `PSLVERR=1` for an active
unmapped access (`PSEL && PENABLE` with no matching window).

Generated top instance names are deterministic and avoid collisions with
declared top ports. In the shipped sample, the authored peripheral instance
`status` collides with the requester public `status` output, so the generated
top instantiates `(?fsmc:status_peripheral apb_status_regs)`. Reports preserve
the authored `instance_name` and expose `generated_instance_name` for audit.

## Reports And Support

The APB composition report schema remains:

```text
fsmgen.ial2.protocol_intent.apb_composition.v1
```

Multi-peripheral reports add:

```text
composition.topology = multi_peripheral_interconnect
composition.endpoint_child_instance_count
composition.generated_interconnect
composition.address_map
composition.response_mux
composition.peripherals[].generated_instance_name
children[] role interconnect
```

The new support-accounting identities are:

```text
intent.ppif_apb_composition_multi_peripheral
intent.apb_profile_alias_composition_multi_peripheral
```

The new coverage buckets are:

```text
ial2_ppif_apb_composition_multi_peripheral_pipeline_cli
ial2_apb_profile_alias_composition_multi_peripheral_pipeline_cli
```

The multi-peripheral composition report removes
`apb_interconnect_multi_peripheral_decode_deferred`. APB sidebands/strobes,
alternate widths, and back-to-back policy remain explicit residue.

## CLI Examples

Emit schedule JSON for the `.ppif` source:

```bash
./bin/fsmgen --emit-schedule-json ppif/apb_composition_multi_peripheral.ppif
```

Run strict check JSON for the `.apb` profile alias:

```bash
./bin/fsmgen --strict --check --json ppif/apb_composition_multi_peripheral.apb
```

Generate review artifacts and HDL:

```bash
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-composition-multi-peripheral \
  --output /tmp/fsmgen-apb-composition-multi-peripheral/apb_tb.sv \
  ppif/apb_composition_multi_peripheral.ppif
```

## Non-Goals

This slice does not add APB side effects, byte lanes, `PPROT`, `PSTRB`,
APB4/APB5 sidebands, alternate address/data widths, back-to-back transfer
admission, multiple requesters, bus matrices, scoreboards, queues, direct
IAL2-to-IAL0 lowering, direct backend lowering, verification-output
generation, backend-language variants, AXI interconnect, AHB interconnect, or
VHDL behavior.

## Validation

Focused validation for the behavior passed:

```bash
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c t/1470-ial2-apb-profile-alias.t
perl -Iperl -c t/1472-ial2-apb-composition.t
prove -Iperl t/1470-ial2-apb-profile-alias.t
prove -Iperl t/1472-ial2-apb-composition.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
```

Direct probes passed for schedule JSON, strict check JSON, semantic JSON, and
outdir/HDL generation on the new `.ppif` and `.apb` sources.

## Rollback

Rollback of `.585` removes the two multi-peripheral APB sample files, parser
support for `(peripheral ...)`, `(address-map ...)`, and `(decode ...)` in APB
composition sources, the generated APB interconnect path, the two
support-accounting entries, focused tests, this behavior record, its Knowledge
Map fact card, and the README/ROADMAP/mdBook/task-tree/memory updates. Earlier
APB requester, completer, fixed composition, busy/status, multi-register, and
profile-alias behavior remains owned by previous slices.
