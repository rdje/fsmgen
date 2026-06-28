# IAL2 APB Protection Generalized Multi-Peripheral Multi-Register Cardinality Behavior

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.678`
- Date: `2026-06-28`
- Status: shipped
- Scope: bounded APB sideband-aware 32-bit protected five-register
  generalized register-set cardinality widening

## Shipped Public Sources

`IAL2-FEATURE-COMPLETENESS-FRONTIER.678` ships the `.677` selected public
source pair:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.apb`

The `.apb` profile alias is byte-identical to the `.ppif` source and lowers
through the same generated `.isf` review artifacts before generated `.fsm`
artifacts.

The public representative uses five registers per peripheral:

- `reg0` at local byte address `0`;
- `reg1` at local byte address `4`;
- `reg2` at local byte address `8`;
- `reg3` at local byte address `12`;
- `reg4` at local byte address `16`.

The accepted protected 32-bit register-set family is now bounded to two,
three, four, or five source-ordered registers named `reg0..regN`, with
32-bit addresses, 32-bit data, reset `0`, 4-byte spacing, matching
register-set shape on both peripheral completers, and the selected
register-local `access-policy` matrix on every selected register.

## Protection Policy

Protection remains owned by the selected peripheral completers. The generated
interconnect only propagates `PPROT` and `PSTRB`, translates local address
windows, muxes selected responses, and returns `PSLVERR` for active unmapped
accesses.

The selected access-policy matrix is:

- `reg0` read: allow;
- `reg0` write: require privileged `PPROT[0] == 1`;
- every `reg1..regN` read: require privileged `PPROT[0] == 1`;
- every `reg1..regN` write: require privileged `PPROT[0] == 1`.

Denied mapped reads complete with `PREADY` and `PSLVERR`, return zero read
data, and do not require an interconnect-owned policy predicate. Denied mapped
writes complete with `PREADY` and `PSLVERR` and are side-effect-free.

## Generated Behavior

The generated requester keeps the selected back-to-back timing contract:
`accepted`, `busy`, 2-bit `status`, `done`, 32-bit `last_read_data`, and
`last_error`; one active transfer plus one queued next transfer; queue-depth
`1`; overflow `reject`; and queued relaunch of 32-bit `PWDATA`, 3-bit
`PPROT`, and 4-bit `PSTRB`.

The generated interconnect remains propagation-only:

- decodes status/control windows at bases `0` and `256`;
- translates `PADDR_CONTROL` by subtracting the control base;
- forwards `PENABLE`, `PWRITE`, `PWDATA`, `PPROT`, and `PSTRB`;
- fans out decoded `PSEL` to status or control;
- muxes selected `PREADY`, `PRDATA`, and `PSLVERR`;
- returns `PSLVERR` for active unmapped accesses;
- inserts no idle cycle between a completed access and queued setup;
- owns no protection predicate.

Both peripheral completers use adjacent setup admission and protected storage.
They generate storage, privileged read/write policy branches, denied
read/write completions, byte-lane writes, and read-data drives for all
selected registers, including `reg3` and `reg4` in the public representative.

## Reports And Support Accounting

Reports now include aggregate multi-peripheral `back_to_back_policy` metadata
for the protected five-register representative and keep the selected 32-bit
protected register arrays source-ordered as `[reg0, reg1, reg2, reg3, reg4]`
for both status and control peripherals.

The support-accounted identities are:

- `intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back`

The coverage buckets are:

- `ial2_ppif_apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back_pipeline_cli`

`RegressionCorpus`, `LanguageSurfaceSection`, and the capability manifest now
list both public surfaces as supported smoke fixtures.

## Deferred Boundaries

The slice deliberately does not select data16 protected five-register
generalized register sets, more than five registers, more than two peripheral
completers, deeper queues, overflow policies other than `reject`,
accepted-less requesters, multiple active APB transfers, alternate access
policies, interconnect-owned protection policy, bus matrices, scoreboards,
direct backend lowering, verification-output generation, backend-language
variants, AXI, AHB, or VHDL.

## Validation

Focused validation passed:

- `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm`
- `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm`
- `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`
- `perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm`
- `perl -Iperl -c t/1470-ial2-apb-profile-alias.t`
- `perl -Iperl -c t/1472-ial2-apb-composition.t`
- `perl -Iperl -c t/248-regression-corpus-accounting.t`
- `perl -Iperl -c t/297-capability-manifest.t`
- `cmp -s ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.ppif ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.apb`
- `./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.ppif`
- `./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.apb`
- `./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.ppif`
- `./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.ppif`
- `./bin/fsmgen --quiet --strict --outdir /tmp/fsmgen-apb-protected-five-register-probe.hqV85f ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.ppif`
- `prove -Iperl t/248-regression-corpus-accounting.t`
- `prove -Iperl t/297-capability-manifest.t`
- `scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 2048 -- prove -Iperl t/1470-ial2-apb-profile-alias.t`
- `scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 2048 -- prove -Iperl t/1472-ial2-apb-composition.t`

The initial probe using `--out-dir` failed because this CLI spells the option
`--outdir`; the corrected `--outdir` probe passed.

## Rollback

Rollback removes the two public source files, restores the selected 32-bit
protected generalized cardinality bound to four registers, removes the new
support-accounting identities and capability entries, removes the focused
tests and docs/fact-card updates, regenerates the Knowledge Map, and returns
the active frontier to a selector that re-owns any future protected
cardinality widening.
