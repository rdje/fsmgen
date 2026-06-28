# IAL2 APB Back-To-Back Transfer Policy Contract Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.606`
- Date: `2026-06-28`
- Status: selected
- Scope: APB `.ppif` / `.apb` public contract selection only

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.606` selects an explicit opt-in APB
back-to-back transfer policy contract before any parser, generator, sample,
support-accounting, validation, generated-artifact, JSON, HDL/runtime, suffix,
direct-backend, verification-output, backend-language, AXI, AHB, or VHDL
behavior changes.

The selected public contract is a bounded depth-1 queued requester policy plus
adjacent-safe completer setup admission. Existing APB sources keep their
current one-transfer-at-a-time behavior until they opt in with a new
`(timing-policy ...)` clause under the existing APB `(transfer ...)` block.

The next implementation owner is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.607`, a bounded requester, completer, and
fixed-composition implementation for the selected sample family. Multi-
peripheral interconnect propagation remains a later exact owner after the fixed
composition path proves the public policy and report migration.

Update `.609`: that later exact owner now ships the selected 32-bit
no-sideband two-peripheral status multi-peripheral propagation family. This
contract selection remains the source of the shared requester/completer timing
vocabulary.

## Evidence Read

This selection reads and closes the contract questions left by:

- `docs/IAL2_APB_BACK_TO_BACK_READINESS_AUDIT.md`
- `docs/IAL2_POST_APB_DATA16_PPROT_NEXT_SLICE_SELECTION.md`
- `docs/IAL2_APB_DATA16_PPROT_EFFECTS_BEHAVIOR.md`
- `docs/IAL2_APB_DATA16_PPROT_EFFECTS_CONTRACT_SELECTION.md`
- `docs/IAL2_APB_DATA16_PPROT_EFFECTS_READINESS_AUDIT.md`
- `docs/IAL2_APB_PPROT_EFFECTS_BEHAVIOR.md`
- `docs/IAL2_APB_SIDEBAND_DATA16_BEHAVIOR.md`
- `docs/IAL2_APB_SIDEBAND_STROBE_BEHAVIOR.md`
- `perl/FSM/Adapter/IAL2/PPIF.pm`
- `perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm`
- `perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm`
- `perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm`
- `perl/FSM/Support/RegressionCorpus.pm`
- `perl/FSM/Support/LanguageSurfaceSection.pm`
- `t/1470-ial2-apb-profile-alias.t`
- `t/1471-ial2-apb-completer.t`
- `t/1472-ial2-apb-composition.t`
- `README.md`, `ROADMAP_V2.md`, `docs/book/src/14-feature-backlog.md`
- `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`
- `docs/TASK_TREE.md`, `MEMORY.md`, `KNOWLEDGE_MAP.md`
- decisions `0015`, `0016`, `0017`, and `0018`

Live schedule probes confirmed that current APB requester, completer, fixed
composition, and multi-peripheral composition reports still retain
`apb_back_to_back_policy_deferred`.

## Selected Source Vocabulary

The requester policy is an optional nested clause under the existing
`apb-requester` transfer block:

```text
(transfer apb_transfer
  (setup (select 1) (enable 0))
  (access (select 1) (enable 1))
  (complete-on ready)
  (sample read-data error)
  (latency (min 2) (max 16))
  (timing-policy
    (back-to-back queued)
    (queue-depth 1)
    (overflow reject)))
```

The selected requester response surface also requires an accepted pulse:

```text
(response
  (accepted accepted)
  (busy busy)
  (status status width 2)
  (done done)
  (read-data last_read_data width 32)
  (error last_error))
```

The completer policy is an optional nested clause under the existing
`apb-completer` transfer block:

```text
(transfer apb_complete
  (setup-detect (select 1) (enable 0))
  (wait-cycles wait_cycles)
  (read register)
  (write register)
  (unmapped-address error)
  (timing-policy
    (setup-admission adjacent)))
```

No new top-level `apb-composition` timing clause is selected in this first
contract. Composition support is derived from compatible endpoint policies.

## Requester Semantics

