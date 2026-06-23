# AXI IAL2 Manager Post Multiple Mixed Dynamic/Static Write Demux Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.296`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.297`, readiness audit for
multiple mixed dynamic/static read response-demux after generated bounded
multiple mixed dynamic/static write `BID` response-demux shipped.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.295` multiple mixed dynamic/static write `BID` response-demux behavior:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md`
- `.294` multiple mixed dynamic/static write contract selection.
- `.293` multiple mixed dynamic/static readiness audit.
- `.292` post mixed dynamic/static multi-beat selector.
- `.280` mixed dynamic/static read burst-last `RID && RLAST`
  response-demux behavior.
- `.276` mixed dynamic/static read single-beat `RID` response-demux behavior.
- `.284` mixed dynamic/static scalar read-data behavior and `.291` mixed
  dynamic/static multi-beat output-bank behavior.
- Multiple all-dynamic read precedents from `.251` and `.255`, and the
  multiple all-dynamic read-data/burst/runtime/multi-beat ladder.
- Current generator/report surfaces in
  `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`, especially
  `_response_demux_dynamic_read_transaction`,
  `_response_demux_mixed_dynamic_static_read_transaction`,
  `_normalize_response_demux_read`, and the mixed dynamic/static assertion
  helper.
- Focused dynamic test coverage in
  `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, support
  accounting in `FSM::Support::RegressionCorpus`, README, `ROADMAP_V2.md`,
  mdBook, task tree, Memory, and Knowledge Map state.

## Rationale

`.295` settled the first widened mixed dynamic/static ownership and report
contract on the smallest surface: write `BID` response-demux with one dynamic
write transaction and two concrete static write transactions. That work
established list-shaped `mixed_transactions` and `static_id_reservations`,
dynamic capture exclusions for all selected static concrete IDs, onehot0
request policy across more than two selected mixed transactions, and
pairwise raw-response unique-match assertions while preserving the existing
one-dynamic plus one-static report contract.

The next roadmap-aligned gap is the read side of that same widened mixed
ownership problem. The read plan builder still fails closed before
normalization for mixed dynamic/static read families wider than one dynamic
plus one concrete static transaction:

```text
AXI manager capacity/status IAL2 contract response_demux.read mixed dynamic/static ID matching supports exactly one dynamic read transaction and one concrete static read transaction in this slice
```

The assertion helper is already list-shaped, but read response-demux has two
public scopes and two completion semantics: single-beat `RID` completion and
burst-last `RID && RLAST` completion. The read side therefore deserves a
readiness audit before contract selection or implementation. The audit should
decide whether the first read-side widened owner is single-beat `RID` only,
burst-last `RID && RLAST`, a combined contract-selection slice, or a smaller
helper/report prerequisite.

Further write cardinality, such as two dynamic plus one static transaction,
should not be next. The project now has one widened write mixed contract;
read-side reuse is the higher-leverage parity step before expanding write
cardinality again. Same-cycle request widening beyond onehot0,
release-and-recapture, dynamic same-ID queues, and scoreboards remain later
owners because they require queue or scoreboard semantics that the current
mixed response-demux contracts deliberately avoid.

## Selected .297 Boundary

`.297` should audit only multiple mixed dynamic/static read response-demux
readiness. It should:

- inspect the current one-dynamic plus one-static read single-beat and
  burst-last behavior and the `.295` multi-static write implementation;
- inspect the read plan builder, read normalization, read-data coverage
  predicates, generated completion signal maps, static concrete-ID
  reservation/report surfaces, onehot0 request policy, and assertion helper;
- decide whether the next exact owner should be public contract selection for
  multiple mixed dynamic/static read single-beat `RID` response-demux,
  burst-last `RID && RLAST` response-demux, both scopes, direct
  implementation, or a narrower prerequisite;
- record candidate public sample stems, likely
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif`
  for single-beat and a burst-last sibling if selected later;
- record expected report vocabulary, including candidate modes
  `bounded_multi_mixed_dynamic_static_read_rid_demux_contract` and
  `bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
  generated completion sources
  `generated_multi_mixed_dynamic_static_read_demux` and
  `generated_multi_mixed_dynamic_static_read_demux_last_beat`, list-shaped
  mixed transaction/static-ID reservation fields, and dynamic capture
  exclusions for every selected static concrete ID;
- record expected validation gates, docs and Knowledge Map impact, rollback,
  and explicit residue; and
- change no parser, generator, PPIF sample, support-accounting catalog,
  validation behavior, generated artifact, test, schedule/check/semantic JSON,
  or HDL behavior.

## Explicit Residue

These remain future exact owners unless `.297` deliberately selects one of
them as the next boundary:

- implementation of multiple mixed dynamic/static read response-demux;
- scalar read-data, burst-length/runtime validation, and multi-beat output
  banks over multiple mixed read demux;
- two-dynamic plus one-static mixed dynamic/static write cardinality;
- broader mixed write and read cardinalities;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation

Selector validation is documentation and continuity only:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No focused generator, parser, support-accounting, schedule/check/semantic, or
HDL probes are required because `.296` changes no behavior.

## Rollback

Rollback is the `.296` selector commit. Reverting it restores `.296` as the
active selector after `.295` and removes the `.297` readiness-audit owner.
