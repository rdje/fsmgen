# AXI IAL2 Manager Post Multiple Mixed Dynamic/Static Read Demux Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.300`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.301`, readiness audit for
multiple mixed dynamic/static read burst-last `RID && RLAST` response-demux
after generated bounded multiple mixed dynamic/static read single-beat `RID`
response-demux shipped.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.299` multiple mixed dynamic/static read single-beat `RID`
  response-demux behavior:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md`
- `.298` multiple mixed dynamic/static read single-beat contract selection.
- `.297` multiple mixed dynamic/static read readiness audit.
- `.295` multiple mixed dynamic/static write `BID` response-demux behavior.
- `.291` mixed dynamic/static multi-beat output-bank behavior over the
  one-dynamic plus one-static path.
- `.280` one-dynamic plus one-static mixed read burst-last `RID && RLAST`
  response-demux behavior.
- `.276` one-dynamic plus one-static mixed read single-beat `RID`
  response-demux behavior.
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

`.299` settled the widened mixed dynamic/static read ownership contract for
the smallest read-side behavior: single-beat `RID` response-demux with one
dynamic read transaction and two concrete static read transactions. It also
proved the list-shaped mixed transaction and static-ID reservation report
surface, pairwise raw-response unique-match assertions, and preserved `.276`
one-dynamic plus one-static report compatibility.

The next roadmap-aligned gap is the burst-last lifetime for that same widened
read ownership shape. The one-dynamic plus one-static path deliberately
shipped single-beat `RID` first in `.276`, then selected and shipped
burst-last `RID && RLAST` before scalar read-data, burst-length/runtime
validation, and multi-beat output banks. The all-dynamic multiple read path
used the same order: single-beat first, then burst-last, then read-data and
runtime/multi-beat expansions.

Read-data and burst-length behavior should not be widened over the multi-static
mixed read shape until the final-beat completion semantics are audited. The
audit should confirm whether the current `.299` multi-static read plan can
reuse the `.280` burst-last final-completion path without changing the
one-static report contract, whether a public contract selector is needed
before implementation, and whether any report/static helper cleanup is safer
first.

Broader mixed cardinalities such as two dynamic plus one static, same-cycle
request widening beyond onehot0, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL all
remain later owners because they require either broader ownership policy or
backend contracts outside this read lifetime audit.

## Selected .301 Boundary

`.301` should audit only multiple mixed dynamic/static read burst-last
`RID && RLAST` response-demux readiness. It should:

- inspect `.299` multiple mixed read single-beat behavior, `.298` contract,
  `.280` one-static mixed read burst-last behavior, `.276` one-static mixed
  read single-beat behavior, and `.295` multi-static mixed write behavior;
- inspect the read plan builder, read normalization, last-signal handling,
  generated completion signal maps, static concrete-ID reservation/report
  surfaces, onehot0 request policy, and mixed assertion helper;
- decide whether the next exact owner should be public contract selection,
  direct generated behavior, helper/report cleanup, or a narrower prerequisite;
- record candidate public sample stem, likely
  `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif`
  if the audit selects behavior;
- record expected report vocabulary, including candidate mode
  `bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
  generated completion source
  `generated_multi_mixed_dynamic_static_read_demux_last_beat`, list-shaped
  mixed transaction/static-ID reservation fields, and final-beat completion
  semantics;
- record expected validation gates, docs and Knowledge Map impact, rollback,
  and explicit residue; and
- change no parser, generator, PPIF sample, support-accounting catalog,
  validation behavior, generated artifact, test, schedule/check/semantic JSON,
  or HDL behavior.

## Explicit Residue

These remain future exact owners unless `.301` deliberately selects one of
them as the next boundary:

- implementation of multiple mixed dynamic/static read burst-last
  `RID && RLAST` response-demux;
- scalar read-data over multiple mixed read demux;
- burst-length/runtime validation and multi-beat output banks over multiple
  mixed read demux;
- two-dynamic plus one-static mixed dynamic/static cardinality;
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
HDL probes are required because `.300` changes no behavior.

## Rollback

Rollback is the `.300` selector commit. Reverting it restores `.300` as the
active selector after `.299` and removes the `.301` readiness-audit owner.
