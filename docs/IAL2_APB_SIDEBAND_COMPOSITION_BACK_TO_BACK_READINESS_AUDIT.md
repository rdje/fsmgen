# IAL2 APB Sideband Composition Back-To-Back Readiness Audit

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.613`
- Date: `2026-06-28`
- Status: selected next contract owner
- Scope: APB sideband-aware completer and composition back-to-back readiness only

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.613` audits the next APB timing-policy
residue after `.612` shipped requester-side queued `PPROT/PSTRB` capture.

The audit selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.614`, a no-behavior
public contract-selection owner for the bounded 32-bit sideband-aware APB
completer and fixed-composition timing-policy family. The next owner should
settle the exact public sample names, one-register completer scope, fixed
composition propagation boundary, report/residue movement, diagnostics,
validation, and rollback before implementation.

No parser behavior, generator behavior, samples, support-accounting entries,
generated artifacts, schedule/check JSON, semantic JSON, HDL/runtime behavior,
suffix acceptance, direct backend lowering, verification-output generation,
backend-language variants, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior changes in this audit.

## Evidence Read

The audit read:

- `docs/IAL2_APB_SIDEBAND_BACK_TO_BACK_BEHAVIOR.md`;
- `docs/IAL2_APB_SIDEBAND_BACK_TO_BACK_READINESS_AUDIT.md`;
- `docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md`;
- `docs/IAL2_APB_BACK_TO_BACK_BEHAVIOR.md`;
- `docs/IAL2_APB_BACK_TO_BACK_CONTRACT_SELECTION.md`;
- `docs/IAL2_APB_SIDEBAND_STROBE_BEHAVIOR.md`;
- `docs/IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR.md`;
- `docs/IAL2_APB_DATA16_PPROT_EFFECTS_BEHAVIOR.md`;
- `perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm`;
- `perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm`;
- `perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm`;
- `perl/FSM/Support/RegressionCorpus.pm`;
- `perl/FSM/Support/LanguageSurfaceSection.pm`;
- focused APB/profile-alias/support tests;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and relevant
  decisions.

Live schedule probes confirmed the current split:

- `ppif/apb_requester_transfer_sideband_status_back_to_back.ppif` removes broad
  `apb_back_to_back_policy_deferred` and keeps narrowed
  `apb_additional_back_to_back_policies_deferred`;
- `ppif/apb_completer_multi_register_sideband.ppif` still reports
  `apb_back_to_back_policy_deferred`;
- `ppif/apb_composition_multi_register_sideband.ppif` still reports
  `apb_back_to_back_policy_deferred` at the top and child surfaces;
- `ppif/apb_composition_multi_peripheral_sideband.ppif` still reports
  `apb_back_to_back_policy_deferred` at the top, requester, interconnect, and
  peripheral surfaces.

## Current Substrate

The requester prerequisite is now present. `.612` accepts the selected
32-bit sideband-aware requester timing policy, adds `queued_prot` and
`queued_wstrb`, captures `req_prot/req_wstrb` at accepted time, and relaunches
queued setup with `PPROT/PSTRB` from the queued payload.

The sideband completer substrate already samples `PADDR`, `PWRITE`, `PWDATA`,
`PPROT`, `PSTRB`, and `wait_cycles` on setup (`PSEL && !PENABLE`) and applies
`PSTRB` byte enables to selected writes. However, the selected adjacent setup
policy guard remains narrower than that substrate:

```text
APB completer IAL2 contract selected setup-admission adjacent policy supports
only the 32-bit no-sideband completer family in this slice
```

It also rejects multi-register storage for timing-policy completers. That makes
a one-register sideband-aware completer the smallest viable completer target.

The fixed-composition wiring substrate already propagates `PPROT/PSTRB` between
sideband-aware requester and completer endpoints. The selected timing-policy
compatibility guard still rejects sideband-aware wiring:

```text
APB fixed composition selected back-to-back timing-policy supports only 32-bit
no-sideband APB wiring in this slice
```

The multi-peripheral interconnect substrate also propagates `PPROT/PSTRB`, but
its selected timing-policy compatibility guard still requires no-sideband
wiring and exactly two one-register peripheral completers. Multi-peripheral
sideband timing propagation should therefore follow, not precede, the fixed
one-requester/one-completer sideband timing contract.

## Selected Next Owner

`.614` shall select the public contract for the bounded 32-bit sideband-aware
APB completer and fixed-composition timing-policy family before implementation.

The contract-selection owner should decide:

- exact `.ppif` and `.apb` sample names for the sideband-aware adjacent
  one-register completer and fixed one-requester/one-completer composition;
- whether the first implementation combines standalone completer timing support
  and fixed-composition propagation, or splits them;
- report and support-accounting movement for selected sideband completer and
  fixed-composition surfaces;
- diagnostics for missing/incompatible endpoint timing policies, sideband bundle
  mismatches, multi-register timing attempts, data16/protection attempts, and
  multi-peripheral attempts;
- focused schedule/check/semantic JSON, generated-artifact, HDL-shape, and
  profile-alias parity validation; and
- rollback boundaries.

## Deferred Work

This audit does not select multi-peripheral sideband timing propagation,
data16/protection back-to-back variants, multi-register completer timing
policy, queue depths greater than 1, overflow policies other than `reject`,
accepted-less requester surfaces, multiple active APB transfers, direct backend
lowering, verification-output generation, backend-language variants, AXI, AHB,
or VHDL behavior.

## Validation

Audit validation used documentation/code review plus live report probes:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_sideband_status_back_to_back.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register_sideband.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_register_sideband.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral_sideband.ppif
```

Closeout also runs Knowledge Map, mdBook, docs path, memory, diff, and doctrine
gates.

## Rollback

Rollback is doc-only: revert this audit, its fact card, README, ROADMAP_V2,
mdBook, task tree, Memory, and generated Knowledge Map changes. The `.612`
requester behavior and all existing sideband, data16, protection, completer,
composition, AXI, AHB, and VHDL behavior remain unchanged.
