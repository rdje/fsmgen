# AXI IAL2 Manager Post Multiple Dynamic Runtime Validation Next-Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.265`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.266`, readiness audit for generated
multiple dynamic multi-beat read-data output-bank behavior over the generated
multiple dynamic read runtime-validation boundary shipped in `.264`.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.264` multiple dynamic runtime beat-count/`RLAST` behavior:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md`
- `.263` multiple dynamic report-only raw-`ARLEN` behavior:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_BEHAVIOR.md`
- `.262` burst-length/runtime public contract selection.
- `.259` multiple dynamic scalar read-data behavior.
- `.255` multiple dynamic read burst-last/`RLAST` response-demux behavior.
- `.251` multiple dynamic read single-beat response-demux behavior.
- `.243` single-active dynamic multi-beat output-bank behavior.
- `.242` single-active dynamic multi-beat readiness audit.
- Current implementation boundaries in
  `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`, especially
  `_read_data_response_demux_transaction_coverage`,
  `_dynamic_read_response_demux_covers_multi_beat_boundary`,
  `_read_data_covers_multi_beat_by_rid_interleaving`,
  `_read_data_covers_bounded_multi_beat_burst_output`,
  `_read_data_multi_beat_output_init_rule_lines`, and
  `_read_data_capture_rule_lines`.
- Current README, `ROADMAP_V2.md`, mdBook, task tree, Memory, and Knowledge Map
  state.

## Why `.266` Is Next

`.260` ordered the remaining read-data-adjacent multiple dynamic work as:

1. burst-length metadata over multiple dynamic read demux;
2. runtime beat-count/`RLAST` validation over that metadata; and
3. multi-beat output banks over the runtime-validation boundary.

`.263` and `.264` complete the first two items. The shipped `.264` runtime
sample now provides the prerequisite state for every generated all-dynamic read
transaction: raw `ARLEN` storage, expected-beat storage, read-beat counter
storage, request-time initialization, matched-read-beat counter increments, and
runtime `RLAST` assertions.

The remaining read-data residue on the `.264` runtime sample is:

```text
multi_beat_read_data_reassembly
per_beat_outputs
rresp_aggregation
```

That is the same class of residue that `.243` resolved for the single-active
dynamic runtime-validation shape. The multiple dynamic version should not jump
directly to implementation because the live admission code still treats dynamic
multi-beat burst-length coverage as single-active only, while scalar
last-beat burst-length/runtime coverage is now multi-transaction. The output
bank helpers are transaction-list shaped after admission, but the audit must
settle the public multi-transaction source shape, report vocabulary,
diagnostics, validation, and residue before any behavior changes.

## Scope For `.266`

`.266` must audit whether generated multiple dynamic multi-beat output-bank
behavior can be implemented directly, needs a public contract-selection slice
first, requires helper/report cleanup, or should defer behind a smaller
prerequisite.

The audit should cover:

- two or more all-dynamic read transactions;
- generated `response-demux.read` with `response-scope burst-last`, one-bit
  `last-signal`, generated transaction completion, and
  `generated_dynamic_demux_last_beat` completion source;
- `read-data.read capture-scope multi-beat`;
- `completion-source response-demux`;
- `status-policy per-beat`;
- `status-aggregation worst-observed`;
- `interleaving multi-beat-by-rid`;
- runtime-assertion `burst-length` metadata with request-captured `ARLEN`;
- complete exactly-once output-bank bindings for every generated dynamic read
  demux transaction;
- per-transaction data-output prefixes, status-output prefixes, valid-mask
  outputs, length outputs, and scalar status aggregate outputs;
- lane capture from raw matched dynamic read beats, not final `RID && RLAST`
  completion pulses;
- request-time clearing/initialization for every transaction's output bank;
- report fields for output-bank shape, lane outputs, valid masks, length
  outputs, aggregate status outputs/rules, generated runtime state, generated
  assertions, and residue movement;
- diagnostics for missing, partial, duplicate, extra, or mismatched
  multi-beat transaction bindings; and
- focused dynamic validation, support-accounting expectations, direct
  schedule/check/semantic/HDL probes, rollback, and temporary-artifact cleanup.

## Non-Goals

`.265` changes no behavior.

`.266` is an audit owner unless it explicitly selects a later implementation or
contract-selection leaf. It must not implement behavior by accident.

Mixed dynamic/static demux, same-cycle request widening beyond the existing
onehot0 policy, same-cycle release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain later exact owners.

## Validation

Selector validation is documentation and continuity only:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No focused generator, parser, support-accounting, schedule/check/semantic, or
HDL probes are required because `.265` changes no behavior.

## Rollback

Rollback is the `.265` selector commit. Reverting it restores `.265` as the
active post-runtime exact-owner selector and removes the `.266` readiness-audit
owner.
