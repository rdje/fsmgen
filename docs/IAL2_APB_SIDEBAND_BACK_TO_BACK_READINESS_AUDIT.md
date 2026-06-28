# IAL2 APB Sideband Back-To-Back Readiness Audit

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.611`
- Date: `2026-06-28`
- Status: selected next implementation owner
- Scope: APB sideband-aware back-to-back timing-policy readiness only

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.611` audits the next APB timing-policy
residue after the selected no-sideband fixed and multi-peripheral
back-to-back families shipped.

The result is ready for a narrow requester-first implementation owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.612`. No new public timing-policy
vocabulary is needed before that implementation. `.606` already selected
requester `(timing-policy (back-to-back queued) (queue-depth 1) (overflow
reject))`, requester `accepted`, and the semantic rule that all request payload
fields are sampled at acceptance time, including sidebands when present.

The next owner should implement only the 32-bit sideband-aware APB requester
back-to-back queue capture surface. Fixed composition, multi-peripheral
composition, data16/protection variants, deeper queues, alternate overflow
policies, accepted-less requester surfaces, multiple active APB transfers,
direct backend lowering, verification-output generation, backend-language
variants, AXI, AHB, and VHDL stay deferred.

This audit changes no parser behavior, generator behavior, samples,
support-accounting catalog entries, generated artifacts, schedule/check JSON,
semantic JSON, HDL/runtime behavior, suffix acceptance, direct backend
lowering, verification-output generation, backend-language variants, APB
behavior, AXI behavior, AHB behavior, or VHDL behavior.

## Evidence Read

The audit read:

- `docs/IAL2_POST_APB_MULTI_PERIPHERAL_BACK_TO_BACK_NEXT_SLICE_SELECTION.md`;
- `docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md`;
- `docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_READINESS_AUDIT.md`;
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
- selected APB `.ppif` samples;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and relevant
  decisions.

Live schedule probes over the shipped sideband, sideband data16, and sideband
data16 protection requester/composition samples confirmed that
`apb_back_to_back_policy_deferred` remains present on the top report and child
report surfaces. That residue remains explicit even after `.607` and `.609`
removed the broad residue for selected no-sideband back-to-back surfaces.

## Current Requester Shape

The shipped sideband requester already has the public payload fields required
by the `.606` timing-policy contract:

```text
(protection req_prot width 3)
(write-strobe req_wstrb width 4)
```

and the generated requester already samples those fields in the normal
one-transfer-at-a-time path:

```text
(sample req_prot as prot)
(sample req_wstrb as wstrb)
```

The current back-to-back patch path is still no-sideband-only. The generated
queue locals are:

```text
queued_valid
queued_addr
queued_write
queued_wdata
```

and queued capture/relaunch stores and drives only address, write bit, and
write data. It does not yet store `PPROT` or `PSTRB`.

The static guard intentionally rejects the candidate sideband requester policy
today:

```text
APB requester-transfer IAL2 contract selected back-to-back timing-policy
supports only the 32-bit no-sideband requester family in this slice
```

A temporary `/tmp` sideband requester candidate with `accepted` plus the
selected timing-policy clause failed exactly at that guard. The temporary
candidate was removed after the probe.

## Completer And Composition Findings

The sideband completer substrate already samples `PADDR`, `PWRITE`, `PWDATA`,
`PPROT`, `PSTRB`, and `wait_cycles` on `PSEL && !PENABLE`, applies `PSTRB`
byte lanes to selected writes, and applies endpoint-local PPROT access policy
for the selected protection samples.

The selected adjacent setup policy is still guarded to the no-sideband
one-register completer family. Existing sideband public completer and
composition samples are multi-register or multi-peripheral shapes, so
composition-wide timing-policy propagation should not be bundled into the
first requester queue-capture implementation.

The fixed and multi-peripheral composition wiring already propagates
`PPROT/PSTRB` for sideband-aware samples. However, `ApbComposition` still
rejects selected timing-policy endpoints whenever the wiring is sideband-aware,
and multi-peripheral timing-policy validation is also bounded to the
no-sideband two-peripheral family. Those guards should remain until a later
exact owner selects composition propagation after requester queue capture is
proven.

## Selected Next Owner

`.612` shall implement the bounded requester-first APB sideband back-to-back
slice.

The next implementation owner should add only the selected public sample
family:

```text
ppif/apb_requester_transfer_sideband_status_back_to_back.ppif
ppif/apb_requester_transfer_sideband_status_back_to_back.apb
```

Selected requester requirements:

- 32-bit APB data and 32-bit APB address;
- request `protection width 3` and `write-strobe width 4`;
- bus `PPROT width 3` and `PSTRB width 4`;
- response `accepted`, `busy`, `status width 2`, `done`, `read-data`, and
  `error`;
- transfer `(timing-policy (back-to-back queued) (queue-depth 1) (overflow
  reject))`.

Selected behavior and report expectations:

- queue locals include `queued_prot` and `queued_wstrb`;
- queued capture stores `req_prot` and `req_wstrb` exactly when `accepted`
  pulses into the queued slot;
- queued relaunch drives `PPROT` from `queued_prot` and drives `PSTRB` from
  `queued_wstrb` masked by the queued write bit;
- direct terminal-cycle acceptance into an empty active slot continues to
  sample and drive the current request payload, including sidebands;
- report `transfer.timing_policy` stays the `.606` policy shape;
- selected sideband requester reports remove broad
  `apb_back_to_back_policy_deferred` and retain narrowed
  `apb_additional_back_to_back_policies_deferred` for composition propagation,
  data16/protection variants, deeper queues, alternate overflow policies,
  multiple active APB transfers, and backend/VHDL work.

## Validation Target For `.612`

The implementation owner should cover:

- parser/static diagnostics for missing `accepted`, missing selected
  timing-policy, unsupported queue depth, unsupported overflow policy,
  data16/protection/composition timing-policy attempts, and missing sideband
  bundle fields;
- `.ppif` and `.apb` profile-alias parity for generated `.isf` and `.fsm`;
- schedule JSON, strict check JSON, strict semantic JSON, generated review
  artifacts, and HDL shape for the two new requester sources;
- generated `.fsm` evidence that queued `PPROT/PSTRB` are captured and
  relaunched without an inserted idle cycle;
- support-accounting and capability-manifest updates;
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map sync; and
- docs/doctrine closeout gates.

## Deferred Work

The next owner must not widen into fixed composition, multi-peripheral
composition, completer timing-policy propagation, data16/protection
back-to-back variants, queue-depth greater than 1, alternate overflow,
accepted-less requester surfaces, multiple active APB transfers, direct
backend lowering, verification-output generation, backend-language variants,
AXI, AHB, or VHDL behavior.

## Validation

Audit validation used documentation/code review, live report probes, and one
temporary fail-closed candidate:

```bash
perl -MJSON::PP=decode_json -e 'for my $path (@ARGV) { my $json = qx(./bin/fsmgen --quiet --emit-schedule-json $path); die "fsmgen failed for $path\n" if $?; my $doc = decode_json($json); my $report = $doc->{protocol_intent} || $doc; my @residue = map { $_->{id} // () } @{ $report->{unsupported_residue} || [] }; print "$path\n  top: " . join(",", @residue) . "\n"; }' ppif/apb_requester_transfer_sideband.ppif ppif/apb_requester_transfer_sideband_data16.ppif ppif/apb_composition_multi_register_sideband.ppif ppif/apb_composition_multi_peripheral_sideband.ppif
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-apb-requester-sideband-btb-candidate.ppif
```

The temporary candidate produced the current requester guard diagnostic and was
removed. Closeout also runs Knowledge Map, mdBook, docs path, memory, diff,
and doctrine gates.

## Rollback

Rollback is doc-only: revert this audit, its fact card, task-tree frontier
updates, README, ROADMAP_V2, mdBook, Memory, and generated Knowledge Map
changes. The `.607` and `.609` no-sideband back-to-back behavior and all
current sideband parser/generator/runtime behavior remain unchanged.
