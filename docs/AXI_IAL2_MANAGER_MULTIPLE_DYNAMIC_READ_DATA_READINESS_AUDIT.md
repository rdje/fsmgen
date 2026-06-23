# AXI IAL2 Manager Multiple Dynamic Read-Data Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.257`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.258`, public contract selection for
bounded scalar read-data over generated multiple dynamic read response-demux.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or used:

- `.256` post multiple dynamic read `RLAST` selector.
- `.255` multiple dynamic read burst-last/`RLAST` response-demux behavior.
- `.254` multiple dynamic read burst-last/`RLAST` contract selection.
- `.253` multiple dynamic read burst-last/`RLAST` readiness audit.
- `.251` multiple dynamic read single-beat response-demux behavior.
- `.250` multiple dynamic read response-demux contract selection.
- `.247` multiple dynamic write response-demux behavior.
- `.243` dynamic multi-beat output-bank behavior.
- `.240` dynamic runtime beat-count/`RLAST` validation behavior.
- `.238` dynamic report-only raw-`ARLEN` burst-length behavior.
- `.234` scalar dynamic read-data behavior.
- `.231` single-active dynamic read burst-last/`RLAST` behavior.
- `.227` single-active dynamic read single-beat behavior.
- `_read_data_response_demux_transaction_coverage`,
  `_normalize_read_data_read`, `_read_data_matched_read_beat_expr`,
  `_read_data_beat_count_assertion_specs`, dynamic response-demux report and
  residue helpers, README, ROADMAP_V2, mdBook, Memory, and Knowledge Map.

## Code Findings

The implementation substrate is close but not contract-complete:

- `_read_data_response_demux_transaction_coverage` already dispatches dynamic
  read-data coverage by `transaction_completion_source`:
  `generated_dynamic_demux` for single-beat and
  `generated_dynamic_demux_last_beat` for burst-last.
- The dynamic branch accepts scalar single-beat and scalar last-beat shapes
  without `burst_length` metadata, and also accepts the previously shipped
  report-only/runtime/multi-beat single-active dynamic shapes.
- The dynamic branch hard-fails unless there is exactly one dynamic read
  transaction and exactly one generated dynamic completion signal.
- `_normalize_read_data_read` already normalizes an arbitrary list of
  transaction bindings, detects duplicate bindings, rejects uncovered
  transactions, and fails when a covered transaction is missing from the
  `read-data.read` transaction list.
- The response-demux reports now expose ordered multiple-dynamic
  `dynamic_transactions` and `generated_completion_signals` for both the
  `.251` single-beat and `.255` burst-last shapes.
- Scalar read-data capture rules are already guarded by each transaction's
  generated completion pulse. They do not create a second raw `RID`/`RLAST`
  match path.
- Multi-beat, burst-length, and runtime-validation helpers use raw matched
  read beats and per-transaction request/counter state. Those should remain
  separate follow-on owners after scalar read-data coverage is selected.

## Why Contract Selection First

The next behavior is small enough to be local, but it still needs an explicit
public contract before code changes. The contract must decide:

- whether the first read-data widening covers both `.251` single-beat and
  `.255` burst-last multiple dynamic read demux or splits them;
- whether all dynamic read transactions in the response-demux report must be
  bound by `read-data.read.transactions`;
- exact public PPIF sample names for scalar single-beat and scalar last-beat
  multiple dynamic read-data;
- whether completion-validity vocabulary can reuse
  `generated_dynamic_read_response_demux_completion_pulse` and
  `generated_dynamic_read_response_demux_last_beat_completion_pulse`, or
  needs multiple-dynamic-specific wording;
- report residue cleanup for `read_data_interleaving` and whether
  `bursts`/`same_id_ordering` remain under `response_demux.residue`;
- fail-closed diagnostics for missing, extra, or partial transaction
  bindings; and
- validation gates and support-accounting expectations for the later
  implementation.

Selecting the contract first prevents the implementation slice from also
having to define public sample names, report vocabulary, and the exact boundary
between scalar read-data, burst-length/runtime validation, and multi-beat
output-bank behavior.

## Selected .258 Boundary

`.258` should select the exact public contract for bounded scalar read-data
over generated multiple dynamic read response-demux. It should define:

- public source shapes for the `.251` single-beat multiple dynamic read
  response-demux plus scalar `capture-scope single-beat` read-data;
- public source shapes for the `.255` burst-last multiple dynamic read
  response-demux plus scalar `capture-scope last-beat` read-data;
- required all-dynamic read-family coverage;
- transaction-to-generated-completion mapping;
- requirement that read-data transaction bindings exactly cover all generated
  dynamic read demux transactions in the selected read family;
- scalar data/status output binding rules and collision expectations;
- completion-validity and report vocabulary;
- diagnostics for partial coverage, extra transactions, duplicate bindings,
  and generated completion count mismatches;
- public PPIF sample names and support-accounting entries;
- focused parser/generator/dynamic/support-accounting validation gates;
- docs, mdBook, README, ROADMAP_V2, Memory, and Knowledge Map updates;
- rollback; and
- explicit residue.

## Non-Goals

This audit does not implement read-data over multiple dynamic read demux. It
does not change parser, generator, PPIF samples, support-accounting catalog,
validation behavior, generated artifacts, tests, schedule/check/semantic JSON,
or HDL behavior.

These remain later exact owners unless `.258` explicitly selects otherwise:

- generated scalar read-data over multiple dynamic read demux;
- burst-length/runtime validation over multiple dynamic read demux;
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

Audit validation is documentation and continuity only:

```bash
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

Rollback is the `.257` audit commit. Reverting it restores `.257` as the
active readiness-audit frontier and removes the `.258` public
contract-selection owner.
