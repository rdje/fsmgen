# AXI IAL2 Manager Mixed Dynamic/Static Issue-Order Queue Read-Data Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.513`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.513` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.514`, direct bounded implementation of
paired scalar read-data routing over generated mixed dynamic/static read
same-ID `issue-order-queue` completions.

No separate public contract-selection leaf is required. Existing
`read-data.read` syntax already describes scalar single-beat and scalar
last-beat `RDATA`/`RRESP` capture from generated response-demux completions,
and prior generated dynamic queue and mixed response-demux read-data slices
already prove the two halves of the contract. The remaining blocker is local
to read-data transaction coverage for the generated mixed queue completion
sources.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, schedule/check/semantic
JSON, test, HDL/runtime behavior, backend behavior, external converter
dependency, verification-output, or VHDL behavior.

## Evidence Read

The audit read:

- `.512` selector.
- `.511` public `.ppif` surface synchronization.
- `.510` public surface selector.
- `.509` generated mixed dynamic/static read burst-last `RID && RLAST`
  same-ID `issue-order-queue` behavior.
- `.506` generated mixed dynamic/static read single-beat `RID` same-ID
  `issue-order-queue` behavior.
- `.503` generated mixed dynamic/static write `BID` same-ID
  `issue-order-queue` behavior.
- `.465`, `.466`, and `.467` generated dynamic read queue read-data audit,
  contract, and behavior records.
- `.282`, `.283`, and `.284` generated mixed dynamic/static response-demux
  read-data audit, contract, and behavior records.
- `.469`, `.471`, `.473`, `.494`, `.497`, `.500`, `.287`, `.289`, and `.291`
  raw-`ARLEN`, runtime-validation, and multi-beat records for dynamic queues
  and mixed response-demux.
- Current read-data coverage, normalization, report, residue, parser/CLI,
  generator-test, support-accounting, README, ROADMAP_V2, mdBook, Memory,
  task tree, and Knowledge Map surfaces.

## Current Boundary

Generated mixed dynamic/static read queue reports expose queue-owned
completion sources:

```text
generated_mixed_dynamic_static_issue_order_queue_demux
generated_mixed_dynamic_static_issue_order_queue_demux_last_beat
```

`_response_demux_transaction_completion_source_is_dynamic_issue_order_queue`
already recognizes those sources as generated same-ID issue-order queue
completion sources for queue generation and reporting. However,
`_read_data_response_demux_transaction_coverage` currently has separate
branches for:

- ordinary mixed dynamic/static read response-demux completions:
  `generated_mixed_dynamic_static_read_demux` and
  `generated_mixed_dynamic_static_read_demux_last_beat`; and
- generated all-dynamic issue-order queue completions:
  `generated_dynamic_issue_order_queue_demux` and
  `generated_dynamic_issue_order_queue_demux_last_beat`.

It has no branch for the generated mixed dynamic/static issue-order queue
sources.

## Temporary Candidate Probe

Two temporary PPIF candidates under `/tmp` added existing scalar `read-data`
clauses to the shipped mixed queue samples:

```text
/tmp/ial2-mixed-queue-read-data-single.ppif
/tmp/ial2-mixed-queue-read-data-burst-last.ppif
```

The initial RAM-guarded probe failed closed because process-tree inspection is
unavailable inside the sandbox. The approved guarded rerun stayed below the
88% host-memory cutoff and failed both candidates at the same current local
coverage fallback:

```text
AXI manager capacity/status IAL2 contract read_data.read requires read response_demux auto transaction coverage metadata
```

The candidates parsed far enough to reach read-data coverage. No parser
syntax, public source-shape, PPIF adapter, IAL1, IAL0, SystemVerilog, backend,
external converter, or VHDL prerequisite was exposed.

## Selected `.514` Implementation Boundary

`.514` should implement only paired scalar read-data over generated mixed
dynamic/static read same-ID issue-order queue completions:

