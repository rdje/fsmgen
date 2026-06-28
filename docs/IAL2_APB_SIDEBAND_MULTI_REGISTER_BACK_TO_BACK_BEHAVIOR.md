# IAL2 APB Sideband Multi-Register Back-To-Back Behavior

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.622`
- Date: `2026-06-28`
- Status: shipped
- Scope: selected 32-bit APB sideband-aware two-register completer and
  fixed-composition back-to-back timing-policy behavior

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.622` implements the `.621` selected APB
sideband-aware multi-register back-to-back timing-policy prerequisite for
exactly four public sources:

- `ppif/apb_completer_multi_register_sideband_back_to_back.ppif`
- `ppif/apb_completer_multi_register_sideband_back_to_back.apb`
- `ppif/apb_composition_multi_register_sideband_status_back_to_back.ppif`
- `ppif/apb_composition_multi_register_sideband_status_back_to_back.apb`

The selected sources lower through generated `.isf` review artifacts before
generated `.fsm` artifacts. The selected completer combines the existing
sideband/strobe byte-lane behavior, multi-register decode behavior, and
adjacent setup-admission behavior. The selected fixed composition combines that
completer with the `.612` sideband requester queue and the `.615` fixed
sideband composition wiring.

This slice does not widen the APB outstanding model. There is still at most one
active APB transfer and one queued requester-side next transfer.

## Selected Completer Contract

The selected standalone completer family is intentionally narrow:

- one `apb-completer apb_completer`;
- 32-bit `PADDR`, `PWDATA`, `PRDATA`, and register data;
- bus `PPROT width 3`;
- bus `PSTRB width 4`;
- `wait_cycles width 4`;
- exactly two source-ordered storage registers;
- `reg0` at address `0`, width `32`, reset `0`;
- `reg1` at address `4`, width `32`, reset `0`;
- no register-local `access-policy` clauses;
- `(setup-detect (select 1) (enable 0))`;
- `(timing-policy (setup-admission adjacent))`.

Adjacent setup admission now accepts the existing selected one-register
no-sideband family, the existing selected one-register sideband-aware family,
and this selected two-register sideband-aware no-policy family. Other
multi-register timing-policy completer shapes remain rejected or deferred.

## Generated Completer Behavior

The generated completer samples `PADDR`, `PWRITE`, `PWDATA`, `PPROT`, `PSTRB`,
and `wait_cycles` on `PSEL && !PENABLE`. It uses the sampled wait count for the
access phase, decodes address `0` to `reg0`, decodes address `4` to `reg1`,
applies `PSTRB` byte enables to selected writes, reads the selected register,
and reports unmapped addresses with `PSLVERR`.

The selected adjacent setup policy admits the next setup phase on an adjacent
`PSEL && !PENABLE` cycle without requiring an inter-transfer idle cycle. The
standalone completer report includes:

```json
"timing_policy": {
  "setup_admission": "adjacent"
}
```

The selected report removes broad `apb_back_to_back_policy_deferred` for this
standalone completer surface and retains narrowed
`apb_additional_back_to_back_policies_deferred` residue for unselected APB
timing-policy families.

## Selected Fixed Composition Contract

The selected fixed composition combines:

- the `.612` 32-bit sideband requester with `accepted`, `busy`, and
  `status width 2`;
- requester timing policy `(timing-policy (back-to-back queued)
  (queue-depth 1) (overflow reject))`;
- request sidebands `req_prot width 3` and `req_wstrb width 4`;
- the selected two-register sideband-aware adjacent setup completer;
- one requester child and one completer child;
- 32-bit sideband-aware fixed wiring with `PPROT width 3` and `PSTRB width 4`.

The fixed-composition compatibility guard accepts this selected sideband-aware
two-register no-policy completer only for one-requester/one-completer fixed
composition. Multi-peripheral multi-register timing propagation remains
deferred.

