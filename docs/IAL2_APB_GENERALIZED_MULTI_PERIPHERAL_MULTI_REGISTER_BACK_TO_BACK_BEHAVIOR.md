# IAL2 APB Generalized Multi-Peripheral Multi-Register Back-To-Back Behavior

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.660`
- Date: `2026-06-28`
- Status: shipped
- Scope: first bounded generalized APB sideband-aware no-policy
  multi-peripheral multi-register register-set behavior

## Shipped Public Sources

`IAL2-FEATURE-COMPLETENESS-FRONTIER.660` ships the `.659` selected public
source pair:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.apb`

The `.apb` profile alias mirrors the `.ppif` source and lowers through the
same generated `.isf` review artifacts before generated `.fsm` artifacts.

The public representative uses three registers per peripheral:

- `reg0` at local byte address `0`;
- `reg1` at local byte address `4`;
- `reg2` at local byte address `8`.

The accepted generalized no-policy register-set family is still bounded to
two, three, or four source-ordered registers named `reg0..regN`, with 32-bit
addresses, 32-bit data, reset `0`, 4-byte spacing, no `access-policy`
clauses, and matching register-set shape on both peripheral completers.

## Generated Behavior

The generated requester exposes `accepted`, `busy`, `status`, `done`,
`last_read_data`, and `last_error`. It accepts one active transfer plus one
queued next transfer, preserves queue-depth `1` and overflow `reject`, and
relaunches queued 32-bit `PWDATA` together with `PPROT` and `PSTRB`.

The generated interconnect remains propagation-only:

- decodes status/control windows at bases `0` and `256`;
- translates `PADDR_CONTROL` by subtracting the control base;
- forwards `PENABLE`, `PWRITE`, `PWDATA`, `PPROT`, and `PSTRB`;
- fans out decoded `PSEL` to status or control;
- muxes selected `PREADY`, `PRDATA`, and `PSLVERR`;
- returns `PSLVERR` for active unmapped accesses;
- inserts no idle cycle between a completed access and queued setup;
- owns no protection predicate.

Both peripheral completers use adjacent setup admission and no-policy storage.
They generate storage, read hits, byte-lane writes, and read-data drives for
all selected registers, including `reg2` in the public representative.

## Reports And Support Accounting

Reports now include aggregate multi-peripheral `back_to_back_policy` metadata
for this selected generalized no-policy register-set family, remove broad
`apb_back_to_back_policy_deferred` for the supported public sources, and keep
narrowed future residue for unselected APB timing-policy families.

The support-accounted identities are:

- `intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back`

`RegressionCorpus`, `LanguageSurfaceSection`, and the capability manifest now
list both public surfaces as supported smoke fixtures.

## Deferred Boundaries

The slice deliberately does not select data16 generalized register sets,
protected generalized register sets, more than four registers, more than two
peripherals, deeper queues, overflow policies other than `reject`,
accepted-less requesters, multiple active APB transfers, bus matrices,
scoreboards, direct backend lowering, verification-output generation,
backend-language variants, AXI, AHB, or VHDL.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.661` is the next selector for that
remaining APB timing/register-set residue.

## Validation

Focused validation passed:

- `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm`
- `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm`
- `perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm`
- `perl -c t/1470-ial2-apb-profile-alias.t`
- `perl -c t/1472-ial2-apb-composition.t`
- `perl -c t/248-regression-corpus-accounting.t`
- `perl -c t/297-capability-manifest.t`
- `./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.ppif`
- `./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.apb`
- `./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-generalized-regset-check ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.ppif`
- `prove -Iperl t/248-regression-corpus-accounting.t`
- `prove -Iperl t/297-capability-manifest.t`
- `scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 2048 -- prove -Iperl t/1470-ial2-apb-profile-alias.t`
- `scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 2048 -- prove -Iperl t/1472-ial2-apb-composition.t`

The initial guarded `t/1470` attempts at host cutoffs `88` and `99` stopped
before useful completion because host memory was already above those
thresholds. The final guarded runs kept descendant RSS capped at 2048 MiB and
passed.
