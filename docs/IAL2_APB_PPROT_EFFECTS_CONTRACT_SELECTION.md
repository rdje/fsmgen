# IAL2 APB PPROT Effects Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.596`

Date: 2026-06-27

## Summary

`.596` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.597`, direct bounded
implementation of the first APB `PPROT` access-control effects contract.

The selected contract changes no behavior in `.596`. It records the exact
source vocabulary, denied-access semantics, report/support shape, diagnostics,
validation, and rollback boundary that `.597` must implement.

The first implementation is deliberately narrow: sideband-aware 32-bit APB
multi-register completers and compositions only. Sideband-aware data16 policy
effects, additional `PPROT` predicates, global/window/peripheral policies, and
interconnect-owned enforcement remain future exact-owner work.

## Selected Source Syntax

The first policy surface is register-local and lives inside an APB completer
storage register:

```lisp
(register control_reg
  (address 4 width 32)
  (data control_data_q width 32 reset 0)
  (access-policy
    (read allow)
    (write require (privileged 1))))
```

The selected access clauses are:

- `(read allow)` or `(read require (privileged VALUE))`;
- `(write allow)` or `(write require (privileged VALUE))`;
- `VALUE` is `0` or `1`.

The selected predicate namespace is local to FSMGen's APB policy contract:
`(privileged VALUE)` means sampled `PPROT[0] == VALUE`. This selection does
not add public semantics for `PPROT[1]`, `PPROT[2]`, secure/non-secure,
instruction/data, user-defined predicates, boolean policy expressions, or
runtime-programmable policies.

The first public samples should exercise both denied-read and denied-write
paths. A typical two-register completer uses an unprotected status register
and a protected control register:

```lisp
(storage
  (register status_reg
    (address 0 width 32)
    (data status_data_q width 32 reset 0)
    (access-policy
      (read allow)
      (write require (privileged 1))))
  (register control_reg
    (address 4 width 32)
    (data control_data_q width 32 reset 0)
    (access-policy
      (read require (privileged 1))
      (write require (privileged 1)))))