## Generated Fixed Composition Behavior

The generated top exposes the requester `accepted`, `busy`, `status`, `done`,
`last_error`, and `last_read_data` outputs. The requester keeps the `.612`
depth-1 queued sideband behavior: accepted queued transfers store the queued
address, write bit, write data, `PPROT`, and `PSTRB`, then relaunch the queued
setup without an inserted idle cycle.

The fixed composition wires requester `PADDR/PWRITE/PWDATA/PPROT/PSTRB` into
the selected multi-register completer. The completer samples the queued
sideband payload on the adjacent setup cycle and applies byte-lane writes to
`reg0` or `reg1` according to the decoded address.

The composition report adds aggregate `back_to_back_policy` metadata for both
endpoints, removes broad `apb_back_to_back_policy_deferred` for the selected
fixed-composition surface, and retains narrowed future-policy residue.

## Support Accounting

Support-accounting identities added in this slice:

- `intent.ppif_apb_completer_multi_register_sideband_back_to_back`
- `intent.apb_profile_alias_completer_multi_register_sideband_back_to_back`
- `intent.ppif_apb_composition_multi_register_sideband_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_register_sideband_status_back_to_back`

Coverage buckets added in this slice:

- `ial2_ppif_apb_completer_multi_register_sideband_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_completer_multi_register_sideband_back_to_back_pipeline_cli`
- `ial2_ppif_apb_composition_multi_register_sideband_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_register_sideband_status_back_to_back_pipeline_cli`

## CLI Examples

Emit schedule JSON for the standalone completer:

```bash
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_completer_multi_register_sideband_back_to_back.ppif
```

Run check JSON for the `.apb` fixed-composition alias:

```bash
./bin/fsmgen --quiet --check --json \
  ppif/apb_composition_multi_register_sideband_status_back_to_back.apb
```

Generate review artifacts and HDL:

```bash
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-mreg-btb \
  --output /tmp/fsmgen-apb-mreg-btb/apb_tb.sv \
  ppif/apb_composition_multi_register_sideband_status_back_to_back.ppif
```

## Deferred Work

- multi-peripheral multi-register timing propagation;
- data16 back-to-back timing variants beyond the selected sideband-aware
  data16 fixed multi-register status family;
- protection-policy back-to-back timing variants;
- combined data16-protection back-to-back timing;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester surfaces;
- multiple active APB bus transfers;
- direct backend lowering and verification-output generation;
- backend-language variants, AXI, AHB, and VHDL behavior.

## Validation

Focused validation for this slice includes:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c t/1470-ial2-apb-profile-alias.t
perl -Iperl -c t/1471-ial2-apb-completer.t
perl -Iperl -c t/1472-ial2-apb-composition.t
perl -Iperl -c t/248-regression-corpus-accounting.t
perl -Iperl -c t/297-capability-manifest.t
prove -Iperl t/1471-ial2-apb-completer.t
prove -Iperl t/1472-ial2-apb-composition.t
prove -Iperl t/1470-ial2-apb-profile-alias.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
```

Direct probes cover schedule JSON, check JSON, semantic JSON, temporary
generated review artifacts, and generated HDL for the selected `.ppif` and
`.apb` sources. Closeout also runs Knowledge Map generation/check, mdBook
build, docs path, memory, diff, and doctrine gates.

## Rollback

Rollback removes the four selected public samples, the selected two-register
sideband timing-policy guard widening in `ApbCompleter` and `ApbComposition`,
the support-accounting entries, focused tests, this behavior record, its
Knowledge Map fact card, README, ROADMAP_V2, mdBook, task tree, Memory, and
generated Knowledge Map updates. Existing no-sideband back-to-back behavior,
sideband requester behavior, sideband one-register fixed-composition behavior,
sideband multi-peripheral behavior, APB sideband/data16/protection behavior,
AXI, AHB, and VHDL behavior remain owned by earlier or future slices.
