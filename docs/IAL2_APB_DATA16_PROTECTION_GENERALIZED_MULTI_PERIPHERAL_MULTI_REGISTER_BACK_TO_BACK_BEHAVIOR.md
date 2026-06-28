# IAL2 APB Data16 Protection Generalized Multi-Peripheral Multi-Register Back-To-Back Behavior

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.668`
- Date: `2026-06-28`
- Status: shipped
- Scope: bounded APB sideband-aware data16 protected generalized
  `reg0..regN` register-set multi-peripheral back-to-back timing behavior

## Shipped Public Sources

`IAL2-FEATURE-COMPLETENESS-FRONTIER.668` ships the `.667` selected public
source pair:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.apb`

The `.apb` profile alias is byte-identical to the `.ppif` source and lowers
through the same generated `.isf` review artifacts before generated `.fsm`
artifacts.

The public representative uses three protected registers per peripheral:

- `reg0` at local byte address `0`;
- `reg1` at local byte address `2`;
- `reg2` at local byte address `4`.

The admitted family remains bounded to two, three, or four source-ordered
registers named `reg0..regN`, with 32-bit address fields, 16-bit data, reset
`0`, 2-byte spacing, matching register-set shape on both peripheral
completers, and the selected protected access-policy matrix.

## Generated Behavior

The generated requester exposes `accepted`, `busy`, `status`, `done`,
`last_read_data`, and `last_error`. It accepts one active transfer plus one
queued next transfer, preserves queue-depth `1` and overflow `reject`, and
relaunches queued 16-bit `PWDATA` together with 3-bit `PPROT` and 2-bit
`PSTRB`.

The generated interconnect remains propagation-only:

- decodes status/control windows at bases `0` and `258`;
- uses a window size of `258` bytes for each selected peripheral;
- translates `PADDR_CONTROL` by subtracting the control base;
- forwards `PENABLE`, `PWRITE`, `PWDATA`, `PPROT`, and `PSTRB`;
- fans out decoded `PSEL` to status or control;
- muxes selected `PREADY`, `PRDATA`, and `PSLVERR`;
- returns `PSLVERR` for active unmapped accesses;
- inserts no idle cycle between a completed access and queued setup;
- owns no protection predicate.

Both peripheral completers use adjacent setup admission and own protection
enforcement. Allowed mapped writes update only selected byte lanes. Denied
mapped reads return zero data with `PSLVERR`; denied mapped writes complete
with `PSLVERR` and leave storage unchanged.

The selected access-policy matrix is:

- `reg0` read: allow;
- `reg0` write: require privileged `PPROT[0] == 1`;
- every `regN` where `N >= 1` read: require privileged `PPROT[0] == 1`;
- every `regN` where `N >= 1` write: require privileged `PPROT[0] == 1`.

## Reports And Support Accounting

Reports include aggregate multi-peripheral `back_to_back_policy` metadata for
this selected data16 protected generalized register-set family, remove broad
`apb_back_to_back_policy_deferred` and broad selected-family protection
residue for the supported public sources, and keep narrowed future residue for
unselected APB timing-policy families.

The support-accounted identities are:

- `intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back`

`RegressionCorpus`, `LanguageSurfaceSection`, and the capability manifest now
list both public surfaces as supported smoke fixtures.

## Deferred Boundaries

The slice deliberately does not select more than four registers, more than two
peripherals, deeper queues, overflow policies other than `reject`,
accepted-less requesters, multiple active APB transfers, bus matrices,
scoreboards, alternate protection-policy matrices, interconnect-owned
protection, direct backend lowering, verification-output generation,
backend-language variants, AXI, AHB, or VHDL.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.669` owns the next APB
timing/register-set residue selector.

## Validation

Focused validation passed:

- `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm`
- `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm`
- `perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm`
- `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`
- `perl -Iperl -c t/1470-ial2-apb-profile-alias.t`
- `perl -Iperl -c t/1472-ial2-apb-composition.t`
- `perl -Iperl -c t/248-regression-corpus-accounting.t`
- `perl -Iperl -c t/297-capability-manifest.t`
- `diff -u ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.ppif ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.apb`
- `./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.ppif`
- `./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.apb`
- `./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.ppif`
- `./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.ppif`
- `./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-data16-prot-gen-668-outdir --output /tmp/fsmgen-apb-data16-prot-gen-668-outdir/apb_tb.sv ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.ppif`
- `prove -Iperl t/248-regression-corpus-accounting.t`
- `prove -Iperl t/297-capability-manifest.t`
- `scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 2048 -- prove -Iperl t/1470-ial2-apb-profile-alias.t`
- `scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 2048 -- prove -Iperl t/1472-ial2-apb-composition.t`
- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `mdbook build docs/book`
- `scripts/check_docs_relative_paths.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`
- `scripts/check_doctrines.sh`

The guarded APB profile-alias and composition runs used the repository RAM
guard with process inspection and kept descendant RSS capped at 2048 MiB.
