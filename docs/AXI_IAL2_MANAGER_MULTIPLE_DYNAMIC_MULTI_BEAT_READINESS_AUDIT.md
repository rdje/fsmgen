# AXI IAL2 Manager Multiple Dynamic Multi-Beat Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.266`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.267`, public contract selection for
bounded generated multiple dynamic multi-beat read-data output-bank behavior
over the generated multiple dynamic read runtime-validation boundary.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or used:

- `.265` post-runtime selector:
  `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md`
- `.264` multiple dynamic runtime beat-count/`RLAST` behavior:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md`
- `.263` multiple dynamic report-only raw-`ARLEN` behavior.
- `.262` burst-length/runtime public contract selection.
- `.259` multiple dynamic scalar read-data behavior.
- `.255` multiple dynamic read burst-last/`RLAST` response-demux behavior.
- `.251` multiple dynamic read single-beat response-demux behavior.
- `.243` single-active dynamic multi-beat output-bank behavior.
- `.242` single-active dynamic multi-beat readiness audit.
- The public source shapes:
  `ppif/axi_manager_capacity_status_dynamic_read_data_multi_beat.ppif` and
  `ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion.ppif`.
- Current implementation surfaces in
  `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`:
  `_read_data_response_demux_transaction_coverage`,
  `_normalize_read_data_read`,
  `_read_data_multi_beat_output_init_rule_lines`,
  `_read_data_capture_rule_lines`, `_read_data_generated_artifacts`,
  `_dynamic_read_response_demux_covers_multi_beat_boundary`,
  `_read_data_covers_multi_beat_by_rid_interleaving`, and
  `_read_data_covers_bounded_multi_beat_burst_output`.
- Focused dynamic validation surfaces in
  `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, support
  accounting in `perl/FSM/Support/RegressionCorpus.pm`, README,
  `ROADMAP_V2.md`, mdBook, task tree, Memory, and Knowledge Map.

## Guarded Probe Caveat

Two guarded schedule probes were attempted for the committed single-active
dynamic multi-beat sample and the committed multiple dynamic runtime sample:

```bash
scripts/run_with_ram_guard.sh --host-max-pct 93 --process-max-rss-mb 2048 -- ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_data_multi_beat.ppif
scripts/run_with_ram_guard.sh --host-max-pct 93 --process-max-rss-mb 2048 -- ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion.ppif
```

Inside the sandbox, the guard reported process-tree inspection unavailable.
With process-inspection approval, both probes were stopped immediately because
host memory was already above the configured cutoff (`97.0%` and `97.2%`
observed against a `93%` cutoff). The audit did not rerun these probes
unguarded. It relies on committed behavior docs, public sample source shapes,
source/test code review, and prior `.264` direct probe evidence.

## Code Findings

The remaining fail-closed boundary is local and explicit.
`_read_data_response_demux_transaction_coverage` already admits scalar
last-beat report-only/runtime burst-length metadata for one or more generated
dynamic read transactions, but it still admits multi-beat dynamic
burst-length only when the generated dynamic read transaction count is exactly
one:

```text
capture_scope multi-beat
transaction_completion_source generated_dynamic_demux_last_beat
response_scope burst_last
burst_length_validation runtime_assertion
dynamic_transaction_count == 1
```

The same coverage helper still has a later guard that rejects non-scalar
dynamic burst-length or multi-beat coverage unless the dynamic transaction set
is single-active, except for the already-shipped multi-transaction scalar
last-beat burst-length/runtime shape.

Report residue recognition is also single-active today. The helper
`_dynamic_read_response_demux_covers_multi_beat_boundary` returns true only
when `dynamic_transactions` has exactly one element. Therefore
`_read_data_covers_multi_beat_by_rid_interleaving` and
`_read_data_covers_bounded_multi_beat_burst_output` cannot yet treat a
multiple dynamic multi-beat output-bank sample as covering read-data
interleaving and burst output residue.

After coverage admission, the lower substrate is already transaction-list
driven:

- `_normalize_read_data_read` creates per-transaction generated data lanes,
  status lanes, valid masks, length outputs, optional scalar aggregate status
  outputs, raw `ARLEN` storage, expected-beat storage, read-beat counters,
  beat-count rules/assertions, output-init rule names, lane-capture rule
  names, and aggregate update rule names.
- `_read_data_multi_beat_output_init_rule_lines` iterates over
  `read_data.read.transactions` and initializes each transaction's output bank
  from that transaction's request event.
- `_read_data_capture_rule_lines` iterates over every transaction and every
  generated lane, capturing raw matched dynamic read beats when the
  transaction's beat counter matches the lane index.
- `_read_data_generated_artifacts` already aggregates multi-beat data/status
  lane outputs, valid-mask outputs, length outputs, output-init rules,
  lane-capture rules, scalar aggregate outputs/rules, burst-length storage,
  beat-count storage/rules, and beat-count assertions across the transaction
  list.

No separate IAL1, IAL0, or SystemVerilog prerequisite is visible before the
public contract is selected.

## Why `.267` Is Contract Selection

Direct implementation is too wide for `.267` without a public contract slice
first. The existing syntax is close, but the multiple dynamic multi-beat shape
needs exact ownership for:

- the public sample name and source object name;
- whether every generated dynamic read transaction must have output-bank
  bindings in the same `read-data.read` object before generation;
- diagnostics for missing, duplicate, extra, partial, or mismatched
  multi-beat transaction bindings;
- expected report vocabulary for generated multi-beat lane outputs, valid
  masks, length outputs, scalar aggregate outputs, runtime state, runtime
  assertions, and residue removal across multiple transactions;
- support-accounting entry and focused-suite behavior label;
- validation expectations and host-memory caveats for focused dynamic tests;
  and
- preservation requirements for `.263`, `.264`, `.259`, and `.243`.

Selecting the contract first keeps the later implementation leaf narrow: move
the dynamic multi-beat admission and residue-recognition gates from exactly
one dynamic transaction to the selected all-dynamic multi-transaction shape,
then prove the already list-shaped lower helpers emit the expected artifacts.

## Scope For `.267`

`.267` should select the public contract for exactly this family:

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
- complete exactly-once multi-beat output-bank bindings for every generated
  dynamic read demux transaction; and
- per-transaction data-output prefixes, status-output prefixes, scalar status
  aggregate outputs, valid-mask outputs, and length outputs.

The contract must also select sample and support-accounting names, expected
report fields, diagnostics, validation gates, docs/Knowledge Map impact,
rollback, and explicit residue.

## Non-Goals

`.266` changes no behavior.

`.267` is a contract-selection owner. It must not implement parser/generator
behavior unless it explicitly selects a later implementation leaf first.

Mixed dynamic/static demux, same-cycle request widening beyond the existing
onehot0 policy, same-cycle release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain later exact owners.

## Validation

Audit closeout validation is documentation and continuity only:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No behavior probes are required for `.266` because no behavior changes. The
attempted guarded schedule probes and their host-memory cutoff are recorded
above.

## Rollback

Rollback is the `.266` audit commit. Reverting it restores `.266` as the
active multiple dynamic multi-beat readiness audit and removes the `.267`
contract-selection owner.
