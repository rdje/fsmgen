# AXI IAL2 Manager Post Mixed Dynamic/Static Issue-Order Queue Read-Data Multi-Beat Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.522`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.522` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.523`, readiness audit for broader mixed
dynamic/static write `BID` same-ID `issue-order-queue` cardinality.

The selected audit is intentionally narrow:

```text
write transactions: w0, w1, w2
w0 transaction ID: dynamic
w1 transaction ID: concrete static
w2 transaction ID: concrete static
id_families.write width: 4
request ID signal: axi0_awid
response ID signal: axi0_bid
same-id-ordering.write: dynamic-id-reuse issue-order-queue
response-demux.write: generated BID completion
candidate queue depth: 3 selected transactions
```

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, generated artifact, schedule/check/semantic JSON, test, HDL/runtime
behavior, backend behavior, verification-output generation, backend-language
variant, external converter dependency, or VHDL behavior.

## Why Broader Mixed Queue Cardinality Next

`.520` completed the bounded one-dynamic plus one-concrete-static mixed
dynamic/static queue read-data ladder by shipping runtime-validation
multi-beat output banks over the generated mixed read burst-last queue
completion. `.521` then synchronized public contract summaries so that shipped
surface is visible to downstream consumers.

The remaining deferred IAL2 queue surface closest to the shipped code is
broader mixed issue-order queue cardinality. The first step should not be a
scoreboard, direct backend lowering, verification-output generation,
backend-language work, external converter audit, or VHDL. It should audit the
smallest wider mixed queue shape:

- write `BID`, not read `RID` or `RID && RLAST`;
- one dynamic transaction plus two concrete static transactions, not arbitrary
  cardinality;
- same existing `dynamic-id-reuse issue-order-queue` policy;
- generated queue behavior only after readiness is proven; and
- no read-data, raw-`ARLEN`, runtime-validation, multi-beat, packed-vector, or
  alternate full-burst payload behavior in the audit.

Write `BID` is the smallest owner because it widens static siblings without
adding read final-beat preservation, raw non-final `RID`, read-data banking,
burst-length validation, or multi-beat reassembly.

## Selected Next Leaf

`.523` should audit whether direct implementation can add exactly one bounded
public mixed write queue sample with one dynamic write transaction and two
concrete static write transactions, or whether a smaller parser/report/static
validation prerequisite is required first.

The candidate source shape is:

```text
(manager-capacity-status axi-manager-capacity-status
  ...
  (id-families
    (write axi0_awid axi0_bid 4))
  (transactions
    (w0 write request axi0_aw_fire complete axi0_b_fire id dynamic)
    (w1 write request axi0_aw_fire complete axi0_b_fire id 4'h3)
    (w2 write request axi0_aw_fire complete axi0_b_fire id 4'h5))
  (same-id-ordering
    (write (dynamic-id-reuse issue-order-queue)))
  (response-demux
    (write))
  ...)
```

The exact public sample name and report vocabulary remain subject to the
audit. A plausible stem is
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_multi_static.ppif`,
but `.523` must confirm the final source/report/support-accounting identity
before implementation.

## Audit Questions For `.523`

The audit should verify:

- where current code fails closed when one dynamic plus two concrete static
  write transactions combine generated mixed write `BID` response-demux with
  same-ID issue-order queue behavior;
- whether the existing mixed queue planner can reuse the one-dynamic plus
  one-static path with list-shaped static entries, or needs a narrower report
  prerequisite first;
- how the queue distinguishes dynamic captured-ID matches from the two
  concrete static IDs;
- how static concrete-ID reservation and dynamic request/static-active
  exclusion should extend from one static sibling to two;
- whether queue depth should be derived from the selected transaction count,
  the family max-pending value, or a smaller local bound;
- which no-active-same-ID, active dynamic-ID uniqueness, static exclusion,
  overflow, active-match, unique-match, and completion-active assertions must
  be present before generated completion behavior is claimed;
- how reports should distinguish one-static mixed queue behavior from the new
  multi-static mixed queue boundary; and
- which focused parser, generator, support-accounting, schedule/check/semantic
  JSON, and RAM-guarded probes are sufficient for a direct implementation
  slice.

## Deferred Alternatives

`.522` explicitly defers:

- implementation of broader mixed queue cardinality until `.523` completes;
- read single-beat or read burst-last mixed queue cardinality widening;
- read-data, raw-`ARLEN`, runtime-validation, or multi-beat behavior over
  broader mixed queue cardinalities;
- scoreboards;
- group-local simultaneous enqueue widening;
- packed burst-vector outputs and alternate full burst payload assembly;
- arbitrary queue cardinality;
- verification-output generation;
- direct backend behavior;
- backend-language variants;
- external converter dependency selection, including `sv2v`; and
- VHDL.

## Validation

This selector closes with documentation and continuity gates only:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No syntax, parser, generator, PPIF, support-accounting, schedule/check/
semantic JSON, HDL, or runtime behavior validation is claimed for `.522`
because it changes no behavior.

## Rollback

Rollback is documentation-only: revert this selector doc, the matching
Knowledge Map card/map entry, task-tree advancement, README/ROADMAP/mdBook
sync, and Memory pointer. No generated HDL or runtime artifact rollback is
required.
