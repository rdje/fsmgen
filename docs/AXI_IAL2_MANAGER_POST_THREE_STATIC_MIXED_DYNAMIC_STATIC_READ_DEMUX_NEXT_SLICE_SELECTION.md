# AXI IAL2 Manager Post Three-Static Mixed Dynamic/Static Read Demux Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.323`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.324`, readiness audit for bounded
one-dynamic plus three-concrete-static mixed dynamic/static read burst-last
`RID && RLAST` response-demux after generated bounded one-dynamic plus
three-concrete-static mixed dynamic/static read single-beat `RID`
response-demux shipped.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.322` one-dynamic plus three-concrete-static mixed dynamic/static read
  single-beat `RID` response-demux behavior:
  `docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md`
- `.321` three-static mixed dynamic/static read single-beat public contract
  selection.
- `.320` three-static mixed dynamic/static read response-demux readiness
  audit.
- `.318` one-dynamic plus three-concrete-static mixed dynamic/static write
  `BID` response-demux behavior.
- `.303` one-dynamic plus two-concrete-static mixed dynamic/static read
  burst-last `RID && RLAST` response-demux behavior.
- `.299` one-dynamic plus two-concrete-static mixed dynamic/static read
  single-beat `RID` response-demux behavior.
- `.307`, `.310`, `.312`, and `.314` two-static mixed dynamic/static
  read-data, burst-length, runtime-validation, and multi-beat output-bank
  behavior over the multiple mixed boundary.
- Current generator/report surfaces in
  `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`, especially
  `_response_demux_dynamic_read_transaction`,
  `_response_demux_mixed_dynamic_static_read_transaction`,
  `_normalize_response_demux_read`,
  `_read_data_response_demux_transaction_coverage`, and the mixed
  dynamic/static assertion helper.
- Focused dynamic test coverage in
  `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, support
  accounting in `FSM::Support::RegressionCorpus`, README, `ROADMAP_V2.md`,
  mdBook, task tree, Memory, and Knowledge Map state.

## Rationale

`.322` settled the next broader read-side cardinality for the smallest
read-side behavior: single-beat `RID` response-demux with one dynamic read
transaction and three concrete static read transactions. It reused the
existing list-shaped multi-mixed read report mode and proved that the static
reservation/exclusion, generated completion, and pairwise unique-match
surfaces scale to four covered read transactions.

The next roadmap-aligned gap is final-beat lifetime matching for that same
three-static ownership shape. The earlier one-static path shipped single-beat
`RID` first, then selected and shipped burst-last `RID && RLAST`, before
read-data, burst-length/runtime validation, and multi-beat output banks. The
two-static mixed path followed the same order: `.299` single-beat, `.303`
burst-last, then the read-data ladder.

Read-data over the three-static shape should not be widened before final-beat
completion semantics are audited. Current burst-last normalization still
contains an explicit one-dynamic plus one- or two-static admission guard, and
read-data coverage over multiple mixed dynamic/static read demux still
depends on the existing two-static boundary. A readiness audit is therefore
the smallest signoff-level next slice.

Two-dynamic-plus-static shapes, general capped mixed sets, same-cycle request
widening beyond `onehot0`, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain later owners because they require broader ownership or backend policy
outside this read-lifetime audit.

## Selected .324 Boundary

`.324` should audit only one-dynamic plus three-concrete-static mixed
dynamic/static read burst-last `RID && RLAST` response-demux readiness. It
should:

- inspect `.322` three-static read single-beat behavior, `.321` contract,
  `.303` two-static mixed read burst-last behavior, `.299` two-static mixed
  read single-beat behavior, and `.318` three-static write behavior;
- inspect the read plan builder, read normalization, last-signal handling,
  generated completion signal maps, static concrete-ID reservation/report
  surfaces, onehot0 request policy, and mixed assertion helper;
- decide whether the next exact owner should be public contract selection,
  direct generated behavior, helper/report cleanup, or a narrower
  prerequisite;
- record candidate public sample stem, likely
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif`
  if the audit selects behavior;
- record expected report vocabulary, including whether the existing
  `bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract` mode and
  `generated_multi_mixed_dynamic_static_read_demux_last_beat` completion
  source can cover the three-static shape through list fields;
- record expected diagnostics, validation gates, docs and Knowledge Map
  impact, rollback, and explicit residue; and
- change no parser, generator, PPIF sample, support-accounting catalog,
  validation behavior, generated artifact, test, schedule/check/semantic
  JSON, or HDL behavior.

## Explicit Residue

These remain future exact owners unless `.324` deliberately selects one of
them as the next boundary:

- implementation of one-dynamic plus three-static mixed dynamic/static read
  burst-last `RID && RLAST` response-demux;
- read-data over the three-static mixed read demux boundary;
- burst-length/runtime validation and multi-beat output banks over the
  three-static mixed read demux boundary;
- two-dynamic plus one-static mixed dynamic/static cardinality;
- general capped mixed write and read cardinalities;
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
