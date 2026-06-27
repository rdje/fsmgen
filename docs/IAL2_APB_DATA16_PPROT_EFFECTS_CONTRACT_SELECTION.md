# IAL2 APB Data16 PPROT Effects Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.602`

Date: 2026-06-27

## Summary

`.602` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.603`, direct bounded
implementation of sideband data16 APB `PPROT` policy effects.

The selected contract changes no behavior in `.602`. It composes the shipped
sideband data16 APB width contract from `.594` with the shipped register-local
`PPROT[0]` access-policy vocabulary and denied-access behavior from `.597`.

The implementation remains deliberately narrow: sideband-aware 16-bit APB
multi-register completers, fixed one-requester/one-completer compositions, and
one-requester/two-peripheral compositions only. Requester-only policy behavior,
single-register protected completers, global/window/peripheral policies, and
interconnect-owned enforcement remain future exact-owner work.

## Selected Source Syntax

The selected public suffix is `sideband_data16_protection`. The selected sample
pairs are:

```text
ppif/apb_completer_multi_register_sideband_data16_protection.ppif
ppif/apb_completer_multi_register_sideband_data16_protection.apb
ppif/apb_composition_multi_register_sideband_data16_protection.ppif
ppif/apb_composition_multi_register_sideband_data16_protection.apb
ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif
ppif/apb_composition_multi_peripheral_sideband_data16_protection.apb
```

The selected support-accounting identities mirror those names:

```text
intent.ppif_apb_completer_multi_register_sideband_data16_protection
intent.apb_profile_alias_completer_multi_register_sideband_data16_protection
intent.ppif_apb_composition_multi_register_sideband_data16_protection
intent.apb_profile_alias_composition_multi_register_sideband_data16_protection
intent.ppif_apb_composition_multi_peripheral_sideband_data16_protection
intent.apb_profile_alias_composition_multi_peripheral_sideband_data16_protection
```

No requester-transfer-only data16 protection sample is selected. Requesters
already propagate `PPROT` and observe protection effects through returned
`PSLVERR`, status, and read data.

Data16 protection sources keep the existing data16 sideband widths:

- 32-bit `PADDR`, request address, register addresses, and address-map
  base/size fields;
- 16-bit `PWDATA`, `PRDATA`, request write data, requester read data, and
  completer register data;
- 3-bit `PPROT`;
- 2-bit `PSTRB` and requester `write-strobe`;
- 4-bit `wait_cycles`; and
- 2-bit requester `status` where a composition sample uses the status-capable
  requester shape.

The selected policy syntax is exactly the `.597` register-local vocabulary:

```lisp
(register reg0
  (address 0 width 32)
  (data reg0_data_q width 16 reset 0)
  (access-policy
    (read allow)
    (write require (privileged 1))))
(register reg1
  (address 2 width 32)
  (data reg1_data_q width 16 reset 0)
  (access-policy
    (read require (privileged 1))
    (write require (privileged 1))))
```

The only selected predicate remains `(privileged VALUE)`, where `VALUE` is `0`
or `1` and the predicate means sampled `PPROT[0] == VALUE`. `.603` must not add
public semantics for `PPROT[1]`, `PPROT[2]`, secure/non-secure,
instruction/data, user-defined predicates, boolean expressions, or
runtime-programmable policies.

## Selected Behavior

Completers evaluate the selected register policy from setup-phase sampled
`PPROT`, after address decode and at the existing APB response point. The
existing wait-count timing remains unchanged.

Allowed mapped accesses keep the shipped sideband data16 behavior:

- reads return the selected 16-bit register data and `PSLVERR=0`;
- writes update only `PSTRB`-selected byte lanes and return `PSLVERR=0`;
- `PSTRB[0]` maps to `PWDATA[7:0]`;
- `PSTRB[1]` maps to `PWDATA[15:8]`; and
- `PSTRB=2'b00` remains a successful no-byte write when the mapped write is
  allowed.

Denied mapped accesses complete at the normal response point with `PREADY=1`
and `PSLVERR=1`:

- denied reads drive 16-bit `PRDATA=0`;
- denied writes do not update storage, regardless of `PSTRB`; and
- denial takes precedence over the successful no-byte-write rule, so a denied
  mapped write with `PSTRB=2'b00` still returns `PSLVERR=1`.

Unmapped accesses remain owned by the existing unmapped-address policy and
return `PSLVERR=1`. Register-local policy is not evaluated for unmapped
addresses.

Requester-observable behavior is unchanged except for the selected completer
response: `done` asserts on transfer completion, `error` samples `PSLVERR`,
status-capable requesters report `done_error`, and denied reads publish a
zero-valued 16-bit read-data sample.

## Composition Behavior

Fixed one-requester/one-completer data16 protection composition does not
enforce policy itself. It wires requester `PPROT/PSTRB` to the selected
completer and returns the completer response.

