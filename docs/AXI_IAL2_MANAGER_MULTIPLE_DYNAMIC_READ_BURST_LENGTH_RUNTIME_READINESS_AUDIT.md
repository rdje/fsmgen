# AXI IAL2 Manager Multiple Dynamic Read Burst-Length/Runtime Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.261`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.262`, public contract selection for
bounded burst-length and runtime beat-count/`RLAST` validation over generated
multiple dynamic read response-demux.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or used:

- `.260` post multiple dynamic read-data selector.
- `.259` multiple dynamic read-data behavior.
- `.258` multiple dynamic read-data contract selection.
- `.257` multiple dynamic read-data readiness audit.
- `.255` multiple dynamic read burst-last/`RLAST` response-demux behavior.
- `.251` multiple dynamic read single-beat response-demux behavior.
- `.243` single-active dynamic multi-beat output-bank behavior.
- `.240` single-active dynamic runtime beat-count/`RLAST` validation
  behavior.
- `.238` single-active dynamic report-only raw-`ARLEN` burst-length behavior.
- Current `_read_data_response_demux_transaction_coverage`,
  `_normalize_read_data_read`, `_normalize_read_data_burst_length`,
  `_read_data_burst_length_capture_rule_lines`,
  `_read_data_beat_count_rule_lines`,
  `_read_data_matched_read_beat_expr`,
  `_read_data_beat_count_assertion_specs`,
  `_report_read_data`, `_read_data_generated_artifacts`, and
  response-demux residue helpers.
- README, ROADMAP_V2, mdBook, Memory, and Knowledge Map.

## Code Findings

The implementation substrate is close, but public contract ownership is still
needed before behavior changes:

- The dynamic read-data coverage branch now accepts scalar single-beat and
  scalar last-beat read-data over one or more generated all-dynamic read
  response-demux transactions when no `burst_length` metadata is present.
- The same branch still limits dynamic `burst_length` and dynamic multi-beat
  coverage to exactly one generated dynamic read transaction. A temporary
  mutation of
  `ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif`
  that added runtime `burst-length` metadata failed closed at the expected
  dynamic burst-length diagnostic.
- `_normalize_read_data_burst_length` already validates the public raw-`ARLEN`
  metadata: `source arlen`, width-8 signal, `axlen-plus-one`, request capture,
  `max-beats` in `1..256`, and `validation report-only` or
  `runtime-assertion`.
- After coverage is admitted, `_normalize_read_data_read` already iterates the
  normalized transaction list and assigns per-transaction raw-`ARLEN` storage
  plus burst-length capture rule names. For runtime validation it also assigns
  per-transaction expected-beat storage, read-beat counter storage, beat-count
  init/increment rule names, and four assertion names.
- The IAL1 emission helpers are transaction-list shaped:
  `_read_data_burst_length_storage_lines`,
  `_read_data_burst_length_capture_rule_lines`,
  `_read_data_beat_count_storage_lines`,
  `_read_data_beat_count_rule_lines`, and
  `_read_data_beat_count_assertion_specs` all iterate
  `read_data.read.transactions`.
- Runtime beat counting uses `_read_data_matched_read_beat_expr`, which
  composes the raw read response event with the response-demux transaction
  state's active `RID == selected_id` match. That is the same raw beat boundary
  `.255` already guards with active-match and unique-match assertions for
  multiple dynamic read burst-last demux.
- `_report_read_data` and `_read_data_generated_artifacts` already aggregate
  generated burst-length inputs/storage/rules, expected-beat storage,
  beat-count storage/rules, and beat-count assertions across the normalized
  transaction list.
- The remaining direct implementation appears local to admitting the multiple
  dynamic burst-length/runtime coverage, then updating report/residue wording,
  diagnostics, samples, support accounting, and focused expectations.

## Why Contract Selection First

The next behavior is adjacent to existing helpers, but it has enough public
surface area to require a contract selector before implementation. The
contract must decide:

- whether report-only raw-`ARLEN` capture and runtime beat-count/`RLAST`
  validation ship together or in separate implementation leaves;
- public PPIF sample names and whether both samples should be support-accounted
  immediately;
- whether the public source shape requires every generated dynamic read demux
  transaction to bind a read-data transaction before burst-length metadata is
  admitted;
- the ARLEN ownership rule for multiple active dynamic reads: one family-level
  `ARLEN` input captured per transaction at that transaction's admitted
  request event;
- per-transaction expected-beat and read-beat counter state naming/reporting;
- whether runtime validation is allowed only for scalar last-beat read-data
  over multiple dynamic `RID && RLAST` demux, or whether any adjacent shape
  should remain explicitly excluded;
- exact diagnostics for missing, partial, extra, duplicate, or mismatched
  burst-length/runtime coverage;
- report vocabulary for generated burst-length and beat-count artifacts across
  multiple dynamic transactions;
- response-demux and read-data residue cleanup after report-only and runtime
  samples; and
- validation gates and rollback for the later implementation.

Selecting the public contract first keeps the implementation slice local and
prevents sample naming, report vocabulary, diagnostic shape, and residue
policy from being decided while code is changing.

## Selected .262 Boundary

`.262` should select the public contract for bounded burst-length and runtime
beat-count/`RLAST` validation over generated multiple dynamic read
response-demux. It should define:

- source shapes based on `.259` scalar last-beat multiple dynamic read-data;
- whether report-only and runtime validation ship in one implementation or
  split into separate leaves;
- exact transaction coverage rules;
- per-transaction raw-`ARLEN` capture ownership;
- per-transaction runtime counter/assertion semantics;
- public PPIF sample names and support-accounting entries;
- schedule/check/semantic report fields;
- diagnostics for unsupported shapes and malformed transaction coverage;
- focused parser/generator/dynamic/support-accounting validation;
- docs, README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map
  updates;
- rollback; and
- explicit residue.

## Non-Goals

This audit does not implement burst-length capture or runtime validation over
multiple dynamic read demux. It does not add PPIF samples or support-accounting
entries and does not change tests, parser, generator, generated artifacts,
schedule/check/semantic JSON, HDL, or validation behavior.

These remain later exact owners unless `.262` explicitly selects otherwise:

- generated burst-length/runtime behavior over multiple dynamic read demux;
- multi-beat output banks over multiple dynamic read demux;
- mixed dynamic/static demux;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID ordering;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation

Audit validation is documentation and continuity only, plus the temporary
fail-closed probe noted above:

```bash
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-multi-dynamic-runtime-probe.ppif
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No focused generator, parser, support-accounting, schedule/check/semantic, or
HDL probes are required because this audit changes no behavior.

## Rollback

Rollback is the `.261` audit commit. Reverting it restores `.261` as the
active readiness-audit frontier and removes the `.262` public
contract-selection owner.
