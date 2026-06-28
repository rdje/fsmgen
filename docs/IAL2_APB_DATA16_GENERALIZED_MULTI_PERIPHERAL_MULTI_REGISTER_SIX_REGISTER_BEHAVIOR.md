# IAL2 APB Data16 Generalized Multi-Peripheral Multi-Register Six-Register Behavior

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.688`
- Date: `2026-06-28`
- Status: shipped
- Scope: bounded APB sideband-aware data16 no-policy six-register
  generalized register-set cardinality widening

## Shipped Public Sources

`IAL2-FEATURE-COMPLETENESS-FRONTIER.688` ships the `.687` selected public
source pair:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.apb`

The `.apb` profile alias is byte-identical to the `.ppif` source and lowers
through the same generated `.isf` review artifacts before generated `.fsm`
artifacts.

The public representative uses six registers per peripheral:

- `reg0` at local byte address `0`;
- `reg1` at local byte address `2`;
- `reg2` at local byte address `4`;
- `reg3` at local byte address `6`;
- `reg4` at local byte address `8`;
- `reg5` at local byte address `10`.

The accepted generalized no-policy data16 register-set family is now bounded
to two, three, four, five, or six source-ordered registers named
`reg0..regN`, with 32-bit addresses, 16-bit data, reset `0`, 2-byte spacing,
no `access-policy` clauses, and matching register-set shape on both
peripheral completers.

## Generated Behavior

The generated requester keeps the selected data16 back-to-back timing
contract: `accepted`, `busy`, 2-bit `status`, `done`, 16-bit
`last_read_data`, and `last_error`; one active transfer plus one queued next
transfer; queue-depth `1`; overflow `reject`; and queued relaunch of 16-bit
`PWDATA`, 3-bit `PPROT`, and 2-bit `PSTRB`.

The generated interconnect remains propagation-only:

- decodes status/control windows at bases `0` and `258`;
- translates `PADDR_CONTROL` by subtracting the control base;
- forwards `PENABLE`, `PWRITE`, 16-bit `PWDATA`, 3-bit `PPROT`, and 2-bit
  `PSTRB`;
- fans out decoded `PSEL` to status or control;
- muxes selected `PREADY`, `PRDATA`, and `PSLVERR`;
- returns `PSLVERR` for active unmapped accesses;
- inserts no idle cycle between a completed access and queued setup;
- owns no protection predicate.

Both peripheral completers use adjacent setup admission and no-policy storage.
They generate storage, read hits, byte-lane writes, and read-data drives for
all selected registers, including `reg4` and `reg5` in the public
representative.

## Reports And Support Accounting

Reports include aggregate multi-peripheral `back_to_back_policy` metadata for
the data16 six-register representative and keep the selected data16 no-policy
register arrays source-ordered as `[reg0, reg1, reg2, reg3, reg4, reg5]` for
both status and control peripherals.

The support-accounted identities are:

- `intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back`

The coverage buckets are:

- `ial2_ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back_pipeline_cli`

`RegressionCorpus`, `LanguageSurfaceSection`, and the capability manifest now
list both public surfaces as supported smoke fixtures.

## Deferred Boundaries

The slice deliberately does not select protected data16 six-register
generalized register sets, protected 32-bit six-register generalized register
sets, more than six registers, more than two peripheral completers, deeper
queues, overflow policies other than `reject`, accepted-less requesters,
multiple active APB transfers, bus matrices, scoreboards, direct backend
lowering, verification-output generation, backend-language variants, AXI,
AHB, or VHDL.

The active frontier returns to exact task-tree ownership before any future
protected, broader-cardinality, backend, or protocol-family behavior change.

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
- `cmp -s ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.ppif ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.apb`
- `./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.ppif`
- `./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.apb`
- `./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.ppif`
- `./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.ppif`
- `./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-data16-six-reg-688-outdir --output /tmp/fsmgen-apb-data16-six-reg-688-outdir/apb_tb.sv ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.ppif`
- `prove -Iperl t/248-regression-corpus-accounting.t`
- `prove -Iperl t/297-capability-manifest.t`
- `scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 2048 -- prove -Iperl t/1470-ial2-apb-profile-alias.t`
- `scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 2048 -- prove -Iperl t/1472-ial2-apb-composition.t`

Generated artifact inspection confirmed `reg5` storage/read/write paths,
two-byte write masks, queued 2-bit `PSTRB`, the 258-byte control-window
translation, and no interconnect-owned protection predicate.

## Rollback

Rollback removes the two public source files, restores the selected data16
no-policy generalized cardinality bound to five registers, removes the new
support-accounting identities and capability entries, removes the focused
tests and docs/fact-card updates, regenerates the Knowledge Map, and returns
the active frontier to a selector that re-owns any future data16 six-register
or broader cardinality widening before behavior changes.