Multi-peripheral data16 protection composition also leaves enforcement in the
selected peripheral completers. Each protected peripheral selected by `.603`
must be a sideband-aware data16 multi-register completer, so the existing
multi-register access-policy contract remains intact. The generated
interconnect continues to decode `PSEL`, translate local `PADDR`, fan out
2-bit `PSTRB` and 3-bit `PPROT`, mux selected `PREADY/PRDATA/PSLVERR`, and
generate unmapped active-access errors.

The selected multi-peripheral sample keeps the data16 address-map evidence from
`.594`: 2-byte-aligned static windows, including a non-4-byte-aligned boundary
such as `STATUS_SIZE = 258` and `CONTROL_BASE = 258`, while each protected
peripheral uses registers at offsets `0` and `2`.

## Reports And Residue

Selected data16 protection reports must keep width reporting separate from
policy reporting:

- `width_policy.selected_contract` remains `sideband_data16`;
- width policy continues to report 16-bit data, 2-bit strobe, two byte lanes,
  2-byte register/window alignment, 32-bit address/address-map widths, and
  4-bit wait counts; and
- `protection_policy` uses the existing `.597` register-local report shape.

The selected `protection_policy` metadata captures:

- policy scope `register`;
- predicate namespace `fsmgen_apb_pprot_v1`;
- predicate source sampled from `PPROT[0]`;
- per-register read/write policies;
- denied-read behavior: `PREADY=1`, `PRDATA=0`, `PSLVERR=1`;
- denied-write behavior: side-effect-free, `PSLVERR=1`; and
- zero-strobe interaction: allowed writes are successful no-byte writes, denied
  writes remain errors.

Fixed composition reports must identify the completer as enforcement owner.
Multi-peripheral composition reports must identify peripheral completers as
enforcement owners and the interconnect as propagation/mux-only.

Reports for the selected data16 protection samples replace
`apb_protection_policy_effects_deferred` with
`apb_additional_protection_policies_deferred` while retaining
`apb_remaining_widths_deferred`. Existing sideband data16 samples without
`access-policy` keep `apb_protection_policy_effects_deferred` and no
`protection_policy`. Existing 32-bit protection samples keep their current
report shape.

## Diagnostics

`.603` must preserve existing diagnostics and update only the selected data16
policy boundary. It must reject:

- `access-policy` outside APB completer storage registers;
- `access-policy` on APB sources without bus-side `PPROT/PSTRB`;
- `access-policy` on single-register completers;
- data widths other than the selected 16-bit and 32-bit APB policy paths;
- strobe widths that do not match `data_width / 8`;
- duplicate `access-policy`, `read`, or `write` clauses;
- missing `read` or `write` clauses;
- unsupported actions other than `allow` and `require`;
- `allow` clauses with predicates;
- `require` clauses without exactly one selected predicate;
- predicates other than `privileged`;
- predicate values other than `0` or `1`; and
- malformed, requester-only, global, window, peripheral, composition,
  interconnect, multi-predicate, boolean, or runtime-programmable policy syntax.

Diagnostics must stay distinct from unsupported object, profile/suffix
mismatch, malformed APB bus, sideband width, strobe/data width, duplicate
register, address-alignment, address-map overlap, and unmapped-address
diagnostics.

## Validation

The selected implementation owner must run focused syntax checks for the PPIF
parser, APB completer, APB composition, regression corpus, language-surface
manifest, and focused APB tests.

It must run direct schedule/check/semantic/outdir probes for all six selected
data16 protection sample paths, preservation probes for existing sideband
data16 samples without policies, preservation probes for existing 32-bit
protection samples, focused APB prove tests, regression-corpus and
capability-manifest tests, Knowledge Map generation/check, mdBook build, docs
path audit, memory architecture check, diff check, and the doctrine gate.

Focused prove tests should include:

```bash
prove -Iperl t/1470-ial2-apb-profile-alias.t \
  t/1471-ial2-apb-completer.t \
  t/1472-ial2-apb-composition.t \
  t/248-regression-corpus-accounting.t \
  t/297-capability-manifest.t
```

## Non-Goals

`.602` and the selected `.603` implementation do not add requester-only policy
behavior, single-register protected completers, 8-bit or 64-bit APB data
policy variants, alternate address widths, alternate wait-count widths,
`PPROT[1]` or `PPROT[2]` predicates, secure/non-secure policy,
instruction/data policy, multiple predicates, boolean policy expressions,
global completer policies, address-window policies, peripheral policies,
interconnect-owned policy enforcement, runtime-programmed policy registers,
back-to-back transfer admission, multiple requesters, bus matrices, direct
IAL2-to-IAL0 lowering, direct backend lowering, verification-output generation,
backend-language variants, AXI behavior, AHB behavior, or VHDL behavior.

## Rollback

Rollback of `.602` is doc-only: revert this contract, its fact card,
task-tree frontier updates, README, ROADMAP_V2, mdBook, Memory, and generated
Knowledge Map changes.

Rollback of `.603`, when implemented, must remove the six data16 protection
sample files, support-accounting identities, parser/generator/report/test
changes, and docs while preserving shipped APB sideband, data16, and 32-bit
protection behavior.
