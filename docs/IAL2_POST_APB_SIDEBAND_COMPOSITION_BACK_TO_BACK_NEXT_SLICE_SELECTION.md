# IAL2 Post APB Sideband Composition Back-To-Back Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.616`
- Date: `2026-06-28`
- Status: selected next contract owner
- Scope: APB sideband-aware back-to-back timing-policy next-owner selection
  only

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.616` audits the APB timing-policy frontier
after `.615` shipped the selected sideband-aware adjacent completer and
fixed-composition back-to-back behavior.

The next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.617`, public contract
selection for the bounded 32-bit sideband-aware multi-peripheral APB
back-to-back family. `.617` should settle exact sample names, endpoint and
interconnect compatibility, report/residue movement, support-accounting
identities, diagnostics, validation, and rollback before any implementation.

No parser behavior, generator behavior, samples, support-accounting entries,
generated artifacts, schedule/check JSON, semantic JSON, HDL/runtime behavior,
suffix acceptance, direct backend lowering, verification-output generation,
backend-language variants, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior changes in this selector.

## Evidence Read

This selection read:

- `docs/IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_BEHAVIOR.md`;
- `docs/IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_CONTRACT_SELECTION.md`;
- `docs/IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_READINESS_AUDIT.md`;
- `docs/IAL2_APB_SIDEBAND_BACK_TO_BACK_BEHAVIOR.md`;
- `docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md`;
- `docs/IAL2_APB_BACK_TO_BACK_BEHAVIOR.md`;
- `docs/IAL2_APB_SIDEBAND_STROBE_BEHAVIOR.md`;
- `docs/IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR.md`;
- `docs/IAL2_APB_PPROT_EFFECTS_BEHAVIOR.md`;
- `docs/IAL2_APB_DATA16_PPROT_EFFECTS_BEHAVIOR.md`;
- `ppif/apb_composition_multi_peripheral_sideband.ppif`;
- `ppif/apb_composition_multi_peripheral_status_back_to_back.ppif`;
- `ppif/apb_composition_multi_peripheral_sideband_protection.ppif`;
- `perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm`;
- `perl/FSM/Support/RegressionCorpus.pm`;
- `perl/FSM/Support/LanguageSurfaceSection.pm`;
- focused APB/profile-alias/support tests;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and relevant
  decisions.

## Current Substrate

The shipped timing-policy pieces are now staged enough for a multi-peripheral
sideband contract selection:

- `.607` shipped the selected no-sideband fixed requester/completer/composition
  timing-policy family;
- `.609` shipped the selected no-sideband two-peripheral status back-to-back
  propagation family;
- `.612` shipped sideband requester queued `PPROT/PSTRB` capture and relaunch;
- `.615` shipped sideband adjacent completer setup admission and fixed
  one-requester/one-completer sideband composition propagation.

The existing sideband multi-peripheral substrate already propagates
`PPROT width 3` and data-derived `PSTRB width 4` through the generated
interconnect to every peripheral completer. It also decodes current
`PSEL/PADDR`, fans out decoded `PSEL`, forwards `PENABLE`, muxes selected
responses, and leaves protection enforcement at endpoint completers.

Live schedule probes confirmed:

- `ppif/apb_composition_multi_peripheral_status_back_to_back.ppif` reports
  aggregate `back_to_back_policy` and narrowed
  `apb_additional_back_to_back_policies_deferred`;
- `ppif/apb_composition_multi_peripheral_sideband.ppif` propagates
  `PPROT/PSTRB` but still carries broad `apb_back_to_back_policy_deferred`;
- `ppif/apb_composition_multi_peripheral_sideband_protection.ppif` still
  carries broad `apb_back_to_back_policy_deferred` while also carrying
  protection-policy metadata;
- `ppif/apb_composition_multi_peripheral_sideband_data16.ppif` still carries
  broad `apb_back_to_back_policy_deferred` plus remaining-width residue.

## Guard Audit

The current implementation has a narrow fail-closed guard for multi-peripheral
timing propagation:

```text
APB multi-peripheral selected back-to-back timing-policy supports only 32-bit
no-sideband APB wiring in this slice
```

A temporary candidate combining the existing sideband multi-peripheral source
with requester `accepted`/queued timing policy and adjacent setup policy on
both peripheral completers failed exactly at that guard. That confirms there is
no parser prerequisite for the next contract selection; the blocker is the
unselected multi-peripheral sideband timing-policy compatibility boundary.

## Selected Next Owner

`.617` shall select the public contract for bounded 32-bit sideband-aware
multi-peripheral APB back-to-back propagation before implementation.

The contract-selection owner should decide:

- exact `.ppif` and `.apb` sample names, likely the status-capable sideband
  two-peripheral family;
- whether the implementation remains two-peripheral-only or admits a small
  cardinality widening;
- requester response and timing-policy requirements;
- per-peripheral sideband adjacent setup requirements;
- sideband wiring compatibility across requester, interconnect, and every
  peripheral completer;
- report/residue movement for top, requester, interconnect, and peripheral
  surfaces;
- support-accounting identities and language-surface wording;
- fail-closed diagnostics for partial sidebands, incompatible endpoint timing
  policy, unsupported widths, protection/data16 attempts, and unselected
  peripheral counts;
- focused schedule/check/semantic JSON, generated-artifact, HDL-shape, and
  profile-alias parity validation; and
- rollback boundaries.

## Deferred Work

This selector does not select data16/protection back-to-back variants,
multi-register timing policy, queue depths greater than 1, overflow policies
other than `reject`, accepted-less requester surfaces, multiple active APB
transfers, multi-requester interconnects, direct backend lowering,
verification-output generation, backend-language variants, AXI, AHB, or VHDL
behavior.

Data16 and protection timing-policy variants remain behind the selected
32-bit sideband multi-peripheral contract because they add width-policy and
endpoint-protection axes on top of the sideband interconnect timing boundary.

## Validation

Audit validation used documentation/code review plus live probes:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral_status_back_to_back.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral_sideband.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral_sideband_protection.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral_sideband_data16.ppif
```

The temporary combined sideband multi-peripheral timing-policy candidate was
created outside the repository and removed automatically. It failed at the
current no-sideband-only multi-peripheral timing guard.

Closeout also runs Knowledge Map, mdBook, docs path, memory, diff, and doctrine
gates.

## Rollback

Rollback is doc-only: revert this selector, its fact card, README, ROADMAP_V2,
mdBook, task tree, Memory, and generated Knowledge Map changes. The `.615`
sideband fixed-composition behavior and all existing APB, AXI, AHB, and VHDL
behavior remain unchanged.
