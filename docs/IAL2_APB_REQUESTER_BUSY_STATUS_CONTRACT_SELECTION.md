# IAL2 APB Requester Busy/Status Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.571`

Date: 2026-06-27

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.571` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.572`, direct bounded implementation of an
additive APB requester `busy` output contract for generated requester-transfer
and fixed requester/completer composition IAL2 sources.

This selector changes no parser, generator, sample, support-accounting,
manifest, test, schedule/check/semantic JSON, HDL/runtime, direct backend,
verification-output, backend-language variant, AXI, APB, or VHDL behavior.

## Evidence Read

The selector read the shipped APB requester/composition surfaces and current
residue:

- `.570` post-alias-widening next-slice selector;
- `.569` APB `.apb` alias widening behavior;
- `.566` APB fixed composition behavior;
- `.550` APB requester-transfer behavior;
- current requester/composition reports and `apb_requester_busy_status_deferred`;
- lower-layer `fsm/apb_requester.fsm` and `fsm/apb_tb.fsm`, which already
  expose public `busy`;
- `RegressionCorpus` APB `.ppif` and `.apb` support entries;
- `LanguageSurfaceSection` `.ppif` and `.apb` boundaries;
- focused APB requester/profile-alias/composition tests; and
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map.

Current generated requester and fixed composition IAL2 reports expose:

```text
done
last_error
last_read_data
```

They do not expose `busy`. The residue is explicit:

```text
apb_requester_busy_status_deferred
```

The lower-layer direct fixtures provide the selected behavior precedent:

```text
fsm/apb_requester.fsm -> public busy output on apb_requester
fsm/apb_tb.fsm        -> public busy output on apb_tb
```

## Selected Public Contract

The next behavior slice must be additive: existing shipped APB requester and
composition samples remain unchanged and keep their current public port shapes.

The first generated IAL2 status widening exposes only a one-bit `busy` output.
Named multi-bit status enums or status-code fields remain deferred.

The selected source syntax adds an optional `busy` binding to an APB requester
`response` block:

```text
(response
  (busy busy)
  (done done)
  (read-data last_read_data width 32)
  (error last_error))
```

The first busy-capable public samples are:

```text
ppif/apb_requester_transfer_busy.ppif
ppif/apb_requester_transfer_busy.apb
ppif/apb_composition_busy.ppif
ppif/apb_composition_busy.apb
```

The busy requester-transfer samples must lower through generated
`apb_requester.isf` and `apb_requester.fsm`, generate HDL module
`apb_requester`, and expose `busy`, `done`, `last_error`, and
`last_read_data`.

The busy fixed-composition samples must lower through generated requester and
completer `.isf`/`.fsm` review artifacts plus generated top `apb_tb.fsm`,
generate HDL modules `apb_requester`, `apb_completer`, and `apb_tb`, and expose
top-level `busy`, `done`, `last_error`, and `last_read_data`.

The selected `busy` semantics match the direct APB fixture precedent:

- `busy` is low in idle before a transfer is accepted;
- `busy` is high after request acceptance through setup/access progress;
- `busy` remains high on the completion pulse cycle; and
- `busy` returns low after the requester returns to idle.

## Support And Source Identity

The selected support-accounting entries are:

```text
intent.ppif_apb_requester_transfer_busy
intent.apb_profile_alias_requester_transfer_busy
intent.ppif_apb_composition_busy
intent.apb_profile_alias_composition_busy
```

The selected coverage names are:

```text
ial2_ppif_apb_requester_transfer_busy_pipeline_cli
ial2_apb_profile_alias_requester_transfer_busy_pipeline_cli
ial2_ppif_apb_composition_busy_pipeline_cli
ial2_apb_profile_alias_composition_busy_pipeline_cli
```

The `.ppif` samples use `source_kind: ppif`; the `.apb` samples use
`source_kind: ial2_profile_alias`. Check JSON and semantic JSON must preserve
the authored `.ppif` or `.apb` source path.

## Report And Residue Policy

Busy-capable requester-transfer reports must not carry
`apb_requester_busy_status_deferred`. They should instead keep named status
fields explicitly deferred with a narrower residue:

```text
apb_requester_status_field_deferred
```

Busy-capable composition reports must remove
`apb_requester_busy_status_deferred` and keep the same
`apb_requester_status_field_deferred` residue. Multi-peripheral decode,
multi-register decode, sidebands/strobes, alternate widths, and back-to-back
policy remain separate residues.

Existing no-busy APB requester-transfer and composition samples remain valid
and keep their current `apb_requester_busy_status_deferred` residue until a
future owner decides whether to migrate or retire those exact samples.

## Diagnostics

The implementation owner must keep fail-closed diagnostics for:

- malformed `(busy ...)` response clauses;
- non-identifier busy signal names;
- duplicate response/bus/request/storage/generated local names;
- unsupported `(status ...)` clauses in the first busy slice;
- mixed requester/completer busy composition shapes that omit the explicit
  `(apb-composition ...)` object;
- missing profile and non-APB profile under `.apb`; and
- non-APB profile-alias source shapes.

## Validation Plan

The implementation owner should add focused coverage for:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_busy.ppif
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer_busy.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_requester_transfer_busy.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_busy.apb
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer_busy.apb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_requester_transfer_busy.apb
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_busy.ppif
./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_busy.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_composition_busy.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_busy.apb
./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_busy.apb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_composition_busy.apb
```

It should also prove generated review-artifact materialization with `--outdir`,
support-accounting coverage, capability-manifest/source-kind alignment,
existing no-busy sample preservation, targeted negative diagnostics, mdBook
synchronization, Knowledge Map synchronization, memory/doc path gates, and the
doctrine gate.

## Rejected Alternatives

Changing existing APB requester/composition samples in place is rejected
because it would change shipped public port shapes. The selected first slice is
additive and keeps current samples runnable as-is.

Selecting a named status field in the first implementation is rejected because
the lower-layer APB fixtures prove `busy`, not a status enum. Status fields can
be selected later after the busy path is generated and documented.

Implementing only `.ppif` without `.apb` aliases is rejected because `.569`
made `.apb` a current APB requester/completer/composition alias surface; new
APB requester/composition source-shape variants should keep `.ppif` and `.apb`
aligned unless a future selector explicitly splits them.

Multi-peripheral decode, multi-register decode, sidebands/strobes, alternate
widths, back-to-back transfer policy, APB report-only cleanup, another IAL2
protocol surface, direct backend, verification-output, backend-language
variant, AXI follow-on, and VHDL remain deferred.

## Rollback

Rollback of `.571` removes this selector record, its Knowledge Map fact card,
and the README/ROADMAP/mdBook/task-tree/memory updates. No runtime behavior,
source sample, parser rule, generator, support-accounting entry, test,
generated artifact, or public suffix behavior is changed by this selector.
