# IAL2 APB PPROT Access-Policy Behavior

Task-tree owners: `IAL2-FEATURE-COMPLETENESS-FRONTIER.597`,
`IAL2-FEATURE-COMPLETENESS-FRONTIER.603`

Date: 2026-06-27

## Outcome

FSMGen now ships bounded APB `PPROT` access-control behavior for
sideband-aware 32-bit and data16 multi-register APB completers and
compositions.

New support-accounted samples:

```text
ppif/apb_completer_multi_register_sideband_protection.ppif
ppif/apb_completer_multi_register_sideband_protection.apb
ppif/apb_composition_multi_register_sideband_protection.ppif
ppif/apb_composition_multi_register_sideband_protection.apb
ppif/apb_composition_multi_peripheral_sideband_protection.ppif
ppif/apb_composition_multi_peripheral_sideband_protection.apb
ppif/apb_completer_multi_register_sideband_data16_protection.ppif
ppif/apb_completer_multi_register_sideband_data16_protection.apb
ppif/apb_composition_multi_register_sideband_data16_protection.ppif
ppif/apb_composition_multi_register_sideband_data16_protection.apb
ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif
ppif/apb_composition_multi_peripheral_sideband_data16_protection.apb
```

Existing APB samples without `access-policy` remain unchanged, including the
sideband-aware data16 no-policy samples.

## Source Shape

The selected policy syntax is register-local and lives inside APB completer
storage registers:

```lisp
(storage
  (register reg0
    (address 0 width 32)
    (data reg0_data_q width 32 reset 0)
    (access-policy
      (read allow)
      (write require (privileged 1))))
  (register reg1
    (address 4 width 32)
    (data reg1_data_q width 32 reset 0)
    (access-policy
      (read require (privileged 1))
      (write require (privileged 1)))))
```

The first policy contract accepts only:

- `(read allow)` or `(read require (privileged 0|1))`;
- `(write allow)` or `(write require (privileged 0|1))`.

`privileged` is an FSMGen-local APB policy predicate. It means sampled
`PPROT[0] == VALUE`, where `PPROT` is sampled by the completer during APB setup.
No public semantics are added for `PPROT[1]`, `PPROT[2]`, secure/non-secure,
instruction/data, boolean predicates, global policies, window policies,
peripheral policies, or runtime-programmable policies.

On data16 protection samples, the same policy syntax applies to selected
2-byte-aligned registers with 16-bit data:

```lisp
(storage
  (register reg1
    (address 2 width 32)
    (data reg1_data_q width 16 reset 0)
    (access-policy
      (read require (privileged 1))
      (write require (privileged 1)))))
```

## Generated Behavior

Completer lowering evaluates the selected register's access policy after
address decode and at the existing APB response point. The wait-count timing is
unchanged.

Allowed mapped accesses keep the sideband-aware APB behavior:

- reads return the selected register and `PSLVERR=0`;
- writes update only the `PSTRB`-selected byte lanes and return `PSLVERR=0`;
- `PSTRB=0` remains a successful no-byte write when the mapped write is
  allowed.

Denied mapped accesses complete normally with `PREADY=1` and `PSLVERR=1`:

- denied reads drive `PRDATA=0`;
- denied writes do not update storage;
- denied writes remain errors even when `PSTRB=0`.

Unmapped accesses keep the existing unmapped-address error behavior and do not
evaluate any register-local policy.

## Composition Behavior

Fixed one-requester/one-completer composition does not enforce policy itself.
It propagates `PPROT/PSTRB` to the completer and returns the completer response
to the requester.

Multi-peripheral composition also leaves enforcement in the selected peripheral
completers. The generated interconnect continues to decode `PSEL`, translate
local `PADDR`, fan out `PPROT/PSTRB`, mux selected `PREADY/PRDATA/PSLVERR`, and
return an unmapped active-access error when no window matches.

Requester-observable behavior is through the normal response path: `done`
asserts on completion, `error` samples `PSLVERR`, status-capable requesters
report `done_error`, and denied reads publish zero read data.

## Reports And Support

The new support-accounting identities are:

