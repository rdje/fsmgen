# IAL2 Post AHB Profile-Alias Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.701`

Date: 2026-06-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.701` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.702`, an AHB completer/subordinate
readiness audit after the bounded AHB requester `.ppif` source and `.ahb`
profile alias both shipped.

This selector changes no parser, generator, source sample, support-accounting
entry, capability manifest, test behavior, schedule/check/semantic JSON,
generated artifact, HDL/runtime behavior, direct backend behavior,
verification-output generation, backend-language variant, AXI, APB, or VHDL
behavior.

## Evidence Read

The selector read the current shipped AHB surfaces:

- `ppif/ahb_requester.ppif`, the bounded generic AHB requester IAL2 source;
- `ppif/ahb_requester.ahb`, the bounded AHB requester profile alias;
- direct `fsm/amba_requester.fsm`, the older cycle-level requester seed;
- AHB requester behavior and AHB profile-alias behavior records;
- the AHB mdBook current-boundary chapter;
- `FSM::Adapter::IAL2::PPIF` AHB requester parsing and suffix validation;
- `FSM::IAL2::ProtocolIntent::AhbRequester` report/residue behavior;
- `RegressionCorpus` and `LanguageSurfaceSection` AHB entries;
- focused AHB tests; and
- README, ROADMAP_V2, task tree, Memory, and Knowledge Map.

Exact probes revalidated the current public requester boundary:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ahb
```

The generic `.ppif` requester report preserves
`ahb_profile_alias_deferred` for compatibility. The `.ahb` alias removes that
stale alias residue, but both public IAL2 AHB reports still keep the broader
AHB residue explicit:

```text
ahb_completer_subordinate_deferred
ahb_interconnect_decode_deferred
ahb_full_manager_deferred
ahb_verification_output_deferred
```

Current repository evidence is requester-only. The direct AHB seed is
`fsm/amba_requester.fsm`; there is no shipped AHB completer/subordinate `.fsm`,
`.ppif`, or `.ahb` fixture, and there is no AHB completer/subordinate
ProtocolIntent generator. That makes readiness audit the correct next owner
before any public contract or implementation.

## Selection

The next owner is a readiness audit, not implementation:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.702
```

`.702` must audit whether AHB completer/subordinate work is ready for public
contract selection, including:

- lower-layer evidence or required seed fixtures for a bounded AHB
  completer/subordinate;
- whether the first object should be spelled `ahb-completer`,
  `ahb-subordinate`, or another explicitly selected vocabulary;
- the minimal bounded source shape and required profile policy;
- required AHB-side signal bindings, including subordinate-side ready/response
  semantics;
- generated `.isf` before generated `.fsm` review-artifact expectations;
- report schema, residue, and support-accounting identity candidates;
- diagnostics for missing profile, wrong profile, mixed requester/subordinate
  objects, unsupported fields, and unsupported widths;
- whether `.ppif` must ship before any `.ahb` alias for the subordinate shape;
- validation probes and focused test scope; and
- rollback.

The selector favors completer/subordinate readiness because it is the first
explicit broader AHB residue after requester `.ppif` and `.ahb` support. AHB
interconnect/decode depends on at least one selected subordinate endpoint
shape; full-manager behavior and scoreboards are broader still.

## Rejected Alternatives

Immediate AHB completer/subordinate implementation is rejected because there
is no selected public source vocabulary, generated-artifact contract, report
schema, diagnostic policy, support-accounting identity, or lower-layer
subordinate seed yet.

AHB interconnect/decode readiness is rejected as the next owner because it
needs requester plus subordinate endpoint contracts before topology, decode,
arbitration, bus-matrix, or aggregate top behavior can be selected.

Full AHB manager behavior is rejected as the next owner because the current
public AHB IAL2 surface intentionally remains a bounded requester, not a full
manager or bus fabric.

Profile-alias public-surface cleanup is rejected because `.700` already moved
`.ahb` into the shipped language surface and synchronized current `.axi`,
`.apb`, and `.ahb` wording. Any remaining pre-`.700` wording is dated history.

Report/residue cleanup alone is rejected because the current residue accurately
names real future AHB owners.

AXI, APB, direct backend, verification-output, backend-language variants, and
VHDL are rejected because the AHB surface now has a narrow next protocol-local
residue with clear ordering.

## Validation

The selector is validated with:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ahb
rg -n 'ahb_completer_subordinate_deferred|ahb_interconnect_decode_deferred|AHB completer/subordinate generation|AHB interconnect/decode generation' \
  docs/IAL2_POST_AHB_PROFILE_ALIAS_NEXT_SLICE_SELECTION.md \
  docs/IAL2_AHB_REQUESTER_PPIF_BEHAVIOR.md \
  docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md \
  docs/book/src/16c-ial2-ahb.md
```

The final `.701` closeout reruns Knowledge Map, mdBook, memory, docs path,
diff, and doctrine gates.

## Rollback

Rollback of `.701` removes this selector record, its Knowledge Map fact card,
and the README/ROADMAP/mdBook/task-tree/Memory updates. No runtime behavior,
source sample, parser rule, generator, support-accounting entry, test,
generated artifact, public suffix behavior, direct backend behavior, or
backend-language behavior is changed by this selector.
