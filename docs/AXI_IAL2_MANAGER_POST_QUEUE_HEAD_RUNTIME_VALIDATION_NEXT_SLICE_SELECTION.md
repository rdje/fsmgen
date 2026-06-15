# AXI IAL2 Manager Post Queue-Head Runtime Validation Next-Slice Selection

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.120`.

Date: `2026-06-15`.

## Purpose

This selector follows generated queue-head beat-count/`RLAST` runtime
validation for the bounded read burst-last concrete same-ID queue-head
last-beat read-data shape from `.119` and chooses the next exact
queue-head/read-data expansion.

The selected next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.121`:
generated multi-beat read-data output-bank behavior for the bounded read
burst-last concrete same-ID queue-head demux shape.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes in this selector.

## Evidence Read

- `.119` behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md`
- `.118` selector:
  `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md`
- `.117` report-only queue-head burst-length behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md`
- `.115` queue-head last-beat read-data behavior:
  `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md`
- auto-ID beat-count/`RLAST` runtime validation:
  `docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md`
- auto-ID multi-beat metadata and output-bank behavior:
  `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md`
  and
  `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md`
- `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- focused generator and PPIF/CLI tests.

Live schedule probes confirmed the current shipped surface:

```text
read_last_beat_same_id_queue_head_burst_length_runtime_assertion:
  response_demux.read.response_scope: burst_last
  response_demux.read.generated_queue_behavior_boundary:
    generated_read_burst_last_queue_head_demux
  response_demux.read.transaction_completion_source:
    generated_queue_head_demux
  read_data.read.capture_scope: last_beat
  read_data.read.completion_validity:
    generated_queue_head_response_demux_last_beat_completion_pulse
  read_data.read.burst_length_validation: runtime_assertion
  read_data.read.beat_count_validation_generated_behavior: true
  read_data.read.beat_count_match_source:
    response_demux_matched_read_beat
  read_data.residue:
    multi_beat_read_data_reassembly
    per_beat_outputs
    rresp_aggregation

read_last_beat_same_id_queue_head_burst_length:
  read_data.read.burst_length_validation: report_only
  read_data.residue:
    generated_beat_count_validation
    multi_beat_read_data_reassembly
    per_beat_outputs
    rresp_aggregation

read_data_multi_beat:
  read_data.read.capture_scope: multi_beat
  read_data.read.burst_length_validation: runtime_assertion
  read_data.read.beat_count_validation_generated_behavior: true
  read_data.read.beat_match_source: response_demux_matched_read_beat
  read_data.read.output_shape: per_beat_output_bank
  read_data.read.valid_output: per_transaction_valid_mask
  read_data.read.length_output: per_transaction_beat_count
  read_data.read.status_aggregation_generated_behavior: true
  read_data.read.multi_beat_reassembly_generated_behavior: true
  read_data.residue: []
