# IAL2 APB Back-To-Back Transfer Policy Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.605`

Date: 2026-06-27

## Summary

`.605` audits APB back-to-back transfer policy readiness after the shipped
sideband data16 `PPROT` policy behavior. It selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.606`, public APB back-to-back transfer
policy contract selection, before any behavior change.

The audit changes no parser behavior, generator behavior, source samples,
support-accounting catalog entries, validation behavior, generated artifacts,
report schemas, schedule/check JSON, semantic JSON, HDL/runtime behavior,
suffix acceptance, direct backend lowering, verification-output generation,
backend-language variants, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior.

## Evidence Read

The audit read `.604`, `.603`, `.602`, `.601`, `.600`, `.599`, `.598`,
`.597`, `.594`, and `.589`; APB behavior/profile docs; live APB
`unsupported_residue` schedule reports; `perl/FSM/Adapter/IAL2/PPIF.pm`;
`perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm`;
`perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm`;
`perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm`;
`perl/FSM/Support/RegressionCorpus.pm`;
`perl/FSM/Support/LanguageSurfaceSection.pm`; focused APB tests; README;
ROADMAP_V2; mdBook; task tree; Memory; Knowledge Map; and relevant
IAL2/backend/VHDL decisions.

Live schedule-report probes reconfirmed that the selected APB surfaces still
carry explicit back-to-back residue:

- `ppif/apb_requester_transfer_status.ppif` keeps
  `apb_back_to_back_policy_deferred` with requester queued-transfer wording.
- `ppif/apb_completer_multi_register_sideband_data16_protection.ppif` keeps
  `apb_back_to_back_policy_deferred` with setup-admission wording.
- `ppif/apb_composition_multi_register_sideband_data16_protection.ppif` keeps
  `apb_back_to_back_policy_deferred` at the fixed-composition level and in the
  requester/completer child reports.
- `ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif`
  keeps `apb_back_to_back_policy_deferred` at the composition, interconnect,
  requester, and peripheral-completer report surfaces.

## Current Boundary

The current parser has no public back-to-back, queue, admission, or timing
policy vocabulary. APB requester `(transfer ...)` clauses are limited to
`setup`, `access`, `complete-on`, `sample`, and `latency`; APB completer
transfer clauses are limited to `setup-detect`, `wait-cycles`, `read`, `write`,
and `unmapped-address`; APB composition has no timing-policy clause.

The generated requester models one active transfer at a time:

- it samples request fields on `start`;
- drives setup with `PSEL=1` and `PENABLE=0`;
- drives access with `PENABLE=1`;
- awaits `PREADY`;
- samples `PRDATA` and `PSLVERR`;
- drives a terminal phase that deasserts `PSEL/PENABLE`, publishes read/error
  status, and completes through `done`.

The generated requester report states `single_outstanding_transfer`, and its
rules describe deasserting `PSEL/PENABLE` at the done pulse. That is not a
public no-idle back-to-back contract.

The generated completer also models one active transfer at a time:

- it admits setup only when `PSEL && !PENABLE`;
- samples address, write, data, sidebands, and wait count at setup;
- drives `PREADY` low during the wait path;
- completes the selected mapped, denied, or unmapped response through the
  existing response point.

The generated completer report also states that each bounded map models one
transfer at a time. Existing behavior may be structurally close to accepting a
new setup after a completed response, but no report or public source contract
promises adjacent-transfer admission.

Composition is propagation-only for this question. Fixed composition wires the
requester bus to the completer bus directly. Multi-peripheral composition
generates `apb_interconnect.isf` and `apb_interconnect.fsm` to decode `PSEL`,
translate local `PADDR`, fan out control/data/sidebands, mux selected
responses, and return an unmapped active-access error. Neither composition
surface selects a timing policy for adjacent requester admissions.

## Readiness Findings

APB back-to-back work is ready to proceed to public contract selection. No
lower-layer, report-static, public-surface cleanup, or mdBook prerequisite is
selected before `.606`.

The next slice must be contract selection rather than implementation because
the public boundary is still unsettled:

- whether back-to-back is implicit APB handshake conformance or an explicit
  opt-in generated requester policy;
- when request inputs are sampled if `start` is asserted while a transfer is
  busy or exactly as `PREADY` completes;
- whether the first policy has a one-entry pending queue, requires the producer
  to hold request fields until acceptance, or exposes a future ready/accepted
  signal;
- whether `done`, `busy`, and 2-bit `status` pulse for every completed
  transfer when adjacent transfers are issued;
- whether selected 32-bit, sideband, data16, and protection APB sample
  families all move together or whether the implementation should start with a
  narrower status-capable subset;
- which reports and support-accounting identities prove the selected timing
  policy.

The existing generated IAL1/IAL0 substrate is sufficient for contract
selection. It already has storage, locals, conditional actions, waits,
comparisons, bit/boolean expressions, and generated composition/interconnect
review artifacts. `.606` should still choose validation that proves the exact
lowering before behavior work starts.

The audit does not split ownership by requester, completer, and composition
yet. Splitting before public contract selection would force private
assumptions about requester queued admission and composition propagation.
`.606` should select the public contract and may then choose a single bounded
implementation owner or split implementation into requester-first,
completer/composition propagation, and report/support cleanup leaves.

## Selection

`.606` shall select the public APB back-to-back transfer policy contract.

The contract selection must decide:

- exact public source vocabulary, if any, for back-to-back or queued-admission
  policy on requester, completer, and composition shapes;
- whether the first selected surface is requester-only, requester plus
  completer, fixed composition, multi-peripheral composition, or a bundled APB
  sample family;
- whether the policy is explicit opt-in, default APB behavior, or a named
  timing-policy variant;
- requester queued-admission semantics, including request sampling point,
  pending depth, behavior when a second request arrives while a pending request
  already exists, and interaction with `busy`, `done`, `last_error`,
  `last_read_data`, and 2-bit `status`;
- required APB waveform shape, especially whether the requester keeps `PSEL`
  asserted and toggles `PENABLE` low for the next setup in the cycle after a
  completed access;
- completer setup-admission semantics for an immediately following
  `PSEL && !PENABLE` setup after the previous response;
- fixed composition propagation expectations;
- multi-peripheral interconnect propagation, decode, local-address, response
  mux, and unmapped active-access expectations across adjacent transfers;
- report fields, `unsupported_residue` migration, and whether child reports
  retain or remove back-to-back residue separately from top-level reports;
- support-accounting identities and sample names;
- parser/static diagnostics for unsupported queue depths, missing policy
  clauses, policy placement, unsupported source shapes, width/policy
  combinations, and profile-alias parity;
- focused validation covering schedule JSON, check JSON, semantic JSON,
  generated `.isf`/`.fsm`, HDL shape, profile-alias parity, support
  accounting, capability-manifest language surface, and mdBook examples;
- rollback boundaries; and
- direct-backend, verification-output, backend-language, AXI/AHB, and VHDL
  deferral.

## Non-Goals

`.605` and `.606` do not implement back-to-back behavior. `.606` is a
contract-selection owner, not a behavior owner.

This audit does not add parser acceptance, sample files, support identities,
generated behavior, report schema fields, runtime timing changes, direct
IAL2-to-IAL0 lowering, direct backend lowering, verification-output
generation, backend-language variants, APB behavior, AXI behavior, AHB
behavior, or VHDL behavior.

Additional `PPROT` predicates, global/window/peripheral/interconnect-owned
policies, runtime-programmable policies, remaining APB widths, multiple
requesters, bus matrices, scoreboards, AXI follow-on, AHB follow-on, direct
backend, verification-output, backend-language variants, and VHDL remain
deferred unless a later exact owner selects them.

## Validation

The audit validation is documentation and static-surface focused:

```bash
rg -n 'apb_back_to_back_policy_deferred|single_outstanding_transfer|setup admission|queued transfer admission' \
  perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm \
  perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm \
  perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm \
  perl/FSM/Support/LanguageSurfaceSection.pm \
  docs/IAL2_POST_APB_DATA16_PPROT_NEXT_SLICE_SELECTION.md
./bin/fsmgen --emit-schedule-json ppif/apb_requester_transfer_status.ppif
./bin/fsmgen --emit-schedule-json ppif/apb_completer_multi_register_sideband_data16_protection.ppif
./bin/fsmgen --emit-schedule-json ppif/apb_composition_multi_register_sideband_data16_protection.ppif
./bin/fsmgen --emit-schedule-json ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is doc-only: revert this audit, its fact card, task-tree frontier
updates, README, ROADMAP_V2, mdBook, Memory, and generated Knowledge Map
changes. The `.603` data16 protection behavior, `.604` selector, and all
existing APB parser/generator/sample/report/runtime behavior remain unchanged.