```text
intent.ppif_apb_completer_multi_register_sideband_protection
intent.apb_profile_alias_completer_multi_register_sideband_protection
intent.ppif_apb_composition_multi_register_sideband_protection
intent.apb_profile_alias_composition_multi_register_sideband_protection
intent.ppif_apb_composition_multi_peripheral_sideband_protection
intent.apb_profile_alias_composition_multi_peripheral_sideband_protection
intent.ppif_apb_completer_multi_register_sideband_data16_protection
intent.apb_profile_alias_completer_multi_register_sideband_data16_protection
intent.ppif_apb_composition_multi_register_sideband_data16_protection
intent.apb_profile_alias_composition_multi_register_sideband_data16_protection
intent.ppif_apb_composition_multi_peripheral_sideband_data16_protection
intent.apb_profile_alias_composition_multi_peripheral_sideband_data16_protection
```

Selected completer reports add `protection_policy` metadata with:

- `scope = register`;
- `predicate_namespace = fsmgen_apb_pprot_v1`;
- predicate source `PPROT[0]` sampled into `prot_q`;
- per-register read/write policy;
- denied-read behavior of `PREADY=1`, `PRDATA=0`, `PSLVERR=1`;
- denied-write behavior of `PREADY=1`, `PRDATA=0`, `PSLVERR=1`, and no storage
  update;
- zero-strobe interaction for allowed and denied writes.

Selected fixed and multi-peripheral composition reports expose
`protection_policy` as propagation/mux metadata and identify completer or
peripheral-completer enforcement ownership.

Reports for the selected 32-bit and data16 protection samples replace
`apb_protection_policy_effects_deferred` with
`apb_additional_protection_policies_deferred`. Existing sideband-aware samples
without `access-policy`, including the data16 no-policy samples, keep their
prior residue.

## Diagnostics

The parser and normalizer reject unsupported policy shapes, including:

- `access-policy` outside APB completer storage registers;
- policy on sources without bus-side `PPROT/PSTRB`;
- policy on single-register completers or unsupported APB width families;
- duplicate or missing `read`/`write` clauses;
- actions other than `allow` and `require`;
- `allow` with predicates;
- `require` without exactly one predicate;
- predicates other than `privileged`;
- predicate values other than `0` or `1`.

## CLI Examples

Emit schedule JSON for the protected standalone completer:

```bash
./bin/fsmgen --emit-schedule-json \
  ppif/apb_completer_multi_register_sideband_protection.ppif
```

Run strict check JSON for the protected fixed-composition `.apb` alias:

```bash
./bin/fsmgen --strict --check --json \
  ppif/apb_composition_multi_register_sideband_protection.apb
```

Generate review artifacts and HDL for the protected multi-peripheral
composition:

```bash
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-pprot-policy \
  --output /tmp/fsmgen-apb-pprot-policy/apb_tb.sv \
  ppif/apb_composition_multi_peripheral_sideband_protection.ppif
```

## Non-Goals

This behavior does not add 8-bit or 64-bit policy variants, alternate address
widths, alternate wait-count widths,
`PPROT[1]` or `PPROT[2]` predicates, secure/non-secure policy,
instruction/data policy, multiple predicates, boolean policy expressions,
global completer policies, address-window policies, peripheral policies,
interconnect-owned policy enforcement, runtime-programmed policy registers,
requester-only policy behavior, back-to-back transfer admission, multiple
requesters, bus matrices, direct IAL2-to-IAL0 lowering, direct backend
lowering, verification-output generation, backend-language variants, AXI
behavior, AHB behavior, or VHDL behavior.

## Validation

Focused validation for the behavior passed:

```bash
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c t/1470-ial2-apb-profile-alias.t
perl -Iperl -c t/1471-ial2-apb-completer.t
perl -Iperl -c t/1472-ial2-apb-composition.t
perl -Iperl -c t/248-regression-corpus-accounting.t
prove -l t/1471-ial2-apb-completer.t \
  t/1472-ial2-apb-composition.t \
  t/1470-ial2-apb-profile-alias.t \
  t/248-regression-corpus-accounting.t \
  t/297-capability-manifest.t
```

## Rollback

Rollback of `.597` removes the 32-bit protection sample files, parser support
for register-local `access-policy` on 32-bit sideband completers, APB
completer/composition 32-bit policy lowering and reports, the 32-bit
support-accounting identities, and the matching docs/tests. Rollback of `.603`
removes the data16 protection sample files, the data16 policy admission and
lowering/report support, the data16 protection support-accounting identities,
and the matching docs/tests. Earlier APB requester, completer, composition,
`.apb`, busy/status, multi-register, multi-peripheral, sideband/strobe, and
data16 no-policy behavior remains owned by previous slices.
