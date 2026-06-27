# IAL2 APB Multi-Register Decode Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.581`

Date: 2026-06-27

## Outcome

FSMGen now ships bounded APB multi-register completer decode through additive
standalone completer and status-capable fixed-composition sources:

```text
ppif/apb_completer_multi_register.ppif
ppif/apb_completer_multi_register.apb
ppif/apb_composition_multi_register.ppif
ppif/apb_composition_multi_register.apb
```

Existing one-register APB completer and composition sources remain unchanged.

Update `.594`: sideband-aware data16 variants add 16-bit data and 2-byte
alignment without changing the existing 32-bit multi-register samples:

```text
ppif/apb_completer_multi_register_sideband_data16.ppif
ppif/apb_completer_multi_register_sideband_data16.apb
ppif/apb_composition_multi_register_sideband_data16.ppif
ppif/apb_composition_multi_register_sideband_data16.apb
```

Update `.597`: sideband-aware 32-bit protection variants add register-local
`access-policy` enforcement without changing existing unprotected
multi-register samples:

```text
ppif/apb_completer_multi_register_sideband_protection.ppif
ppif/apb_completer_multi_register_sideband_protection.apb
ppif/apb_composition_multi_register_sideband_protection.ppif
ppif/apb_composition_multi_register_sideband_protection.apb
```

## Source Shape

The selected syntax is repeated `(register ...)` clauses under the existing
APB completer `(storage ...)` block:

```lisp
(storage
  (register reg0
    (address 0 width 32)
    (data reg0_data_q width 32 reset 0))
  (register reg1
    (address 4 width 32)
    (data reg1_data_q width 32 reset 0)))
```

The first bounded slice requires source-order registers, unique register
names, unique data signal names, unique decimal addresses, address width 32,
4-byte address alignment, register data width 32, and reset value 0. Read and
write transfer policy remains `(read register)`, `(write register)`, and
`(unmapped-address error)`.

For `.594` data16 sideband variants, register data width is 16, `PSTRB` width
is 2, and decoded register addresses are 2-byte aligned. The shipped data16
samples map address `0` to `reg0_data_q` and address `2` to `reg1_data_q`.

For `.597` protection variants, each selected 32-bit sideband-aware register may
carry an `(access-policy ...)` block. The first policy predicate is
`(privileged 0|1)`, which maps to sampled `PPROT[0]`.

## Generated Behavior

Generated completer IAL1 samples `PADDR`, `PWRITE`, `PWDATA`, and
`wait_cycles` during APB setup (`PSEL && !PENABLE`) as before. After the
sampled wait count completes:

- a mapped write updates only the selected decoded register and drives
  `PREADY=1`, `PRDATA=0`, `PSLVERR=0`;
- a mapped read drives `PREADY=1`, `PRDATA=<selected register>`, `PSLVERR=0`;
- an unmapped read or write drives `PREADY=1`, `PRDATA=0`, `PSLVERR=1`.

For the shipped two-register samples, address `0` maps to `reg0_data_q` and
address `4` maps to `reg1_data_q`.

## Reports And Support

One-register reports keep the historical shape:

```text
bindings.storage.register
transfer.register
```

Multi-register reports use additive source-order lists:

```text
bindings.storage.registers[]
transfer.registers[]
```

The new support-accounting identities are:

```text
intent.ppif_apb_completer_multi_register
intent.apb_profile_alias_completer_multi_register
intent.ppif_apb_composition_multi_register
intent.apb_profile_alias_composition_multi_register
```

The completer and composition report schemas remain:

```text
fsmgen.ial2.protocol_intent.apb_completer.v1
fsmgen.ial2.protocol_intent.apb_composition.v1
```

Multi-register completer and multi-register composition reports remove
`apb_multi_register_decode_deferred`. They continue to leave multi-peripheral
APB interconnect/decode, sidebands/strobes, alternate widths, and
back-to-back policy as explicit future owners.

The data16 sideband reports add `width_policy` metadata and replace the broad
`apb_alternate_widths_deferred` residue with
`apb_remaining_widths_deferred`. See
[IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR](IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR.md).

The protection sideband reports add `protection_policy` metadata and replace
`apb_protection_policy_effects_deferred` with
`apb_additional_protection_policies_deferred`. See
[IAL2_APB_PPROT_EFFECTS_BEHAVIOR](IAL2_APB_PPROT_EFFECTS_BEHAVIOR.md).

## CLI Examples

Emit schedule JSON for the standalone multi-register completer:

```bash
./bin/fsmgen --emit-schedule-json ppif/apb_completer_multi_register.ppif
```

Check the `.apb` profile-alias mirror:

```bash
./bin/fsmgen --strict --check --json ppif/apb_completer_multi_register.apb
```

Generate review artifacts and HDL for the multi-register composition:

```bash
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-composition-multi-register \
  --output /tmp/fsmgen-apb-composition-multi-register/apb_tb.sv \
  ppif/apb_composition_multi_register.ppif
```

## Non-Goals

This slice does not add side effects, byte lanes, `PPROT`, `PSTRB`, APB4/APB5
sidebands, register arrays, alternate APB widths, multi-peripheral topology,
back-to-back transfer admission, direct backend lowering, verification-output
generation, backend-language variants, AXI behavior, VHDL behavior, or changes
to the existing one-register APB samples.

## Validation

The behavior is covered by focused parser, generator, CLI, report,
support-accounting, and manifest tests:

```bash
prove -Iperl t/1470-ial2-apb-profile-alias.t \
  t/1471-ial2-apb-completer.t \
  t/1472-ial2-apb-composition.t \
  t/248-regression-corpus-accounting.t \
  t/297-capability-manifest.t
```

Direct schedule/check/semantic/outdir probes cover the four new public
samples and preservation probes cover the existing one-register APB samples.

## Rollback

Rollback of `.581` removes the four multi-register APB sample files, the
multi-register parser/generator/report support, the four support-accounting
entries, focused tests, this behavior record, its Knowledge Map fact card, and
the README/ROADMAP/mdBook/task-tree/memory updates. The pre-existing APB
requester, one-register completer, fixed composition, busy/status, and `.apb`
alias samples remain owned by their earlier slices.
