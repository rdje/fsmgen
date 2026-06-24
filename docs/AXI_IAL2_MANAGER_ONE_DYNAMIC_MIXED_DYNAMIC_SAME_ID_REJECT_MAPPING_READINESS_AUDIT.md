# AXI IAL2 Manager One-Dynamic Mixed Dynamic Same-ID Reject Mapping Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.444`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.444` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.445`, public report contract selection for
one-dynamic mixed dynamic/static dynamic same-ID reject mapping.

The audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, runtime behavior, direct backend behavior, backend-language
variant, queue, scoreboard, or VHDL behavior.

## Inputs Read

The audit read:

- `.443` post single-active selector;
- `.442` single-active dynamic same-ID reject mapping behavior;
- `.438` multi-active dynamic same-ID reject enforcement mapping behavior;
- `.437` generated reject mapping readiness audit and its one-dynamic mixed
  fail-closed boundary;
- `.436` metadata-first `(dynamic-id-reuse reject)` parser/report behavior;
- `.434` public dynamic same-ID policy contract;
- one-dynamic mixed dynamic/static write `BID`, read single-beat `RID`, and
  read burst-last `RID && RLAST` response-demux behavior records;
- one-dynamic plus two-static and three-static mixed response-demux records;
- current mixed dynamic/static response-demux builders, assertion specs,
  same-ID coverage helper, residue projection, and fail-closed guard in
  `AxiManagerCapacityStatus.pm`;
- the focused generator fail-closed row for one-dynamic mixed response-demux
  plus `dynamic-id-reuse reject`;
- public support-accounted mixed dynamic/static response-demux samples;
- README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

## Current Boundary

Multi-active all-dynamic and two-dynamic-plus-one-static mixed
response-demux shapes are covered by `.438` through generated
`*_dynamic_request_no_active_same_id` and
`*_dynamic_active_id_unique` assertion evidence.

Single-active all-dynamic response-demux shapes are covered by `.442` through
generated idle-or-releasing, active-match, and completion-active assertion
evidence.

One-dynamic mixed dynamic/static response-demux shapes still fail closed. A
guarded temporary probe that added:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse reject)))
```

to `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif`
failed with:

```text
AXI manager capacity/status IAL2 contract response_demux.read dynamic-id-reuse reject generated enforcement requires generated multi-active dynamic response-demux no-active-same-ID assertions in this slice
```

That diagnostic is conservative and intentionally not final for this family:
one-dynamic mixed shapes have no sibling dynamic transaction, so they cannot
expose the `.438` no-active-same-ID plus active-ID uniqueness pair.

## Generated Evidence

Guarded schedule probes confirmed the representative one-dynamic mixed
surfaces:

| Sample | Mode | Ownership | Static IDs |
| --- | --- | --- | --- |
| `ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif` | `bounded_mixed_dynamic_static_write_bid_demux_contract` | `mixed_dynamic_static_unique_write_ids` | `4'd3` |
| `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif` | `bounded_mixed_dynamic_static_read_rid_demux_contract` | `mixed_dynamic_static_unique_read_ids` | `4'd3` |
| `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif` | `bounded_mixed_dynamic_static_read_rid_rlast_demux_contract` | `mixed_dynamic_static_unique_read_ids` | `4'd3` |
| `ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3.ppif` | `bounded_multi_mixed_dynamic_static_write_bid_demux_contract` | `multi_mixed_dynamic_static_unique_write_ids` | `4'd3`, `4'd5`, `4'd7` |
| `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif` | `bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract` | `multi_mixed_dynamic_static_unique_read_ids` | `4'd3`, `4'd5`, `4'd7` |

Those reports expose `static_id_conflict_policy:
static_concrete_ids_reserved` and generated assertion names for:

- dynamic/static request idle-or-releasing or not-busy admission;
- mixed dynamic/static request `onehot0`;
- dynamic request does not use any selected static concrete ID;
- active dynamic ID is not any selected static concrete ID;
- raw response active match;
- raw response unique match across dynamic/static matches; and
- dynamic and static completion-active release.

## Readiness Finding

The generated evidence is ready for public report-contract selection, not for
direct behavior implementation in this audit.

The evidence is strong enough to audit as generated reject enforcement because
the dynamic request cannot be admitted with a runtime ID equal to any selected
static concrete ID, an active dynamic ID is asserted not to equal selected
static concrete IDs, same-cycle dynamic/static request acceptance is onehot0,
and response ownership is asserted active and unique across all dynamic/static
matches.

It is still a third evidence model. Reusing `.438` fields would overclaim
multi-active dynamic no-active-same-ID assertions. Reusing `.442` fields would
hide the static-ID exclusion evidence that makes mixed dynamic/static shapes
different from single-active all-dynamic shapes.

## Selected `.445` Boundary

`.445` should select the public report contract before any behavior change.
It should decide:

- exact covered shapes: write `BID`, read single-beat `RID`, and read
  burst-last `RID && RLAST`, with one dynamic transaction plus one, two, or
  three selected pairwise-distinct concrete static transactions;
- whether the first implementation slice should cover all generated
  one-dynamic mixed shapes or a narrower family/cardinality subset;
- exact `implementation_status` and `enforcement` values for a mixed
  static-ID-exclusion generated reject contract;
- whether to add fields for covered static transactions, static ID
  reservations/exclusions, generated request-not-static-ID assertions,
  generated active-not-static-ID assertions, mixed request onehot assertions,
  response active/unique-match assertions, and completion-active assertions;
- whether `request_conflict_policy` remains `no_active_same_id` or receives a
  more precise mixed dynamic/static spelling;
- family-local residue movement for `same_id_ordering` and
  `dynamic_id_same_id_ordering`;
- fail-closed diagnostics for missing mixed evidence; and
- validation gates, rollback, docs, mdBook, and Knowledge Map updates for the
  later behavior owner.

## Deferred Work

The following remain outside `.444` and `.445` unless a later task-tree owner
selects them explicitly:

- implementation of the selected report/acceptance mapping;
- dynamic `issue-order-queue` and dynamic `scoreboard` source policy values;
- accepted dynamic same-ID reuse, dynamic per-ID queues, scoreboards, broader
  request arbitration, overflow handling, or ambiguity tracking;
- direct backend behavior, backend-language variants, VHDL behavior, and new
  generated HDL;
- parser/source syntax changes, PPIF samples, support-accounting entries,
  generated artifacts, and tests in the contract-selection slice unless the
  contract explicitly selects them.

## Validation

Validation for `.444` included:

- guarded compact schedule probes for representative one-dynamic mixed write,
  read single-beat, read burst-last, three-static write, and three-static read
  burst-last response-demux public samples;
- a guarded temporary fail-closed probe for one-dynamic mixed read plus
  `dynamic-id-reuse reject`;
- Knowledge Map generation/check;
- mdBook build;
- docs path audit;
- memory architecture check;
- diff check;
- doctrine gate.

The first guarded schedule extractor attempt used the wrong JSON path and
therefore produced no usable schedule evidence; it was rerun with the correct
top-level `response_demux` path and process-inspection approval for the RAM
guard.

## Rollback

Rollback for `.444` is this docs-only audit commit. Reverting it removes the
`.445` selection, fact card, task-tree advancement, live-doc updates, and
resume pointer update without changing generated behavior.
