# IAL2 APB Sideband Composition Back-To-Back Contract Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.614`
- Date: `2026-06-28`
- Status: selected
- Scope: APB sideband-aware completer and fixed-composition timing-policy
  public contract only

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.614` selects the public contract for the
next bounded APB sideband-aware back-to-back implementation. It reuses the
`.606` timing-policy vocabulary and selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.615`
to implement the standalone sideband-aware one-register completer plus the fixed
one-requester/one-completer sideband-aware composition together.

The selected implementation remains bounded to 32-bit APB data, `PPROT` width 3,
`PSTRB` width 4, depth-1 requester queueing, overflow reject, and one
address-0 completer register. Multi-peripheral sideband propagation,
data16/protection variants, multi-register timing policy, deeper queues,
alternate overflow, direct backend lowering, verification-output generation,
backend-language variants, AXI, AHB, and VHDL remain deferred.

No parser behavior, generator behavior, samples, support-accounting entries,
generated artifacts, schedule/check JSON, semantic JSON, HDL/runtime behavior,
suffix acceptance, direct backend lowering, verification-output generation,
backend-language variants, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior changes in this selector.

## Evidence Read

This selection read:

- `docs/IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_READINESS_AUDIT.md`;
- `docs/IAL2_APB_SIDEBAND_BACK_TO_BACK_BEHAVIOR.md`;
- `docs/IAL2_APB_SIDEBAND_BACK_TO_BACK_READINESS_AUDIT.md`;
- `docs/IAL2_APB_BACK_TO_BACK_BEHAVIOR.md`;
- `docs/IAL2_APB_BACK_TO_BACK_CONTRACT_SELECTION.md`;
- `docs/IAL2_APB_SIDEBAND_STROBE_BEHAVIOR.md`;
- `docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md`;
- `perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm`;
- `perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm`;
- `perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm`;
- `perl/FSM/Support/RegressionCorpus.pm`;
- `perl/FSM/Support/LanguageSurfaceSection.pm`;
- `t/1470-ial2-apb-profile-alias.t`;
- `t/1471-ial2-apb-completer.t`;
- `t/1472-ial2-apb-composition.t`;
- `t/248-regression-corpus-accounting.t`;
- `t/297-capability-manifest.t`;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and relevant
  decisions.

Live schedule probes confirmed the current report split:

- `ppif/apb_completer_back_to_back.ppif` reports `setup_admission: adjacent`
  and no broad `apb_back_to_back_policy_deferred` residue;
- `ppif/apb_completer_multi_register_sideband.ppif` still reports broad
  `apb_back_to_back_policy_deferred` residue;
- `ppif/apb_composition_status_back_to_back.ppif` reports aggregate
  back-to-back policy metadata and no broad back-to-back residue;
- `ppif/apb_composition_multi_register_sideband.ppif` still reports broad
  `apb_back_to_back_policy_deferred` residue;
- `ppif/apb_requester_transfer_sideband_status_back_to_back.ppif` reports the
  selected requester timing policy and narrowed future-policy residue.

## Selected Public Sources

`.615` shall implement exactly these four public sources:

- `ppif/apb_completer_sideband_back_to_back.ppif`
- `ppif/apb_completer_sideband_back_to_back.apb`
- `ppif/apb_composition_sideband_status_back_to_back.ppif`
- `ppif/apb_composition_sideband_status_back_to_back.apb`

The `.apb` profile aliases must mirror the `.ppif` sources and lower through
generated `.isf` review artifacts before generated `.fsm` artifacts, matching
the existing APB review path.

## Completer Contract

The selected completer source is a sideband-aware variant of
`apb_completer_back_to_back`:

- exactly one `apb-completer apb_completer`;
- `profile apb`, role `completer`, one clock, and one reset;
- 32-bit `PADDR`, `PWDATA`, and `PRDATA`;
- bus `PPROT width 3` and `PSTRB width 4`, declared together;
- `wait_cycles width 4`;
- exactly one storage register at address `0`, data width 32, reset `0`;
- transfer `(setup-detect (select 1) (enable 0))`;
- transfer `(timing-policy (setup-admission adjacent))`.

The generated behavior must be the existing sideband completer behavior plus
the explicit adjacent setup policy. It samples `PADDR`, `PWRITE`, `PWDATA`,
`PPROT`, `PSTRB`, and `wait_cycles` on `PSEL && !PENABLE`; applies `PSTRB`
byte lanes to the address-0 write; reads the address-0 register; reports
unmapped addresses with `PSLVERR`; and does not require an inter-transfer idle
cycle.

## Fixed Composition Contract