- exactly one dynamic read transaction and one concrete static read
  transaction;
- `same-id-ordering.read (dynamic-id-reuse issue-order-queue)`;
- generated `response-demux.read`;
- one depth-2 generated mixed dynamic/static read issue-order queue;
- `read-max-pending` at least `2`;
- complete `read-data.read` transaction bindings for the generated mixed
  queue transactions;
- scalar single-beat read-data over
  `generated_mixed_dynamic_static_issue_order_queue_demux`; and
- scalar last-beat read-data over
  `generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`.

The selected public samples are:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_same_id_issue_order_queue_read_data.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data.ppif
```

The selected support-accounting identities and coverage buckets are:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_same_id_issue_order_queue_read_data
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_same_id_issue_order_queue_read_data_pipeline_cli
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_pipeline_cli
```

## Expected Report Contract

The response-demux report should remain queue-owned:

```text
bounded_mixed_dynamic_static_read_rid_issue_order_queue_demux_contract
bounded_mixed_dynamic_static_read_rid_rlast_issue_order_queue_demux_contract
generated_mixed_dynamic_static_issue_order_queue_demux
generated_mixed_dynamic_static_issue_order_queue_demux_last_beat
```

The read-data report should keep the existing scalar report modes:

```text
bounded_single_beat_read_data_contract
bounded_last_beat_read_data_contract
```

The new queue-specific completion-validity vocabulary should be:

```text
generated_mixed_dynamic_static_read_issue_order_queue_response_demux_completion_pulse
generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse
```

The covered transaction set is `r0, r1` in generated mixed queue order. The
dynamic transaction `r0` uses the captured runtime `ARID`; the static
transaction `r1` uses the concrete static `RID` literal already stored in the
queue. Read-data capture must consume the generated completion pulses and must
not re-match raw `RID` or `RID && RLAST`.

## Diagnostics

`.514` must fail closed when:

- the response-demux source is not one of the two generated mixed
  dynamic/static issue-order queue completion sources;
- single-beat read-data is paired with burst-last response scope;
- last-beat read-data is paired with single-beat response scope;
- the generated mixed queue does not contain exactly one dynamic read
  transaction and one concrete static read transaction;
- the queue depth is not exactly `2`;
- the generated completion-signal count does not match the covered queue
  transaction count;
- `read-data.read` omits, duplicates, or names a transaction outside the
  generated mixed queue transaction set; or
- the source attempts raw `ARLEN`, runtime beat-count/`RLAST` validation,
  multi-beat output banks, multi-static/two-dynamic mixed queues, scoreboards,
  arbitrary cardinality, direct backend behavior, backend-language variants,
  external converter dependency selection, verification-output generation, or
  VHDL.

## Non-Goals

`.513` changes no behavior. `.514` should also leave these future exact
owners out of scope:

- raw `ARLEN` capture over generated mixed dynamic/static issue-order queues;
- runtime beat-count/`RLAST` validation over generated mixed dynamic/static
  issue-order queues;
- multi-beat output banks over generated mixed dynamic/static issue-order
  queues;
- broader mixed queue cardinality;
- same-cycle widening beyond shipped onehot0/queue boundaries;
- scoreboards;
- direct backend behavior;
- backend-language variants;
- verification-code generation;
- external converter dependency selection such as `sv2v`; and
- VHDL.

## Validation

This readiness audit ran the guarded temporary candidate probes above and
closed with documentation and continuity gates:

```bash
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No parser, generator, PPIF sample, support-accounting, generated-artifact,
schedule/check/semantic JSON, test, HDL/runtime, backend, external-converter,
verification-output, or VHDL behavior validation is claimed for `.513`
because it changes no behavior.

## Rollback

Rollback removes this audit document and its Knowledge Map fact card, reverts
the `.513` task tree, README, ROADMAP_V2, mdBook, and Memory updates, and
returns the active frontier to `.513`. No code or runtime behavior rollback
is needed.
