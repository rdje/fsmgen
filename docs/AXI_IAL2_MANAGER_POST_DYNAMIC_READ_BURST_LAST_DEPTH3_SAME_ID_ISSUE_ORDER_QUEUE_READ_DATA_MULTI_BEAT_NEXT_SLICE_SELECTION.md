# AXI IAL2 Manager Post Dynamic Read Burst-Last Depth-3 Same-ID Issue-Order Queue Read-Data Multi-Beat Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.501`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.501` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.502`, readiness audit for the first
generated mixed dynamic/static write `BID` same-ID `issue-order-queue`
behavior.

The selected audit is intentionally narrow:

```text
write transactions: w0, w1
w0 transaction ID: dynamic
w1 transaction ID: concrete static
id_families.write width: 4
request ID signal: axi0_awid
response ID signal: axi0_bid
same-id-ordering.write: dynamic-id-reuse issue-order-queue
response-demux.write: generated BID completion
submit policy: try
write max pending: at least 2
```

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, generated artifact, report JSON, test, HDL/runtime behavior, external
converter dependency, arbitrary-cardinality queue behavior, direct backend
behavior, backend-language variant, verification-code output, or VHDL
behavior.

## Why Mixed Queue Readiness Next

`.500` closes the all-dynamic depth-3 dynamic queue/read-data ladder by
shipping multi-beat output banks over generated all-dynamic read burst-last
`RID && RLAST` same-ID `issue-order-queue` depth-3 runtime-validation
read-data.

The smallest remaining protocol-owned queue gap is not an external converter
audit, a scoreboard, arbitrary cardinality, backend-language work, or VHDL.
It is composition of two shipped FSMGen-owned substrates:

- mixed dynamic/static response-demux behavior, already shipped for write
  `BID`, read single-beat `RID`, read burst-last `RID && RLAST`, read-data,
  raw `ARLEN`, runtime validation, multi-beat output banks, and broader
  mixed cardinalities; and
- generated dynamic same-ID `issue-order-queue` behavior, already shipped for
  all-dynamic write `BID`, read single-beat `RID`, read burst-last
  `RID && RLAST`, read-data, raw `ARLEN`, runtime validation, and multi-beat
  output banks through depth 3.

The one-dynamic plus one-concrete-static write `BID` queue is the smallest
honest mixed queue owner. It avoids read-only complications such as `RLAST`,
raw/non-final read beats, read-data banking, `ARLEN`, runtime beat-count
validation, and multi-beat reassembly. It also avoids multi-static,
two-dynamic-plus-static, arbitrary-cardinality, scoreboard, same-cycle, direct
backend, backend-language, and VHDL concerns.

FSMGen-owned generation/lowering remains the default. External converters
such as `sv2v` stay optional future audit candidates only; `.501` does not
select them as dependencies.

## Selected Next Leaf

`.502` should audit whether direct implementation can add exactly one
support-accounted public sample for mixed dynamic/static write `BID`
same-ID `issue-order-queue` behavior, or whether a smaller prerequisite is
needed first.

The candidate source shape is:

```text
(manager-capacity-status axi-manager-capacity-status
  ...
  (id-families
    (write axi0_awid axi0_bid 4))
  (transactions
    (w0 write request axi0_aw_fire complete axi0_b_fire id dynamic)
    (w1 write request axi0_aw_fire complete axi0_b_fire id 4'h3))
  (same-id-ordering
    (write (dynamic-id-reuse issue-order-queue)))
  (response-demux
    (write))
  ...)
```

The exact syntax remains subject to the audit; the audit must not claim a
public sample until it verifies the parser and generator boundary.

## Audit Questions For `.502`

The audit should verify:

- where current code fails closed when mixed dynamic/static `response-demux`
  write behavior is combined with `same-id-ordering.write
  (dynamic-id-reuse issue-order-queue)`;
- whether existing compact runtime-ID queue slots can represent a concrete
  static ID alongside a dynamic captured ID, or whether static entries should
  compare directly against a literal;
- how the queue handles overlap between the dynamic captured write ID and the
  concrete static write ID, including issue-order blocking only when the IDs
  match;
- whether the concrete static ID must remain reserved away from dynamic
  capture, as current mixed response-demux behavior does, or whether an
  issue-order queue needs a different policy;
- how same-cycle selected dequeue plus enqueue should behave for this mixed
  queue shape, and whether that concern must stay deferred;
- which overflow, uniqueness, no-active-same-ID, and ambiguous-match
  assertions are required before any completion can be generated;
- how the report should distinguish all-dynamic queue coverage from mixed
  dynamic/static queue coverage, including `same_id_ordering`,
  `response_demux`, generated queue metadata, residue, and source anchors;
- which support-accounting identity, PPIF sample name, focused parser,
  generator, dynamic-ID, support-catalog, schedule JSON, check JSON, semantic
  JSON, and RAM-guarded validation gates would prove a direct implementation;
  and
- whether direct implementation is safe after the audit, or whether a smaller
  parser/report/static-validation prerequisite must own the next slice first.

## Deferred Alternatives

`.501` explicitly defers:

- implementation of mixed dynamic/static issue-order queue behavior until the
  `.502` readiness audit closes;
- mixed read `RID` or `RID && RLAST` issue-order queues;
- multi-static or two-dynamic-plus-static mixed issue-order queues;
- scoreboards;
- same-cycle queue widening beyond existing recapture owners;
- arbitrary queue cardinality;
- verification-code generation;
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
semantic JSON, HDL, or runtime behavior validation is claimed for `.501`
because it changes no behavior.

## Rollback

Rollback is documentation-only: revert this selector doc, the matching
Knowledge Map card/map entry, task-tree advancement, README/ROADMAP/mdBook
sync, and Memory pointer. No generated HDL or runtime artifact rollback is
required.
