# AXI IAL2 Manager Multiple Mixed Dynamic/Static Read-Data Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.305`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.306`, public contract selection for
bounded scalar read-data over generated multiple mixed dynamic/static read
response-demux.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or used:

- `.304` post multiple mixed dynamic/static read RLAST selector.
- `.303` multiple mixed dynamic/static read burst-last `RID && RLAST`
  response-demux behavior.
- `.299` multiple mixed dynamic/static read single-beat `RID` response-demux
  behavior.
- `.284` mixed dynamic/static scalar read-data behavior over the one-dynamic
  plus one-static path.
- `.259` multiple dynamic scalar read-data behavior.
- `_read_data_response_demux_transaction_coverage`,
  `_normalize_read_data_read`, `_read_data_capture_rule_lines`, read-data
  report helpers, response-demux residue helpers, support-accounting catalog,
  focused dynamic tests, README, `ROADMAP_V2.md`, mdBook, Memory, and
  Knowledge Map.

## Code Findings

The scalar read-data substrate is close but not contract-complete for the new
multi-static mixed read shape:

- `_read_data_response_demux_transaction_coverage` has a mixed
  dynamic/static branch for
  `generated_mixed_dynamic_static_read_demux` and
  `generated_mixed_dynamic_static_read_demux_last_beat`.
- That branch is the one-dynamic plus one-static owner shipped by `.284`; it
  requires exactly one dynamic read transaction and exactly one concrete
  static read transaction.
- The branch does not match
  `generated_multi_mixed_dynamic_static_read_demux` or
  `generated_multi_mixed_dynamic_static_read_demux_last_beat`, the completion
  sources shipped by `.299` and `.303`.
- Once a coverage branch returns an ordered transaction set and
  transaction-to-completion map, `_normalize_read_data_read` already rejects
  missing, duplicate, and uncovered transaction bindings and accepts arbitrary
  scalar transaction counts.
- `_read_data_capture_rule_lines` already emits one scalar capture rule per
  normalized transaction, guarded by that transaction's generated completion
  signal. It does not re-match raw `RID` or `RID && RLAST`.
- `.299` and `.303` reports already expose the ordered data a widened scalar
  read-data branch would need: `dynamic_transactions: [r0]`,
  `static_transactions: [r1, r2]`, list-shaped `mixed_transactions`,
  list-shaped `static_id_reservations`, and generated completion signals for
  `r0`, `r1`, and `r2`.

## Why Contract Selection First

The likely implementation is local to the read-data coverage selector plus
sample/test/report surfaces, but the public contract still needs to be fixed
before code changes. The next slice must decide:

- whether the first scalar read-data widening covers both `.299` single-beat
  and `.303` burst-last demux or splits them;
- exact public PPIF sample names;
- whether completion-validity vocabulary should use a new multiple mixed
  prefix or reuse the one-static mixed vocabulary;
- whether covered transaction order is always dynamic transactions followed
  by static transactions;
- fail-closed diagnostics for unsupported completion sources, partial
  bindings, extra bindings, duplicate bindings, completion-count mismatches,
  and unsupported burst/multi-beat extensions;
- whether response-demux/read-data residue changes on scalar coverage;
- focused validation strategy under the `.303` host-memory caveat; and
- docs, mdBook, README, `ROADMAP_V2.md`, Memory, Knowledge Map, and rollback
  requirements.

Selecting the public contract first keeps the later behavior slice narrow and
prevents implementation from also choosing naming, report vocabulary,
diagnostics, and residue movement.

## Selected .306 Boundary

`.306` should select the exact public contract for bounded scalar read-data
over generated multiple mixed dynamic/static read response-demux. It should
define:

- public source shape for `.299` multiple mixed single-beat `RID`
  response-demux plus scalar `capture-scope single-beat` read-data;
- public source shape for `.303` multiple mixed burst-last `RID && RLAST`
  response-demux plus scalar `capture-scope last-beat` read-data;
- required one-dynamic plus two-concrete-static read transaction coverage;
- transaction-to-generated-completion mapping and ordered coverage;
- scalar data/status output binding rules and collision expectations;
- completion-validity and report vocabulary;
- diagnostics for partial coverage, extra transactions, duplicate bindings,
  generated completion count mismatches, unsupported burst-length/runtime or
  multi-beat extensions, and unsupported cardinalities;
- public PPIF sample names and support-accounting entries;
- focused parser/generator/dynamic/support-accounting validation gates,
  including RAM-guarded direct probes and lightweight report/adapter fallback
  probes if direct probes trip host-memory guards;
- docs, mdBook, README, `ROADMAP_V2.md`, Memory, and Knowledge Map updates;
- rollback; and
- explicit residue.

## Non-Goals

This audit does not implement read-data over multiple mixed dynamic/static
read demux. It does not change parser, generator, PPIF samples,
support-accounting catalog, validation behavior, generated artifacts, tests,
schedule/check or semantic JSON, or HDL behavior.

These remain later exact owners unless `.306` explicitly selects otherwise:

- generated scalar read-data over multiple mixed read demux;
- raw `ARLEN` burst-length capture over multiple mixed read burst-last demux;
- runtime beat-count/`RLAST` validation over multiple mixed read burst-last
  demux;
- multi-beat output banks over multiple mixed read demux;
- two-dynamic plus one-static mixed dynamic/static cardinality;
- broader mixed write and read cardinalities;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
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

Rollback is the `.305` audit commit. Reverting it restores `.305` as the
active readiness-audit frontier and removes the `.306` public
contract-selection owner.