```

The current normalizer is intentionally narrow. It allows concrete same-ID
queue-head `read-data` coverage only for:

- generated read single-beat queue-head demux with `capture-scope single-beat`;
- generated read burst-last queue-head demux with `capture-scope last-beat`.

That coverage function is now the primary blocker for queue-head
`capture-scope multi-beat`. The downstream generated behavior already has the
needed primitives:

- queue-head runtime validation now provides expected-count storage and
  matched-read-beat counters for the same bounded read burst-last queue-head
  shape;
- `_read_data_matched_read_beat_expr` can count raw accepted read beats using
  response event plus concrete `RID` plus active queue-head transaction
  identity;
- the auto-ID multi-beat output-bank path already emits payload/status lanes,
  valid masks, length outputs, request-time output clearing, per-lane capture
  rules, and optional scalar `RRESP` aggregation;
- the IAL1, IAL0, and SystemVerilog lowerers already carry those generated
  scalar outputs and rules.

No new lower IAL1, IAL0, or SystemVerilog substrate prerequisite is evident
for the first bounded queue-head multi-beat output-bank slice.

## Selection

Select `.121`, generated multi-beat read-data output-bank behavior for the
bounded read burst-last concrete same-ID queue-head demux shape.

The `.121` implementation boundary should be:

- read family only;
- `response-demux.read.response_scope` is `burst-last`;
- the generated queue-head boundary is
  `generated_read_burst_last_queue_head_demux`;
- exactly one duplicate concrete read-ID group;
- exactly two read transactions in that group;
- computed queue depth is `2`;
- `read-data.read.capture_scope` is `multi-beat`;
- `read-data.read.completion_source` is `response-demux`;
- `read-data.read.status_policy` is `per-beat`;
- `read-data.read.interleaving` is `multi-beat-by-rid`;
- `read-data.read.burst-length` uses `source arlen`, signal width `8`,
  `encoding axlen-plus-one`, `capture request`, and
  `validation runtime-assertion`;
- transaction bindings use `data-output-prefix`, `status-output-prefix`,
  `valid-mask-output`, and `length-output`;
- if selected in the public sample, `status-aggregation worst-observed` uses
  per-transaction scalar `status-aggregate-output` bindings and reuses the
  existing generated scalar aggregation path;
- lane capture rules use raw matched queue-head read beats:
  read response event plus concrete `RID` plus active queue-head transaction
  identity plus beat-count lane index;
- queue dequeue and transaction completion remain owned by the generated
  queue-head demux last-beat completion pulse;
- report JSON preserves
  `completion_validity: generated_queue_head_response_demux_last_beat_completion_pulse`
  while reporting `capture_scope: multi_beat`, `output_shape:
  per_beat_output_bank`, `valid_output: per_transaction_valid_mask`,
  `length_output: per_transaction_beat_count`, generated lane outputs/rules,
  and generated beat-count validation artifacts.

The first public sample should be support-accounted and runnable through
schedule JSON, strict check JSON, normalized semantic JSON, and HDL
verification. Existing queue-head single-beat, queue-head last-beat,
queue-head report-only burst-length, queue-head runtime-validation,
auto-ID runtime-validation, and auto-ID multi-beat samples must remain
behavior compatible.

## Why This Slice

This is the smallest behavior-bearing expansion after `.119`:

- queue-head last-beat capture is already generated;
- queue-head raw-`ARLEN` capture is already generated;
- queue-head beat-count/`RLAST` runtime validation is already generated;
- auto-ID multi-beat output-bank behavior already proves the payload and
  scalar-output lowerers;
- the remaining queue-head read-data residue on the `.119` runtime sample is
  exactly `multi_beat_read_data_reassembly`, `per_beat_outputs`, and
  `rresp_aggregation`.

Deeper or multiple queue groups and mixed same-family auto-ID plus concrete
queue-head demux would expand queue topology and arbitration semantics before
the existing depth-2 read-data path is complete. Direct backend and VHDL work
remain behind the SV-backed IAL feature-completeness path.

## Deferred Work

The following remain outside `.121`:

- queue groups deeper than two slots;
- more than one duplicate concrete-ID group;
- same-family mixed auto-ID plus concrete queue-head response demux;
- generalized per-ID issue-order queues;
- packed burst-vector outputs and alternate payload assembly;
- aggregate-only status output shapes beyond the selected scalar
  per-transaction aggregation path;
- direct backend lowering;
- VHDL.

## Validation Gates

The `.121` implementation should run focused syntax checks, generator and
PPIF/CLI tests, direct schedule/check/semantic/HDL probes for the new public
queue-head multi-beat sample, regression probes for queue-head single-beat,
queue-head last-beat, queue-head report-only burst-length, queue-head
runtime-validation, auto-ID runtime-validation, auto-ID multi-beat, and read
burst-last queue-head samples, support-accounting corpus gates, Knowledge Map
generation/check, mdBook build, docs path audit, memory architecture check,
diff hygiene, README numbering, stale frontier scans, and temporary artifact
cleanup.