The selected composition source combines:

- the already-shipped sideband requester timing policy from
  `apb_requester_transfer_sideband_status_back_to_back`;
- the selected sideband completer adjacent setup policy above;
- one fixed requester child and one fixed completer child;
- sideband-aware wiring with 32-bit address/data, `PPROT width 3`, and
  `PSTRB width 4`;
- requester response `accepted`, `busy`, and `status width 2`;
- no top-level `apb-composition` timing-policy clause.

The composition derives its aggregate back-to-back policy from compatible
endpoint policies. It must propagate requester `PPROT/PSTRB` to the completer
and preserve the existing fixed-composition no-idle-cycle behavior when a
queued requester setup immediately follows a completed access.

`.615` should implement the standalone sideband completer and fixed composition
together because the composition contract cannot be validated without the
sideband adjacent completer policy, while the requester prerequisite already
shipped in `.612`.

## Reports And Support Accounting

Selected sideband completer reports shall add:

```json
"timing_policy": {
  "setup_admission": "adjacent"
}
```

Selected sideband fixed-composition reports shall add aggregate
`back_to_back_policy` metadata with requester and completer endpoint timing
policies, matching the existing no-sideband composition report shape.

The selected four public sources shall remove broad
`apb_back_to_back_policy_deferred` residue and retain narrowed
`apb_additional_back_to_back_policies_deferred` residue for unselected APB
timing-policy variants.

Selected support-accounting identities:

- `intent.ppif_apb_completer_sideband_back_to_back`
- `intent.apb_profile_alias_completer_sideband_back_to_back`
- `intent.ppif_apb_composition_sideband_status_back_to_back`
- `intent.apb_profile_alias_composition_sideband_status_back_to_back`

Selected coverage buckets:

- `ial2_ppif_apb_completer_sideband_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_completer_sideband_back_to_back_pipeline_cli`
- `ial2_ppif_apb_composition_sideband_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_sideband_status_back_to_back_pipeline_cli`

## Diagnostics

The implementation owner shall keep diagnostics fail-closed:

- selected sideband completer timing policy accepts only the bounded 32-bit
  one-register sideband-aware family or the existing no-sideband family;
- partial sideband declarations must continue to reject with the sideband
  bundle diagnostic;
- selected sideband completer timing policy rejects multi-register storage,
  data16, protection access-policy, unsupported `PPROT/PSTRB` widths, and
  unsupported APB data widths;
- selected fixed-composition timing compatibility requires requester
  back-to-back queued depth 1 overflow reject and completer setup-admission
  adjacent;
- selected fixed-composition sideband timing requires matching 32-bit
  sideband-aware requester, completer, and wiring bus fields;
- selected multi-peripheral timing propagation remains rejected for sideband
  wiring in `.615`.

## Validation Target For `.615`

The implementation owner should cover:

- syntax checks for `ApbCompleter.pm`, `ApbComposition.pm`,
  `RegressionCorpus.pm`, `LanguageSurfaceSection.pm`, `t/1470`,
  `t/1471`, `t/1472`, `t/248`, and `t/297`;
- schedule JSON, strict check JSON, strict semantic JSON, generated artifacts,
  and HDL-shape probes for the four selected sources;
- `.ppif` and `.apb` profile-alias parity;
- generated `.fsm` evidence that the sideband completer samples `PPROT/PSTRB`
  on setup and applies `PSTRB` byte enables for the one-register write;
- composition report evidence that the aggregate back-to-back policy includes
  the sideband requester and completer endpoint policies;
- support-accounting and capability-manifest updates;
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map sync; and
- docs/doctrine closeout gates.

## Deferred Work

This selection does not include sideband multi-peripheral timing propagation,
data16/protection back-to-back variants, multi-register completer timing
policy, queue depths greater than 1, overflow policies other than `reject`,
accepted-less requester surfaces, multiple active APB transfers, direct backend
lowering, verification-output generation, backend-language variants, AXI, AHB,
or VHDL behavior.

## Validation

Selector validation used documentation/code review plus live report probes:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_back_to_back.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register_sideband.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_status_back_to_back.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_register_sideband.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_sideband_status_back_to_back.ppif
```

Closeout also runs Knowledge Map, mdBook, docs path, memory, diff, and doctrine
gates.

## Rollback

Rollback is doc-only: revert this selector, its fact card, README, ROADMAP_V2,
mdBook, task tree, Memory, and generated Knowledge Map changes. No parser,
generator, sample, support-accounting, generated-artifact, JSON, HDL/runtime,
APB, AXI, AHB, or VHDL behavior changes are part of `.614`.
