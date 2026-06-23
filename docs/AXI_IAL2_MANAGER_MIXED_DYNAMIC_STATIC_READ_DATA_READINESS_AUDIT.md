# AXI IAL2 Manager Mixed Dynamic/Static Read-Data Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.282`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.283`, public contract selection for
bounded scalar read-data over generated mixed dynamic/static read
response-demux.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or used:

- `.281` post mixed dynamic/static read burst-last selector.
- `.280` mixed dynamic/static read burst-last `RID && RLAST` response-demux
  behavior.
- `.279` mixed dynamic/static read burst-last contract selection.
- `.278` mixed dynamic/static read burst-last readiness audit.
- `.276` mixed dynamic/static read single-beat `RID` response-demux behavior.
- `.272` mixed dynamic/static write `BID` response-demux behavior.
- `.259` multiple dynamic scalar read-data behavior and `.257` readiness audit.
- `.234` single-active dynamic scalar read-data behavior and `.233` readiness
  audit.
- `.197` mixed auto-ID plus concrete queue-head scalar read-data behavior and
  `.196` readiness audit.
- `_read_data_response_demux_transaction_coverage`,
  `_normalize_read_data_read`, `_read_data_capture_rule_lines`,
  `_read_data_matched_read_beat_expr`, read-data report helpers, response-demux
  report/residue helpers, focused tests, support-accounting catalog, README,
  ROADMAP_V2, mdBook, Memory, and Knowledge Map.

## Code Findings

The implementation substrate is close but not contract-complete:

- `_read_data_response_demux_transaction_coverage` dispatches by
  `transaction_completion_source`.
- It already accepts scalar read-data over generated auto-ID, concrete
  queue-head, mixed auto-ID plus concrete queue-head, and all-dynamic read
  response-demux families.
- It has no branch for
  `generated_mixed_dynamic_static_read_demux` or
  `generated_mixed_dynamic_static_read_demux_last_beat`.
- The current fallback consumes `auto_transactions`, so mixed dynamic/static
  read-data would fail before scalar capture can normalize the dynamic/static
  transaction bindings.
- `.276` and `.280` response-demux reports expose the needed mixed coverage:
  ordered `dynamic_transactions`, `static_transactions`,
  `mixed_transactions`, and `generated_completion_signals`.
- `_normalize_read_data_read` already normalizes an arbitrary covered
  transaction list, rejects duplicates, rejects uncovered transactions, and
  fails when a covered transaction is missing from `read-data.read`.
- Scalar capture rules already use each normalized transaction's
  `completion_signal`; they do not need to re-match raw `RID` or
  `RID && RLAST`.
- Burst-length, runtime-validation, and multi-beat helpers use separate
  matched-beat/counter/output-bank paths and should remain follow-on owners
  after scalar mixed read-data coverage is selected.

## Why Contract Selection First

The behavior itself is likely local to read-data transaction coverage and
focused report/test/sample surfaces. A contract selection still belongs before
code changes because the next implementation needs to define:

- whether the first mixed read-data widening covers both `.276` single-beat
  and `.280` burst-last demux or splits them;
- whether both the dynamic read transaction and the static read transaction
  must be bound by `read-data.read.transactions`;
- exact public PPIF sample names for scalar single-beat and scalar last-beat
  mixed dynamic/static read-data;
- completion-validity vocabulary for
  `generated_mixed_dynamic_static_read_demux` and
  `generated_mixed_dynamic_static_read_demux_last_beat`;
- whether existing scalar read-data report modes remain sufficient or need
  mixed dynamic/static-specific wording;
- report residue cleanup for `read_data_interleaving` and whether
  `bursts`/`same_id_ordering` remain under `response_demux.residue`;
- fail-closed diagnostics for missing, extra, duplicate, or partial
  transaction bindings; and
- validation gates and support-accounting expectations for the implementation.

Selecting that public contract first keeps the implementation slice from also
having to choose sample names, report vocabulary, and the boundary between
scalar read-data, burst-length/runtime validation, and multi-beat output-bank
behavior.

## Selected .283 Boundary

`.283` should select the exact public contract for bounded scalar read-data
over generated mixed dynamic/static read response-demux. It should define:

- public source shape for the `.276` single-beat mixed dynamic/static read
  response-demux plus scalar `capture-scope single-beat` read-data;
- public source shape for the `.280` burst-last mixed dynamic/static read
  response-demux plus scalar `capture-scope last-beat` read-data;
- required one-dynamic plus one-concrete-static read-family coverage;
- transaction-to-generated-completion mapping;
- requirement that read-data transaction bindings exactly cover the selected
  mixed read demux transaction set;
- scalar data/status output binding rules and collision expectations;
- completion-validity and report vocabulary;
- diagnostics for partial coverage, extra transactions, duplicate bindings,
  generated completion count mismatches, and unsupported burst/multi-beat
  extensions;
- public PPIF sample names and support-accounting entries;
- focused parser/generator/dynamic/support-accounting validation gates;
- docs, mdBook, README, ROADMAP_V2, Memory, and Knowledge Map updates;
- rollback; and
- explicit residue.

## Non-Goals

This audit does not implement read-data over mixed dynamic/static read demux.
It does not change parser, generator, PPIF samples, support-accounting catalog,
validation behavior, generated artifacts, tests, schedule/check/semantic JSON,
or HDL behavior.

These remain later exact owners unless `.283` explicitly selects otherwise:

- generated scalar read-data over mixed dynamic/static read demux;
- burst-length/runtime validation over mixed dynamic/static read demux;
- multi-beat output banks over mixed dynamic/static read demux;
- multiple mixed dynamic/static read or write transactions;
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

Rollback is the `.282` audit commit. Reverting it restores `.282` as the
active readiness-audit frontier and removes the `.283` public
contract-selection owner.