```

## Selected Behavior

Completers evaluate the selected register policy from the sampled setup-phase
`PPROT` value. The check is performed against the selected register for the
current transfer, after address decode and without changing the existing
wait-count timing.

Allowed mapped accesses behave like the current sideband-aware APB behavior:

- mapped reads return the selected register data and `PSLVERR=0`;
- mapped writes update only the `PSTRB`-selected byte lanes and return
  `PSLVERR=0`;
- `PSTRB=0` remains a successful no-byte write when the mapped write is
  allowed.

Denied mapped accesses complete at the normal response point with `PREADY=1`
and `PSLVERR=1`:

- denied reads drive `PRDATA=0`;
- denied writes are side-effect-free, regardless of `PSTRB`;
- denial takes precedence over the successful no-byte-write rule, so a denied
  mapped write with `PSTRB=0` still returns `PSLVERR=1` and does not update
  storage.

Unmapped accesses remain owned by the existing unmapped-address policy and
return `PSLVERR=1`. Register-local access policy is not evaluated for an
unmapped address.

Requester-observable behavior is unchanged except for the selected completer
response:

- requester `done` asserts when the APB transfer completes;
- requester `error` samples the returned `PSLVERR`;
- status-capable requester variants report `done_error` for denied accesses;
- denied reads publish the sampled zero `PRDATA` value.

## Composition Behavior

Fixed one-requester/one-completer composition does not enforce policy itself.
It wires requester `PPROT` to the completer as the sideband-aware APB contract
already does, and the selected completer returns the denial response.

Multi-peripheral composition also does not enforce policy in the generated
interconnect for this first slice. The interconnect continues to decode
`PSEL`, translate local `PADDR`, fan out `PPROT/PSTRB`, mux the selected
response, and generate unmapped active-access errors. The selected peripheral
completer owns any register-local denial.

## Selected Samples And Support

`.597` shall add 32-bit sideband-aware policy sample pairs for:

```text
ppif/apb_completer_multi_register_sideband_protection.ppif
ppif/apb_completer_multi_register_sideband_protection.apb
ppif/apb_composition_multi_register_sideband_protection.ppif
ppif/apb_composition_multi_register_sideband_protection.apb
ppif/apb_composition_multi_peripheral_sideband_protection.ppif
ppif/apb_composition_multi_peripheral_sideband_protection.apb
```

The selected support-accounting identities mirror those filenames:

```text
intent.ppif_apb_completer_multi_register_sideband_protection
intent.apb_profile_alias_completer_multi_register_sideband_protection
intent.ppif_apb_composition_multi_register_sideband_protection
intent.apb_profile_alias_composition_multi_register_sideband_protection
intent.ppif_apb_composition_multi_peripheral_sideband_protection
intent.apb_profile_alias_composition_multi_peripheral_sideband_protection
```

No requester-transfer-only protection sample is selected, because requesters
already propagate `PPROT` and can observe policy effects only through returned
`PSLVERR`.

## Reports And Residue

Selected completer reports must add additive `protection_policy` metadata that
captures:

- policy scope: `register`;
- predicate namespace: `fsmgen_apb_pprot_v1`;
- predicate source: sampled `PPROT[0]`;
- per-register read/write policy;
- denied-read behavior: `PRDATA=0`, `PSLVERR=1`;
- denied-write behavior: side-effect-free, `PSLVERR=1`;
- `PSTRB=0` interaction: allowed writes are successful no-byte writes, denied
  writes remain errors.

Selected composition reports must expose that policy enforcement is owned by
the selected completer/peripheral and that fixed composition or
multi-peripheral interconnect only propagates and muxes APB responses.

Reports for the selected `.597` samples replace
`apb_protection_policy_effects_deferred` with the narrower
`apb_additional_protection_policies_deferred`, because the first privileged
register-local policy effect is implemented while broader PPROT policy
families remain deferred. Existing sideband-aware samples without
`access-policy`, including data16 samples, keep their current protection-policy
residue.

## Diagnostics

`.597` must reject:

- `access-policy` outside APB completer storage registers;
- `access-policy` on APB sources without bus-side `PPROT`;
- `access-policy` on data widths other than the selected 32-bit APB path;
- duplicate `access-policy`, `read`, or `write` clauses;
- missing `read` or `write` clauses;
- unsupported actions other than `allow` and `require`;
- `require` clauses without exactly one selected predicate;
- predicates other than `privileged`;
- predicate values other than `0` or `1`;
- malformed, global, window, peripheral, composition, requester, interconnect,
  multi-predicate, boolean, or runtime-programmable policy syntax.

Diagnostics must stay distinct from unsupported object, profile/suffix
mismatch, malformed APB bus, sideband width, strobe/data width, duplicate
register, address-alignment, and unmapped-address diagnostics.

## Validation

The selected implementation owner must run focused syntax checks, direct
schedule/check/semantic/outdir probes for all new sample pairs, preservation
probes for existing sideband and data16 APB samples, focused APB prove tests,
regression-corpus and capability-manifest checks, Knowledge Map
generation/check, mdBook build, docs path audit, memory architecture check,
diff check, and doctrine gate.

Focused tests should include `t/1470-ial2-apb-profile-alias.t`,
`t/1471-ial2-apb-completer.t`, `t/1472-ial2-apb-composition.t`,
`t/248-regression-corpus-accounting.t`, and
`t/297-capability-manifest.t`.

## Non-Goals

`.596` and the selected `.597` implementation do not add sideband-aware data16
policy effects, 8-bit or 64-bit APB policy variants, alternate address widths,
alternate wait-count widths, `PPROT[1]` or `PPROT[2]` predicates,
secure/non-secure policy, instruction/data policy, multiple predicates,
boolean policy expressions, global completer policies, address-window policies,
peripheral policies, interconnect-owned policy enforcement, runtime-programmed
policy registers, requester-only policy behavior, back-to-back transfer
admission, multiple requesters, bus matrices, direct IAL2-to-IAL0 lowering,
direct backend lowering, verification-output generation, backend-language
variants, AXI behavior, AHB behavior, or VHDL behavior.

## Rollback

Rollback of `.596` is doc-only: revert this contract, its fact card,
task-tree frontier updates, README, ROADMAP_V2, mdBook, Memory, and generated
Knowledge Map changes. `.597` rollback, when implemented, must remove the
policy samples, parser/generator/report/support-accounting/test changes, and
docs while preserving the current APB sideband, data16, requester, completer,
fixed-composition, and multi-peripheral behavior.