The selected requester policy models at most one active APB transfer and one
queued next transfer.

- `accepted` pulses when a `start` request is sampled into either the active
  transfer slot or the empty queued slot.
- All request payload fields are sampled at acceptance time, including
  address, write bit, write data, and selected sidebands such as `PPROT` and
  `PSTRB` when present.
- `queue-depth 1` means exactly one pending transfer may wait behind the active
  APB transfer.
- `(overflow reject)` means a `start` assertion while the active transfer and
  queued slot are both occupied is not sampled, does not overwrite the queued
  request, and does not pulse `accepted`.
- Each completed transfer still pulses `done` once and updates
  `last_read_data`, `last_error`, and the selected 2-bit `status` encoding.
- When a queued request exists as the active transfer completes, the requester
  may drive the queued request's setup phase in the next cycle with
  `PSEL=1` and `PENABLE=0`, rather than inserting an idle APB bus cycle.
- On a completion cycle that launches the next setup, completion reporting has
  precedence for `done` and `status`; `busy` remains asserted because another
  APB transfer is active or queued.
- Reset clears both the active and queued slots and deasserts `accepted`,
  `busy`, `done`, `PSEL`, and `PENABLE`.

The existing `latency (min 2) (max 16)` contract remains per completed
transfer. The selected policy does not widen APB outstanding semantics beyond
one active bus transfer.

## Completer Semantics

`(setup-admission adjacent)` records that the completer has no internal
idle-cycle requirement between APB accesses. A completer with this policy must
admit every setup cycle that satisfies the selected APB setup detector:

```text
PSEL && !PENABLE
```

including a setup cycle that immediately follows the prior access response.
The completer still completes one APB access at a time and does not create its
own queue. Existing wait-cycle, register read/write, sideband, byte-lane, and
register-local protection-policy behavior stays endpoint-local.

## Composition And Interconnect Propagation

For the first fixed one-requester/one-completer composition implementation,
the source must carry compatible requester and completer timing policies:

- the embedded requester transfer must select `(back-to-back queued)`;
- the embedded completer transfer must select `(setup-admission adjacent)`;
- the composition must propagate the selected endpoint behavior without
  inserting an idle cycle between completed access and queued setup;
- the fixed composition report must surface an aggregate back-to-back policy
  section and remove broad `apb_back_to_back_policy_deferred` residue only for
  the selected fixed-composition sample family.

Multi-peripheral composition is not part of the `.607` first implementation
owner. `.609` later validates the selected 32-bit no-sideband two-peripheral
status family: every peripheral endpoint selects compatible adjacent setup
admission, the generated interconnect does not insert an idle cycle, and
response muxing remains deterministic for an access immediately followed by a
setup to the same or a different peripheral. Broader multi-peripheral
timing-policy variants still retain narrowed future-policy residue until
future exact owners ship them.

## First Supported Sample Family

The selected first implementation sample family is deliberately fixed-
composition and status-observable:

- `ppif/apb_requester_transfer_status_back_to_back.ppif`
- `ppif/apb_requester_transfer_status_back_to_back.apb`
- `ppif/apb_completer_back_to_back.ppif`
- `ppif/apb_completer_back_to_back.apb`
- `ppif/apb_composition_status_back_to_back.ppif`
- `ppif/apb_composition_status_back_to_back.apb`

Selected support-accounting identities:

- `intent.ppif_apb_requester_transfer_status_back_to_back`
- `intent.apb_profile_alias_requester_transfer_status_back_to_back`
- `intent.ppif_apb_completer_back_to_back`
- `intent.apb_profile_alias_completer_back_to_back`
- `intent.ppif_apb_composition_status_back_to_back`
- `intent.apb_profile_alias_composition_status_back_to_back`

The first fixed-composition sample keeps the existing 32-bit APB data path,
one address-0 register completer, explicit `busy`, 2-bit `status`, and new
`accepted` response pulse. Sideband/data16/protection back-to-back samples are
not part of `.607`; they stay later exact owners after the base timing policy
is proven.

## Report Movement

Selected reports add structured timing-policy metadata under the existing
transfer report:

```json
"timing_policy": {
  "back_to_back": "queued",
  "queue_depth": 1,
  "overflow": "reject",
  "accepted": "accepted"
}
```

Completer reports add:

```json
"timing_policy": {
  "setup_admission": "adjacent"
}
```

Fixed-composition reports add an aggregate policy section derived from the
compatible endpoint reports. The selected requester, completer, and fixed-
composition sample reports remove broad `apb_back_to_back_policy_deferred` and
replace it with narrower future-work residue such as
`apb_additional_back_to_back_policies_deferred`.

The narrower residue covers deeper queues, alternate overflow policies,
accepted-less request surfaces, multiple outstanding APB transfers,
sideband/data16/protection variants, multi-peripheral interconnect propagation
beyond the selected `.609` no-sideband status family, direct backend lowering,
verification-output generation, backend-language variants, AXI, AHB, and VHDL.

## Implementation Result

`IAL2-FEATURE-COMPLETENESS-FRONTIER.607` implements the first selected sample
family. See `docs/IAL2_APB_BACK_TO_BACK_BEHAVIOR.md` for the shipped requester
accepted/queued behavior, completer adjacent setup-admission behavior, fixed
composition propagation, reports, support-accounting identities, validation,
and remaining deferrals.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.609` later implements the selected
32-bit no-sideband two-peripheral status multi-peripheral propagation family.
See `docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md`.

## Diagnostics

The `.607` implementation should reject at least:

- a requester `(timing-policy ...)` without `(back-to-back queued)`,
  `(queue-depth 1)`, or `(overflow reject)`;
- `queue-depth` values other than `1`;
- requester back-to-back policy without response `(accepted NAME)`,
  `(busy NAME)`, and `(status NAME width 2)`;
- requester accepted, busy, status, done, read-data, error, request, bus, or
  generated-local name collisions;
- completer `(timing-policy ...)` without `(setup-admission adjacent)`;
- fixed composition where requester and completer timing policies are missing
  or incompatible;
- any top-level composition timing clause in the first slice;
- multi-peripheral back-to-back timing policy outside the selected `.609`
  no-sideband status family until exact owners ship those variants;
- `.apb` aliases whose generated `.isf`/`.fsm` review artifacts or report
  source identity differ from their `.ppif` twins.

Until `.607` changes the parser, the current fail-closed unsupported-clause
diagnostics remain correct for `(timing-policy ...)`.

## Validation Plan

The `.607` implementation should include:

- focused parser/generator tests for requester, completer, fixed composition,
  `.ppif`, and `.apb` alias twins;
- schedule JSON checks proving timing-policy metadata and residue migration;
- check JSON and semantic JSON checks preserving source identity and selected
  support-accounting IDs;
- outdir checks proving generated `.isf` and `.fsm` review artifacts;
- HDL checks proving `accepted`, `busy`, `done`, `status`, `PSEL`, and
  `PENABLE` behavior for idle acceptance, queued acceptance, overflow reject,
  completion with no queue, and completion that launches queued setup;
- negative diagnostics for unsupported policy shapes and incompatible
  composition endpoints;
- mdBook, README, ROADMAP_V2, task-tree, Memory, Knowledge Map, and doctrine
  gates.

## Rollback

This `.606` slice is documentation and tracking only. Rollback is reverting
this contract-selection document, its Knowledge Map card, and the roadmap/book/
task-tree/memory pointers. Because no parser, generator, sample,
support-accounting, validation, generated-artifact, JSON, HDL/runtime, suffix,
direct-backend, verification-output, backend-language, AXI, AHB, or VHDL
behavior changes, there is no runtime behavior rollback.

## Deferred Work

- requester policies without public `accepted`;
- queue depths greater than one;
- alternate overflow policies beyond `reject`;
- multiple active APB bus transfers;
- sideband/data16/protection back-to-back samples;
- multi-peripheral interconnect propagation;
- remaining APB widths and additional protection-policy families;
- direct IAL2-to-backend lowering;
- verification-output generation;
- backend-language variants;
- AXI, AHB, and VHDL behavior.
